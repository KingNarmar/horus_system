-- H.O.R.U.S System — Issue #196 finalizer observability
-- Retain non-sensitive retry diagnostics instead of silently swallowing a
-- failed scheduled finalization attempt.

BEGIN;

ALTER TABLE public.account_deletion_requests
  ADD COLUMN finalization_attempt_count integer NOT NULL DEFAULT 0,
  ADD COLUMN last_finalization_attempt_at timestamptz,
  ADD COLUMN last_finalization_failure_code text;

CREATE OR REPLACE FUNCTION private.finalize_due_account_deletions()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_request record;
  v_profile_name text;
  v_failure_code text;
  v_finalized_count integer := 0;
BEGIN
  FOR v_request IN
    SELECT request.id, request.user_id, request.subject_user_id
    FROM public.account_deletion_requests request
    WHERE request.status = 'pending'
      AND request.user_id IS NOT NULL
      AND request.scheduled_for <= pg_catalog.now()
    ORDER BY request.scheduled_for, request.id
    FOR UPDATE SKIP LOCKED
  LOOP
    BEGIN
      UPDATE public.account_deletion_requests request
      SET
        finalization_attempt_count = request.finalization_attempt_count + 1,
        last_finalization_attempt_at = pg_catalog.now(),
        last_finalization_failure_code = NULL
      WHERE request.id = v_request.id;

      PERFORM private.account_deletion_assert_eligible(v_request.user_id);

      SELECT NULLIF(pg_catalog.btrim(profile.full_name), '')
      INTO v_profile_name
      FROM public.user_profiles profile
      WHERE profile.id = v_request.user_id;

      UPDATE public.audit_logs log
      SET
        actor_display_name = COALESCE(
          NULLIF(pg_catalog.btrim(log.actor_display_name), ''),
          v_profile_name,
          NULLIF(pg_catalog.btrim(log.actor_role), '')
        ),
        actor_email = NULL
      WHERE log.actor_user_id = v_request.user_id;

      UPDATE public.company_invitations invitation
      SET invited_by_display_name = COALESCE(
        NULLIF(pg_catalog.btrim(invitation.invited_by_display_name), ''),
        v_profile_name
      )
      WHERE invitation.invited_by_user_id = v_request.user_id;

      UPDATE storage.objects object_row
      SET owner = NULL,
          owner_id = NULL
      WHERE object_row.owner = v_request.user_id
         OR object_row.owner_id = v_request.user_id::text;

      PERFORM private.audit_account_deletion_lifecycle(
        v_request.user_id,
        'account_deletion_finalized'
      );

      DELETE FROM auth.users auth_user
      WHERE auth_user.id = v_request.user_id;

      IF NOT FOUND THEN
        RAISE EXCEPTION USING
          ERRCODE = 'P1964',
          MESSAGE = 'account_deletion_user_missing';
      END IF;

      UPDATE public.account_deletion_requests request
      SET
        status = 'finalized',
        finalized_at = pg_catalog.now(),
        last_finalization_failure_code = NULL
      WHERE request.id = v_request.id
        AND request.subject_user_id = v_request.subject_user_id
        AND request.status = 'pending';

      v_finalized_count := v_finalized_count + 1;
    EXCEPTION
      WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_failure_code = RETURNED_SQLSTATE;

        UPDATE public.account_deletion_requests request
        SET
          finalization_attempt_count = request.finalization_attempt_count + 1,
          last_finalization_attempt_at = pg_catalog.now(),
          last_finalization_failure_code = v_failure_code
        WHERE request.id = v_request.id
          AND request.status = 'pending';
    END;
  END LOOP;

  RETURN v_finalized_count;
END;
$function$;

REVOKE ALL ON FUNCTION private.finalize_due_account_deletions()
  FROM PUBLIC, anon, authenticated;

COMMIT;
