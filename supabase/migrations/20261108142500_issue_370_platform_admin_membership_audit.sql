-- Issue #370: eliminate unaudited Platform Admin membership UPDATEs.
-- Recovery remains available through a narrow, server-authorized, audited RPC.
-- No modification to ordinary company membership RPCs or historic audit rows.
BEGIN;

-- The existing policy permits a Platform Admin to PATCH every membership column
-- directly. Restrict the grant; SECURITY DEFINER membership RPCs remain usable.
REVOKE UPDATE ON TABLE public.company_users FROM authenticated;

DROP POLICY IF EXISTS company_users_update_platform_admin_only
  ON public.company_users;

-- Ordinary private.write_audit_event requires the actor to be an active member
-- of the target company. A platform operator may be outside that tenant.
CREATE OR REPLACE FUNCTION private.write_platform_membership_recovery_audit(
  p_company_id uuid,
  p_membership_id uuid,
  p_target_user_id uuid,
  p_old_role public.company_role,
  p_new_role public.company_role,
  p_old_active boolean,
  p_new_active boolean,
  p_reason_code text,
  p_case_reference text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_actor_id uuid := auth.uid();
  v_actor_name text;
  v_action text;
BEGIN
  IF v_actor_id IS NULL OR private.is_platform_admin() IS NOT TRUE THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3701',
      MESSAGE = 'platform_recovery_forbidden';
  END IF;

  SELECT COALESCE(
    NULLIF(pg_catalog.btrim(profile.full_name), ''),
    v_actor_id::text
  )
  INTO v_actor_name
  FROM public.user_profiles profile
  WHERE profile.id = v_actor_id
    AND profile.is_platform_admin IS TRUE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3701',
      MESSAGE = 'platform_recovery_forbidden';
  END IF;

  v_action := CASE
    WHEN p_old_role IS DISTINCT FROM p_new_role THEN 'updated'
    WHEN p_new_active THEN 'reactivated'
    ELSE 'deactivated'
  END;

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
    v_actor_id,
    'platform_admin',
    v_actor_name,
    NULL,
    'company_users',
    'company_user',
    p_membership_id::text,
    p_target_user_id::text,
    v_action,
    'platform_membership_recovered',
    pg_catalog.jsonb_build_object(
      'role', p_old_role::text,
      'is_active', p_old_active
    ),
    pg_catalog.jsonb_build_object(
      'role', p_new_role::text,
      'is_active', p_new_active
    ),
    pg_catalog.jsonb_strip_nulls(
      pg_catalog.jsonb_build_object(
        'audit_event', 'platform_membership_recovered',
        'source', 'platform_admin_recovery',
        'reason_code', p_reason_code,
        'case_reference', p_case_reference,
        'user_id', p_target_user_id
      )
    )
  );
END;
$function$;

