-- H.O.R.U.S System — Issue #196 storage ownership finalization hardening
-- Company-owned documents survive individual account deletion. Storage access is
-- company/role scoped, not owner scoped, so remove Auth ownership metadata before
-- deleting the Auth identity without deleting or moving the business object.

BEGIN;

CREATE OR REPLACE FUNCTION public.prepare_account_deletion_finalization(
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF current_user NOT IN ('postgres', 'service_role', 'supabase_admin') THEN
    RAISE EXCEPTION USING ERRCODE = 'P1962', MESSAGE = 'account_deletion_finalizer_forbidden';
  END IF;

  PERFORM private.account_deletion_assert_eligible(p_user_id);

  IF NOT EXISTS (
    SELECT 1
    FROM public.account_deletion_requests request
    WHERE request.user_id = p_user_id
      AND request.subject_user_id = p_user_id
      AND request.status = 'pending'
      AND request.scheduled_for <= pg_catalog.now()
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P1963', MESSAGE = 'account_deletion_not_due';
  END IF;

  UPDATE public.audit_logs
  SET actor_email = NULL
  WHERE actor_user_id = p_user_id;

  UPDATE public.company_invitations invitation
  SET invited_by_display_name = COALESCE(
    invitation.invited_by_display_name,
    (
      SELECT NULLIF(pg_catalog.btrim(profile.full_name), '')
      FROM public.user_profiles profile
      WHERE profile.id = p_user_id
    )
  )
  WHERE invitation.invited_by_user_id = p_user_id;

  UPDATE storage.objects object_row
  SET owner = NULL,
      owner_id = NULL
  WHERE object_row.owner = p_user_id
     OR object_row.owner_id = p_user_id::text;
END;
$function$;

REVOKE ALL ON FUNCTION public.prepare_account_deletion_finalization(uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.prepare_account_deletion_finalization(uuid)
  TO service_role;

COMMIT;
