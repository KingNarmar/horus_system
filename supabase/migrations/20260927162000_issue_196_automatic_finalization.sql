-- H.O.R.U.S System — Issue #196 automatic account deletion finalization
-- Finalization stays entirely server-side. No service-role secret is shipped to
-- Flutter or stored in application code. A Postgres cron job retries due
-- requests hourly; a failed subject remains pending for a later retry.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;

CREATE OR REPLACE FUNCTION private.audit_account_deletion_lifecycle(
  p_user_id uuid,
  p_event text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_membership record;
BEGIN
  FOR v_membership IN
    SELECT membership.company_id
    FROM public.company_users membership
    WHERE membership.user_id = p_user_id
  LOOP
    PERFORM private.write_audit_event(
      v_membership.company_id,
      'company_users',
      'company_user',
      p_user_id::text,
      NULL,
      'status_changed',
      p_event,
      NULL,
      NULL,
      pg_catalog.jsonb_build_object('account_user_id', p_user_id)
    );
  END LOOP;
END;
$function$;

REVOKE ALL ON FUNCTION private.audit_account_deletion_lifecycle(uuid, text)
  FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.request_my_account_deletion()
RETURNS TABLE(status text, requested_at timestamptz, scheduled_for timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_request public.account_deletion_requests%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P1960', MESSAGE = 'account_deletion_auth_required';
  END IF;

  PERFORM private.account_deletion_assert_eligible(v_user_id);

  SELECT request.*
  INTO v_request
  FROM public.account_deletion_requests request
  WHERE request.user_id = v_user_id
    AND request.status = 'pending'
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.account_deletion_requests(
      user_id,
      subject_user_id,
      scheduled_for
    )
    VALUES (
      v_user_id,
      v_user_id,
      pg_catalog.now() + interval '7 days'
    )
    RETURNING * INTO v_request;

    PERFORM private.audit_account_deletion_lifecycle(
      v_user_id,
      'account_deletion_requested'
    );
  END IF;

  RETURN QUERY
  SELECT
    v_request.status::text,
    v_request.requested_at,
    v_request.scheduled_for;
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_my_account_deletion()
RETURNS TABLE(status text, requested_at timestamptz, scheduled_for timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_request public.account_deletion_requests%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P1960', MESSAGE = 'account_deletion_auth_required';
  END IF;

  SELECT request.*
  INTO v_request
  FROM public.account_deletion_requests request
  WHERE request.user_id = v_user_id
    AND request.status = 'pending'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  UPDATE public.account_deletion_requests request
  SET
    status = 'cancelled',
    cancelled_at = pg_catalog.now()
  WHERE request.id = v_request.id
  RETURNING * INTO v_request;

  PERFORM private.audit_account_deletion_lifecycle(
    v_user_id,
    'account_deletion_cancelled'
  );

  RETURN QUERY
  SELECT
    v_request.status::text,
    v_request.requested_at,
    v_request.scheduled_for;
END;
$function$;

CREATE OR REPLACE FUNCTION private.finalize_due_account_deletions()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_request record;
  v_profile_name text;
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
        finalized_at = pg_catalog.now()
      WHERE request.id = v_request.id
        AND request.subject_user_id = v_request.subject_user_id
        AND request.status = 'pending';

      v_finalized_count := v_finalized_count + 1;
    EXCEPTION
      WHEN OTHERS THEN
        -- Keep this subject pending so the next scheduled run can retry.
        NULL;
    END;
  END LOOP;

  RETURN v_finalized_count;
END;
$function$;

REVOKE ALL ON FUNCTION private.finalize_due_account_deletions()
  FROM PUBLIC, anon, authenticated;

DO $block$
DECLARE
  v_job_id bigint;
BEGIN
  SELECT jobid
  INTO v_job_id
  FROM cron.job
  WHERE jobname = 'horus-account-deletion-finalizer';

  IF v_job_id IS NOT NULL THEN
    PERFORM cron.unschedule(v_job_id);
  END IF;

  PERFORM cron.schedule(
    'horus-account-deletion-finalizer',
    '17 * * * *',
    'SELECT private.finalize_due_account_deletions();'
  );
END;
$block$;

COMMIT;