REVOKE ALL ON FUNCTION private.write_platform_membership_recovery_audit(
  uuid, uuid, uuid, public.company_role, public.company_role,
  boolean, boolean, text, text
) FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.recover_company_membership_as_platform_admin(
  p_company_id uuid,
  p_membership_id uuid,
  p_new_role public.company_role,
  p_is_active boolean,
  p_expected_updated_at timestamp with time zone,
  p_reason_code text,
  p_case_reference text DEFAULT NULL
)
RETURNS TABLE (
  membership_id uuid,
  membership_role public.company_role,
  membership_active boolean,
  membership_updated_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_actor_id uuid := auth.uid();
  v_before public.company_users%ROWTYPE;
  v_after public.company_users%ROWTYPE;
  v_new_role public.company_role;
  v_new_active boolean;
  v_reason_code text := NULLIF(pg_catalog.btrim(p_reason_code), '');
  v_case_reference text := NULLIF(pg_catalog.btrim(p_case_reference), '');
BEGIN
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3700',
      MESSAGE = 'platform_recovery_auth_required';
  END IF;

  IF private.is_platform_admin() IS NOT TRUE THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3701',
      MESSAGE = 'platform_recovery_forbidden';
  END IF;

  IF v_reason_code IS NULL OR v_reason_code NOT IN (
    'owner_access_recovery',
    'membership_access_recovery',
    'security_remediation'
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3706',
      MESSAGE = 'platform_recovery_reason_invalid';
  END IF;

  IF v_case_reference IS NOT NULL AND (
    pg_catalog.length(v_case_reference) > 80
    OR v_case_reference !~ '^[A-Za-z0-9][A-Za-z0-9._:-]*$'
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3707',
      MESSAGE = 'platform_recovery_case_reference_invalid';
  END IF;

  IF p_new_role IS NULL AND p_is_active IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3705',
      MESSAGE = 'platform_recovery_change_required';
  END IF;

  IF p_expected_updated_at IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3704',
      MESSAGE = 'platform_recovery_stale_membership';
  END IF;

  -- Lock in the same order as ordinary membership RPCs.
  PERFORM 1
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3702',
      MESSAGE = 'platform_recovery_target_not_found';
  END IF;

  SELECT membership.*
  INTO v_before
  FROM public.company_users membership
  WHERE membership.company_id = p_company_id
    AND membership.id = p_membership_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3702',
      MESSAGE = 'platform_recovery_target_not_found';
  END IF;

  IF v_before.updated_at IS DISTINCT FROM p_expected_updated_at THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3704',
      MESSAGE = 'platform_recovery_stale_membership';
  END IF;

  v_new_role := COALESCE(p_new_role, v_before.role);
  v_new_active := COALESCE(p_is_active, v_before.is_active);

  -- An inactive Owner is not a valid recovery outcome.
  IF v_new_role = 'owner'::public.company_role AND v_new_active IS NOT TRUE THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3703',
      MESSAGE = 'platform_recovery_owner_must_be_active';
  END IF;

  -- Never remove the last active Owner, including through an operator command.
  IF v_before.role = 'owner'::public.company_role
     AND v_before.is_active IS TRUE
     AND (v_new_role <> 'owner'::public.company_role OR v_new_active IS NOT TRUE)
     AND NOT EXISTS (
       SELECT 1
       FROM public.company_users other_owner
       WHERE other_owner.company_id = p_company_id
         AND other_owner.id <> v_before.id
         AND other_owner.role = 'owner'::public.company_role
         AND other_owner.is_active IS TRUE
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3703',
      MESSAGE = 'platform_recovery_last_owner_required';
  END IF;

  -- A genuine no-op creates neither audit history nor a Realtime event.
  IF v_before.role IS NOT DISTINCT FROM v_new_role
     AND v_before.is_active IS NOT DISTINCT FROM v_new_active THEN
    RETURN QUERY
    SELECT v_before.id, v_before.role, v_before.is_active, v_before.updated_at;
    RETURN;
  END IF;

  UPDATE public.company_users membership
  SET role = v_new_role,
      is_active = v_new_active,
      updated_by = v_actor_id,
      updated_at = pg_catalog.now()
  WHERE membership.id = v_before.id
    AND membership.company_id = p_company_id
  RETURNING * INTO v_after;

  -- Same transaction as the membership update. Failure rolls both back.
  PERFORM private.write_platform_membership_recovery_audit(
    p_company_id,
    v_after.id,
    v_after.user_id,
    v_before.role,
    v_after.role,
    v_before.is_active,
    v_after.is_active,
    v_reason_code,
    v_case_reference
  );

  RETURN QUERY
  SELECT v_after.id, v_after.role, v_after.is_active, v_after.updated_at;
END;
$function$;

REVOKE ALL ON FUNCTION public.recover_company_membership_as_platform_admin(
  uuid, uuid, public.company_role, boolean, timestamp with time zone, text, text
) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.recover_company_membership_as_platform_admin(
  uuid, uuid, public.company_role, boolean, timestamp with time zone, text, text
) TO authenticated;

-- Fail-closed if another grant still exposes direct authenticated UPDATE.
DO $contract$
BEGIN
  IF pg_catalog.has_table_privilege(
    'authenticated', 'public.company_users', 'UPDATE'
  ) THEN
    RAISE EXCEPTION 'issue_370_unaudited_membership_update_still_granted';
  END IF;
END;
$contract$;

COMMIT;
