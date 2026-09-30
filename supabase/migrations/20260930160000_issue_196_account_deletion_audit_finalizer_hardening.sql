-- H.O.R.U.S System — Issue #196 account-deletion audit finalizer hardening
-- Lifecycle audit must work both from authenticated self-service RPCs and from
-- the trusted pg_cron finalizer, where auth.uid() is intentionally unavailable.
-- Keep the historical actor display snapshot while avoiding contact PII.

BEGIN;

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
  v_actor_display_name text;
BEGIN
  SELECT NULLIF(pg_catalog.btrim(profile.full_name), '')
  INTO v_actor_display_name
  FROM public.user_profiles profile
  WHERE profile.id = p_user_id;

  FOR v_membership IN
    SELECT membership.company_id, membership.role::text AS actor_role
    FROM public.company_users membership
    WHERE membership.user_id = p_user_id
  LOOP
    INSERT INTO public.audit_logs (
      company_id,
      actor_user_id,
      actor_role,
      actor_display_name,
      actor_email,
      module,
      entity_type,
      entity_id,
      entity_display_name,
      action,
      description,
      old_values,
      new_values,
      metadata
    )
    VALUES (
      v_membership.company_id,
      p_user_id,
      v_membership.actor_role,
      COALESCE(v_actor_display_name, v_membership.actor_role),
      NULL,
      'company_users',
      'company_user',
      p_user_id::text,
      NULL,
      'status_changed',
      p_event,
      NULL,
      NULL,
      pg_catalog.jsonb_build_object('audit_event', p_event)
    );
  END LOOP;
END;
$function$;

REVOKE ALL ON FUNCTION private.audit_account_deletion_lifecycle(uuid, text)
  FROM PUBLIC, anon, authenticated, service_role;

COMMIT;
