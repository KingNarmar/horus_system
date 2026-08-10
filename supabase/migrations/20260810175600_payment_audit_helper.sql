-- H.O.R.U.S System — Issue #27 Payments module
-- Shared structured audit helper used by company-scoped financial RPCs.

BEGIN;

CREATE OR REPLACE FUNCTION private.write_audit_event(
  p_company_id uuid,
  p_module text,
  p_entity_type text,
  p_entity_id text,
  p_entity_display_name text,
  p_action text,
  p_audit_event text,
  p_old_values jsonb,
  p_new_values jsonb,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role text;
  v_actor_display_name text;
  v_actor_email text;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2790',
      MESSAGE = 'audit_actor_not_found';
  END IF;

  SELECT
    company_user.role::text,
    COALESCE(
      NULLIF(pg_catalog.btrim(user_profile.full_name), ''),
      auth_user.email,
      v_actor_user_id::text
    ),
    auth_user.email
  INTO
    v_actor_role,
    v_actor_display_name,
    v_actor_email
  FROM public.company_users company_user
  LEFT JOIN public.user_profiles user_profile
    ON user_profile.id = company_user.user_id
  LEFT JOIN auth.users auth_user
    ON auth_user.id = company_user.user_id
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2790',
      MESSAGE = 'audit_actor_not_found';
  END IF;

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
    p_company_id,
    v_actor_user_id,
    v_actor_role,
    v_actor_display_name,
    v_actor_email,
    p_module,
    p_entity_type,
    p_entity_id,
    p_entity_display_name,
    p_action,
    p_audit_event,
    p_old_values,
    p_new_values,
    COALESCE(p_metadata, '{}'::jsonb)
      || pg_catalog.jsonb_build_object('audit_event', p_audit_event)
  );
END;
$$;

REVOKE ALL ON FUNCTION private.write_audit_event(
  uuid, text, text, text, text, text, text, jsonb, jsonb, jsonb
) FROM PUBLIC;

COMMIT;
