-- H.O.R.U.S System — Issue #203 Company invitations and membership lifecycle
-- Secure, audited membership and ownership commands.

BEGIN;

CREATE OR REPLACE FUNCTION public.change_company_member_role(
  p_company_id uuid,
  p_membership_id uuid,
  p_new_role public.company_role
)
RETURNS TABLE (
  membership_id uuid,
  membership_role public.company_role,
  is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role public.company_role;
  v_target public.company_users%ROWTYPE;
  v_old_role public.company_role;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2820', MESSAGE = 'company_membership_auth_required';
  END IF;

  IF p_new_role IS NULL OR p_new_role = 'owner'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2821', MESSAGE = 'company_member_role_change_not_allowed';
  END IF;

  PERFORM 1
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2822', MESSAGE = 'company_not_found';
  END IF;

  SELECT company_user.role
  INTO v_actor_role
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true
  FOR UPDATE;

  IF NOT FOUND OR v_actor_role <> 'owner'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2823', MESSAGE = 'company_member_role_change_not_allowed';
  END IF;

  SELECT company_user.*
  INTO v_target
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.id = p_membership_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2824', MESSAGE = 'company_member_not_found';
  END IF;

  IF NOT v_target.is_active THEN
    RAISE EXCEPTION USING ERRCODE = 'P2825', MESSAGE = 'company_member_inactive';
  END IF;

  IF v_target.role = 'owner'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2821', MESSAGE = 'company_member_role_change_not_allowed';
  END IF;

  IF v_target.role = p_new_role THEN
    RETURN QUERY SELECT v_target.id, v_target.role, v_target.is_active;
    RETURN;
  END IF;

  v_old_role := v_target.role;

  UPDATE public.company_users company_user
  SET role = p_new_role,
      updated_by = v_actor_user_id,
      updated_at = pg_catalog.now()
  WHERE company_user.id = v_target.id
  RETURNING * INTO v_target;

  PERFORM private.write_audit_event(
    p_company_id,
    'company_users',
    'company_user',
    v_target.id::text,
    v_target.user_id::text,
    'updated',
    'company_member_role_changed',
    pg_catalog.jsonb_build_object('role', v_old_role::text),
    pg_catalog.jsonb_build_object('role', v_target.role::text),
    pg_catalog.jsonb_build_object('user_id', v_target.user_id)
  );

  RETURN QUERY SELECT v_target.id, v_target.role, v_target.is_active;
END;
$$;

REVOKE ALL ON FUNCTION public.change_company_member_role(uuid, uuid, public.company_role) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.change_company_member_role(uuid, uuid, public.company_role) FROM anon;
GRANT EXECUTE ON FUNCTION public.change_company_member_role(uuid, uuid, public.company_role) TO authenticated;

CREATE OR REPLACE FUNCTION public.deactivate_company_member(
  p_company_id uuid,
  p_membership_id uuid
)
RETURNS TABLE (
  membership_id uuid,
  membership_role public.company_role,
  is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role public.company_role;
  v_target public.company_users%ROWTYPE;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2820', MESSAGE = 'company_membership_auth_required';
  END IF;

  PERFORM 1
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2822', MESSAGE = 'company_not_found';
  END IF;

  SELECT company_user.role
  INTO v_actor_role
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true
  FOR UPDATE;

  IF NOT FOUND OR v_actor_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING ERRCODE = 'P2826', MESSAGE = 'company_member_status_change_not_allowed';
  END IF;

  SELECT company_user.*
  INTO v_target
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.id = p_membership_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2824', MESSAGE = 'company_member_not_found';
  END IF;

  IF NOT v_target.is_active THEN
    RETURN QUERY SELECT v_target.id, v_target.role, v_target.is_active;
    RETURN;
  END IF;

  IF v_target.role = 'owner'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2827', MESSAGE = 'company_ownership_command_required';
  END IF;

  IF v_actor_role = 'admin'::public.company_role
     AND v_target.role = 'admin'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2826', MESSAGE = 'company_member_status_change_not_allowed';
  END IF;

  UPDATE public.company_users company_user
  SET is_active = false,
      updated_by = v_actor_user_id,
      updated_at = pg_catalog.now()
  WHERE company_user.id = v_target.id
  RETURNING * INTO v_target;

  PERFORM private.write_audit_event(
    p_company_id,
    'company_users',
    'company_user',
    v_target.id::text,
    v_target.user_id::text,
    'deactivated',
    'company_membership_deactivated',
    pg_catalog.jsonb_build_object('is_active', true, 'role', v_target.role::text),
    pg_catalog.jsonb_build_object('is_active', false, 'role', v_target.role::text),
    pg_catalog.jsonb_build_object('user_id', v_target.user_id)
  );

  RETURN QUERY SELECT v_target.id, v_target.role, v_target.is_active;
END;
$$;

REVOKE ALL ON FUNCTION public.deactivate_company_member(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.deactivate_company_member(uuid, uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.deactivate_company_member(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.reactivate_company_member(
  p_company_id uuid,
  p_membership_id uuid
)
RETURNS TABLE (
  membership_id uuid,
  membership_role public.company_role,
  is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role public.company_role;
  v_target public.company_users%ROWTYPE;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2820', MESSAGE = 'company_membership_auth_required';
  END IF;

  PERFORM 1
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2822', MESSAGE = 'company_not_found';
  END IF;

  SELECT company_user.role
  INTO v_actor_role
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true
  FOR UPDATE;

  IF NOT FOUND OR v_actor_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING ERRCODE = 'P2826', MESSAGE = 'company_member_status_change_not_allowed';
  END IF;

  SELECT company_user.*
  INTO v_target
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.id = p_membership_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2824', MESSAGE = 'company_member_not_found';
  END IF;

  IF v_target.is_active THEN
    RETURN QUERY SELECT v_target.id, v_target.role, v_target.is_active;
    RETURN;
  END IF;

  IF v_target.role = 'owner'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2827', MESSAGE = 'company_ownership_command_required';
  END IF;

  IF v_actor_role = 'admin'::public.company_role
     AND v_target.role = 'admin'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2826', MESSAGE = 'company_member_status_change_not_allowed';
  END IF;

  UPDATE public.company_users company_user
  SET is_active = true,
      updated_by = v_actor_user_id,
      updated_at = pg_catalog.now()
  WHERE company_user.id = v_target.id
  RETURNING * INTO v_target;

  PERFORM private.write_audit_event(
    p_company_id,
    'company_users',
    'company_user',
    v_target.id::text,
    v_target.user_id::text,
    'reactivated',
    'company_membership_reactivated',
    pg_catalog.jsonb_build_object('is_active', false, 'role', v_target.role::text),
    pg_catalog.jsonb_build_object('is_active', true, 'role', v_target.role::text),
    pg_catalog.jsonb_build_object('user_id', v_target.user_id)
  );

  RETURN QUERY SELECT v_target.id, v_target.role, v_target.is_active;
END;
$$;

REVOKE ALL ON FUNCTION public.reactivate_company_member(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reactivate_company_member(uuid, uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.reactivate_company_member(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.grant_company_ownership(
  p_company_id uuid,
  p_membership_id uuid
)
RETURNS TABLE (
  membership_id uuid,
  membership_role public.company_role,
  is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_membership public.company_users%ROWTYPE;
  v_target public.company_users%ROWTYPE;
  v_old_role public.company_role;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2820', MESSAGE = 'company_membership_auth_required';
  END IF;

  PERFORM 1
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2822', MESSAGE = 'company_not_found';
  END IF;

  SELECT company_user.*
  INTO v_actor_membership
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true
  FOR UPDATE;

  IF NOT FOUND OR v_actor_membership.role <> 'owner'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2828', MESSAGE = 'company_ownership_transfer_not_allowed';
  END IF;

  SELECT company_user.*
  INTO v_target
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.id = p_membership_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2824', MESSAGE = 'company_member_not_found';
  END IF;

  IF NOT v_target.is_active THEN
    RAISE EXCEPTION USING ERRCODE = 'P2825', MESSAGE = 'company_member_inactive';
  END IF;

  IF v_target.role = 'owner'::public.company_role THEN
    RETURN QUERY SELECT v_target.id, v_target.role, v_target.is_active;
    RETURN;
  END IF;

  v_old_role := v_target.role;

  UPDATE public.company_users company_user
  SET role = 'owner'::public.company_role,
      updated_by = v_actor_user_id,
      updated_at = pg_catalog.now()
  WHERE company_user.id = v_target.id
  RETURNING * INTO v_target;

  PERFORM private.write_audit_event(
    p_company_id,
    'company_users',
    'company_user',
    v_target.id::text,
    v_target.user_id::text,
    'updated',
    'company_ownership_granted',
    pg_catalog.jsonb_build_object('role', v_old_role::text),
    pg_catalog.jsonb_build_object('role', 'owner'),
    pg_catalog.jsonb_build_object(
      'user_id', v_target.user_id,
      'granted_by_membership_id', v_actor_membership.id
    )
  );

  RETURN QUERY SELECT v_target.id, v_target.role, v_target.is_active;
END;
$$;

REVOKE ALL ON FUNCTION public.grant_company_ownership(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.grant_company_ownership(uuid, uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.grant_company_ownership(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.transfer_company_ownership(
  p_company_id uuid,
  p_target_membership_id uuid,
  p_source_new_role public.company_role DEFAULT 'admin'::public.company_role
)
RETURNS TABLE (
  source_membership_id uuid,
  source_role public.company_role,
  target_membership_id uuid,
  target_role public.company_role
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_source public.company_users%ROWTYPE;
  v_target public.company_users%ROWTYPE;
  v_target_old_role public.company_role;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2820', MESSAGE = 'company_membership_auth_required';
  END IF;

  IF p_source_new_role IS NULL OR p_source_new_role = 'owner'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2828', MESSAGE = 'company_ownership_transfer_not_allowed';
  END IF;

  PERFORM 1
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2822', MESSAGE = 'company_not_found';
  END IF;

  SELECT company_user.*
  INTO v_source
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true
  FOR UPDATE;

  IF NOT FOUND OR v_source.role <> 'owner'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2828', MESSAGE = 'company_ownership_transfer_not_allowed';
  END IF;

  SELECT company_user.*
  INTO v_target
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.id = p_target_membership_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2824', MESSAGE = 'company_member_not_found';
  END IF;

  IF NOT v_target.is_active OR v_target.id = v_source.id THEN
    RAISE EXCEPTION USING ERRCODE = 'P2828', MESSAGE = 'company_ownership_transfer_not_allowed';
  END IF;

  v_target_old_role := v_target.role;

  IF v_target.role <> 'owner'::public.company_role THEN
    UPDATE public.company_users company_user
    SET role = 'owner'::public.company_role,
        updated_by = v_actor_user_id,
        updated_at = pg_catalog.now()
    WHERE company_user.id = v_target.id
    RETURNING * INTO v_target;
  END IF;

  -- Write the ownership audit while the actor is still an Owner. The whole
  -- function is transactional, so a later failure rolls this event back.
  PERFORM private.write_audit_event(
    p_company_id,
    'company_users',
    'company_user',
    v_target.id::text,
    v_target.user_id::text,
    'updated',
    'company_ownership_transferred',
    pg_catalog.jsonb_build_object(
      'source_membership_id', v_source.id,
      'source_role', 'owner',
      'target_membership_id', v_target.id,
      'target_role', v_target_old_role::text
    ),
    pg_catalog.jsonb_build_object(
      'source_membership_id', v_source.id,
      'source_role', p_source_new_role::text,
      'target_membership_id', v_target.id,
      'target_role', 'owner'
    ),
    pg_catalog.jsonb_build_object(
      'source_user_id', v_source.user_id,
      'target_user_id', v_target.user_id
    )
  );

  UPDATE public.company_users company_user
  SET role = p_source_new_role,
      updated_by = v_actor_user_id,
      updated_at = pg_catalog.now()
  WHERE company_user.id = v_source.id
  RETURNING * INTO v_source;

  RETURN QUERY
  SELECT v_source.id, v_source.role, v_target.id, v_target.role;
END;
$$;

REVOKE ALL ON FUNCTION public.transfer_company_ownership(uuid, uuid, public.company_role) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.transfer_company_ownership(uuid, uuid, public.company_role) FROM anon;
GRANT EXECUTE ON FUNCTION public.transfer_company_ownership(uuid, uuid, public.company_role) TO authenticated;

COMMIT;
