-- H.O.R.U.S System — Issue #203 Company invitations and membership lifecycle
-- Secure, audited invitation commands. Raw invitation tokens remain outside Postgres.

BEGIN;

ALTER TABLE public.company_invitations
  ADD CONSTRAINT company_invitations_token_hash_length_check
  CHECK (octet_length(token_hash) = 32);

CREATE OR REPLACE FUNCTION private.company_invitation_ttl()
RETURNS interval
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog
AS $$
  SELECT interval '7 days';
$$;

REVOKE ALL ON FUNCTION private.company_invitation_ttl() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.company_invitation_ttl() FROM anon;
REVOKE ALL ON FUNCTION private.company_invitation_ttl() FROM authenticated;

CREATE OR REPLACE FUNCTION public.prepare_company_invitation(
  p_company_id uuid,
  p_email text,
  p_role public.company_role,
  p_token_hash bytea
)
RETURNS TABLE (
  invitation_id uuid,
  company_id uuid,
  email_normalized text,
  invitation_role public.company_role,
  expires_at timestamptz,
  delivery_attempt_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role public.company_role;
  v_email text := pg_catalog.lower(pg_catalog.btrim(p_email));
  v_existing_member public.company_users%ROWTYPE;
  v_invitation public.company_invitations%ROWTYPE;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2800', MESSAGE = 'company_auth_required';
  END IF;

  IF p_company_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'company_not_found';
  END IF;

  IF v_email IS NULL
     OR pg_catalog.char_length(v_email) < 3
     OR pg_catalog.char_length(v_email) > 320
     OR v_email !~ '^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$' THEN
    RAISE EXCEPTION USING ERRCODE = 'P2802', MESSAGE = 'company_invitation_email_invalid';
  END IF;

  IF p_role IS NULL OR p_role = 'owner'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2803', MESSAGE = 'company_invitation_role_not_allowed';
  END IF;

  IF p_token_hash IS NULL OR pg_catalog.octet_length(p_token_hash) <> 32 THEN
    RAISE EXCEPTION USING ERRCODE = 'P2804', MESSAGE = 'company_invitation_token_invalid';
  END IF;

  PERFORM 1
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'company_not_found';
  END IF;

  SELECT company_user.role
  INTO v_actor_role
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true
  FOR UPDATE;

  IF NOT FOUND OR v_actor_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING ERRCODE = 'P2805', MESSAGE = 'company_invitation_permission_denied';
  END IF;

  IF v_actor_role = 'admin'::public.company_role
     AND p_role = 'admin'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2803', MESSAGE = 'company_invitation_role_not_allowed';
  END IF;

  UPDATE public.company_invitations invitation
  SET status = 'expired'::public.company_invitation_status,
      updated_at = pg_catalog.now()
  WHERE invitation.company_id = p_company_id
    AND invitation.email_normalized = v_email
    AND invitation.status = 'pending'::public.company_invitation_status
    AND invitation.expires_at <= pg_catalog.now();

  SELECT company_user.*
  INTO v_existing_member
  FROM auth.users auth_user
  JOIN public.company_users company_user
    ON company_user.user_id = auth_user.id
   AND company_user.company_id = p_company_id
  WHERE pg_catalog.lower(pg_catalog.btrim(auth_user.email)) = v_email
  LIMIT 1
  FOR UPDATE OF company_user;

  IF FOUND THEN
    IF v_existing_member.is_active THEN
      RAISE EXCEPTION USING ERRCODE = 'P2806', MESSAGE = 'company_member_already_active';
    END IF;

    RAISE EXCEPTION USING ERRCODE = 'P2807', MESSAGE = 'company_member_inactive';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.company_invitations invitation
    WHERE invitation.company_id = p_company_id
      AND invitation.email_normalized = v_email
      AND invitation.status = 'pending'::public.company_invitation_status
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2808', MESSAGE = 'company_invitation_already_pending';
  END IF;

  INSERT INTO public.company_invitations (
    company_id,
    email_normalized,
    role,
    token_hash,
    invited_by_user_id,
    expires_at
  )
  VALUES (
    p_company_id,
    v_email,
    p_role,
    p_token_hash,
    v_actor_user_id,
    pg_catalog.now() + private.company_invitation_ttl()
  )
  RETURNING * INTO v_invitation;

  PERFORM private.write_audit_event(
    p_company_id,
    'company_users',
    'company_invitation',
    v_invitation.id::text,
    v_email,
    'created',
    'company_invitation_created',
    '{}'::jsonb,
    pg_catalog.jsonb_build_object(
      'email', v_email,
      'role', p_role::text,
      'status', 'pending',
      'expires_at', v_invitation.expires_at
    ),
    '{}'::jsonb
  );

  RETURN QUERY
  SELECT
    v_invitation.id,
    v_invitation.company_id,
    v_invitation.email_normalized,
    v_invitation.role,
    v_invitation.expires_at,
    v_invitation.delivery_attempt_id;
END;
$$;

REVOKE ALL ON FUNCTION public.prepare_company_invitation(uuid, text, public.company_role, bytea) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.prepare_company_invitation(uuid, text, public.company_role, bytea) FROM anon;
GRANT EXECUTE ON FUNCTION public.prepare_company_invitation(uuid, text, public.company_role, bytea) TO authenticated;

CREATE OR REPLACE FUNCTION public.prepare_company_invitation_resend(
  p_company_id uuid,
  p_invitation_id uuid,
  p_token_hash bytea
)
RETURNS TABLE (
  invitation_id uuid,
  company_id uuid,
  email_normalized text,
  invitation_role public.company_role,
  expires_at timestamptz,
  delivery_attempt_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role public.company_role;
  v_invitation public.company_invitations%ROWTYPE;
  v_old_expires_at timestamptz;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2800', MESSAGE = 'company_auth_required';
  END IF;

  IF p_token_hash IS NULL OR pg_catalog.octet_length(p_token_hash) <> 32 THEN
    RAISE EXCEPTION USING ERRCODE = 'P2804', MESSAGE = 'company_invitation_token_invalid';
  END IF;

  PERFORM 1
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'company_not_found';
  END IF;

  SELECT company_user.role
  INTO v_actor_role
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true
  FOR UPDATE;

  IF NOT FOUND OR v_actor_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING ERRCODE = 'P2805', MESSAGE = 'company_invitation_permission_denied';
  END IF;

  SELECT invitation.*
  INTO v_invitation
  FROM public.company_invitations invitation
  WHERE invitation.company_id = p_company_id
    AND invitation.id = p_invitation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'company_invitation_invalid';
  END IF;

  IF v_invitation.status = 'accepted'::public.company_invitation_status THEN
    RAISE EXCEPTION USING ERRCODE = 'P2810', MESSAGE = 'company_invitation_already_accepted';
  END IF;

  IF v_invitation.status = 'revoked'::public.company_invitation_status THEN
    RAISE EXCEPTION USING ERRCODE = 'P2811', MESSAGE = 'company_invitation_revoked';
  END IF;

  IF v_invitation.status = 'expired'::public.company_invitation_status
     OR v_invitation.expires_at <= pg_catalog.now() THEN
    RAISE EXCEPTION USING ERRCODE = 'P2812', MESSAGE = 'company_invitation_expired';
  END IF;

  IF v_actor_role = 'admin'::public.company_role
     AND v_invitation.role = 'admin'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2803', MESSAGE = 'company_invitation_role_not_allowed';
  END IF;

  v_old_expires_at := v_invitation.expires_at;

  UPDATE public.company_invitations invitation
  SET token_hash = p_token_hash,
      expires_at = pg_catalog.now() + private.company_invitation_ttl(),
      delivery_attempt_id = extensions.gen_random_uuid(),
      updated_at = pg_catalog.now()
  WHERE invitation.id = p_invitation_id
  RETURNING * INTO v_invitation;

  PERFORM private.write_audit_event(
    p_company_id,
    'company_users',
    'company_invitation',
    v_invitation.id::text,
    v_invitation.email_normalized,
    'updated',
    'company_invitation_resend_prepared',
    pg_catalog.jsonb_build_object('expires_at', v_old_expires_at),
    pg_catalog.jsonb_build_object('expires_at', v_invitation.expires_at),
    '{}'::jsonb
  );

  RETURN QUERY
  SELECT
    v_invitation.id,
    v_invitation.company_id,
    v_invitation.email_normalized,
    v_invitation.role,
    v_invitation.expires_at,
    v_invitation.delivery_attempt_id;
END;
$$;

REVOKE ALL ON FUNCTION public.prepare_company_invitation_resend(uuid, uuid, bytea) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.prepare_company_invitation_resend(uuid, uuid, bytea) FROM anon;
GRANT EXECUTE ON FUNCTION public.prepare_company_invitation_resend(uuid, uuid, bytea) TO authenticated;

CREATE OR REPLACE FUNCTION public.confirm_company_invitation_delivery(
  p_company_id uuid,
  p_invitation_id uuid,
  p_delivery_attempt_id uuid
)
RETURNS TABLE (
  invitation_id uuid,
  invitation_status public.company_invitation_status,
  send_count integer,
  last_sent_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role public.company_role;
  v_invitation public.company_invitations%ROWTYPE;
  v_previous_send_count integer;
  v_audit_event text;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2800', MESSAGE = 'company_auth_required';
  END IF;

  SELECT company_user.role
  INTO v_actor_role
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true
  FOR UPDATE;

  IF NOT FOUND OR v_actor_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING ERRCODE = 'P2805', MESSAGE = 'company_invitation_permission_denied';
  END IF;

  SELECT invitation.*
  INTO v_invitation
  FROM public.company_invitations invitation
  WHERE invitation.company_id = p_company_id
    AND invitation.id = p_invitation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'company_invitation_invalid';
  END IF;

  IF v_invitation.status <> 'pending'::public.company_invitation_status THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'company_invitation_invalid';
  END IF;

  IF v_invitation.expires_at <= pg_catalog.now() THEN
    RAISE EXCEPTION USING ERRCODE = 'P2812', MESSAGE = 'company_invitation_expired';
  END IF;

  IF v_invitation.delivery_attempt_id IS DISTINCT FROM p_delivery_attempt_id THEN
    RAISE EXCEPTION USING ERRCODE = 'P2813', MESSAGE = 'company_invitation_delivery_confirmation_invalid';
  END IF;

  IF v_invitation.last_confirmed_delivery_attempt_id = p_delivery_attempt_id THEN
    RETURN QUERY
    SELECT v_invitation.id, v_invitation.status, v_invitation.send_count, v_invitation.last_sent_at;
    RETURN;
  END IF;

  v_previous_send_count := v_invitation.send_count;

  UPDATE public.company_invitations invitation
  SET last_confirmed_delivery_attempt_id = p_delivery_attempt_id,
      last_sent_at = pg_catalog.now(),
      send_count = invitation.send_count + 1,
      updated_at = pg_catalog.now()
  WHERE invitation.id = p_invitation_id
  RETURNING * INTO v_invitation;

  v_audit_event := CASE
    WHEN v_previous_send_count = 0 THEN 'company_invitation_sent'
    ELSE 'company_invitation_resent'
  END;

  PERFORM private.write_audit_event(
    p_company_id,
    'company_users',
    'company_invitation',
    v_invitation.id::text,
    v_invitation.email_normalized,
    CASE WHEN v_previous_send_count = 0 THEN 'sent' ELSE 'resent' END,
    v_audit_event,
    pg_catalog.jsonb_build_object('send_count', v_previous_send_count),
    pg_catalog.jsonb_build_object(
      'send_count', v_invitation.send_count,
      'last_sent_at', v_invitation.last_sent_at
    ),
    '{}'::jsonb
  );

  RETURN QUERY
  SELECT v_invitation.id, v_invitation.status, v_invitation.send_count, v_invitation.last_sent_at;
END;
$$;

REVOKE ALL ON FUNCTION public.confirm_company_invitation_delivery(uuid, uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.confirm_company_invitation_delivery(uuid, uuid, uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.confirm_company_invitation_delivery(uuid, uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.revoke_company_invitation(
  p_company_id uuid,
  p_invitation_id uuid
)
RETURNS TABLE (
  invitation_id uuid,
  invitation_status public.company_invitation_status,
  revoked_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role public.company_role;
  v_invitation public.company_invitations%ROWTYPE;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2800', MESSAGE = 'company_auth_required';
  END IF;

  SELECT company_user.role
  INTO v_actor_role
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true
  FOR UPDATE;

  IF NOT FOUND OR v_actor_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING ERRCODE = 'P2805', MESSAGE = 'company_invitation_permission_denied';
  END IF;

  SELECT invitation.*
  INTO v_invitation
  FROM public.company_invitations invitation
  WHERE invitation.company_id = p_company_id
    AND invitation.id = p_invitation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'company_invitation_invalid';
  END IF;

  IF v_invitation.status = 'revoked'::public.company_invitation_status THEN
    RETURN QUERY SELECT v_invitation.id, v_invitation.status, v_invitation.revoked_at;
    RETURN;
  END IF;

  IF v_invitation.status = 'accepted'::public.company_invitation_status THEN
    RAISE EXCEPTION USING ERRCODE = 'P2810', MESSAGE = 'company_invitation_already_accepted';
  END IF;

  IF v_invitation.status = 'expired'::public.company_invitation_status
     OR v_invitation.expires_at <= pg_catalog.now() THEN
    RAISE EXCEPTION USING ERRCODE = 'P2812', MESSAGE = 'company_invitation_expired';
  END IF;

  IF v_actor_role = 'admin'::public.company_role
     AND v_invitation.role = 'admin'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2803', MESSAGE = 'company_invitation_role_not_allowed';
  END IF;

  UPDATE public.company_invitations invitation
  SET status = 'revoked'::public.company_invitation_status,
      revoked_at = pg_catalog.now(),
      revoked_by_user_id = v_actor_user_id,
      updated_at = pg_catalog.now()
  WHERE invitation.id = p_invitation_id
  RETURNING * INTO v_invitation;

  PERFORM private.write_audit_event(
    p_company_id,
    'company_users',
    'company_invitation',
    v_invitation.id::text,
    v_invitation.email_normalized,
    'revoked',
    'company_invitation_revoked',
    pg_catalog.jsonb_build_object('status', 'pending'),
    pg_catalog.jsonb_build_object(
      'status', 'revoked',
      'revoked_at', v_invitation.revoked_at
    ),
    '{}'::jsonb
  );

  RETURN QUERY SELECT v_invitation.id, v_invitation.status, v_invitation.revoked_at;
END;
$$;

REVOKE ALL ON FUNCTION public.revoke_company_invitation(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.revoke_company_invitation(uuid, uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.revoke_company_invitation(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_company_invitation_preview(
  p_token_hash bytea
)
RETURNS TABLE (
  invitation_id uuid,
  company_id uuid,
  company_name text,
  email_normalized text,
  invitation_role public.company_role,
  effective_status public.company_invitation_status,
  expires_at timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_email text;
  v_invitation public.company_invitations%ROWTYPE;
  v_company_name text;
  v_effective_status public.company_invitation_status;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2800', MESSAGE = 'company_auth_required';
  END IF;

  IF p_token_hash IS NULL OR pg_catalog.octet_length(p_token_hash) <> 32 THEN
    RAISE EXCEPTION USING ERRCODE = 'P2804', MESSAGE = 'company_invitation_token_invalid';
  END IF;

  SELECT pg_catalog.lower(pg_catalog.btrim(auth_user.email))
  INTO v_actor_email
  FROM auth.users auth_user
  WHERE auth_user.id = v_actor_user_id;

  SELECT invitation.*
  INTO v_invitation
  FROM public.company_invitations invitation
  WHERE invitation.token_hash = p_token_hash;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'company_invitation_invalid';
  END IF;

  IF v_actor_email IS DISTINCT FROM v_invitation.email_normalized THEN
    RAISE EXCEPTION USING ERRCODE = 'P2814', MESSAGE = 'company_invitation_email_mismatch';
  END IF;

  SELECT company_row.name
  INTO v_company_name
  FROM public.companies company_row
  WHERE company_row.id = v_invitation.company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'company_not_found';
  END IF;

  v_effective_status := CASE
    WHEN v_invitation.status = 'pending'::public.company_invitation_status
         AND v_invitation.expires_at <= pg_catalog.now()
      THEN 'expired'::public.company_invitation_status
    ELSE v_invitation.status
  END;

  RETURN QUERY
  SELECT
    v_invitation.id,
    v_invitation.company_id,
    v_company_name,
    v_invitation.email_normalized,
    v_invitation.role,
    v_effective_status,
    v_invitation.expires_at;
END;
$$;

REVOKE ALL ON FUNCTION public.get_company_invitation_preview(bytea) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_company_invitation_preview(bytea) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_company_invitation_preview(bytea) TO authenticated;

CREATE OR REPLACE FUNCTION public.accept_company_invitation(
  p_token_hash bytea
)
RETURNS TABLE (
  membership_id uuid,
  company_id uuid,
  membership_role public.company_role
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_email text;
  v_email_confirmed_at timestamptz;
  v_invitation public.company_invitations%ROWTYPE;
  v_existing_member public.company_users%ROWTYPE;
  v_membership public.company_users%ROWTYPE;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2800', MESSAGE = 'company_auth_required';
  END IF;

  IF p_token_hash IS NULL OR pg_catalog.octet_length(p_token_hash) <> 32 THEN
    RAISE EXCEPTION USING ERRCODE = 'P2804', MESSAGE = 'company_invitation_token_invalid';
  END IF;

  SELECT
    pg_catalog.lower(pg_catalog.btrim(auth_user.email)),
    auth_user.email_confirmed_at
  INTO v_actor_email, v_email_confirmed_at
  FROM auth.users auth_user
  WHERE auth_user.id = v_actor_user_id;

  IF v_actor_email IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2814', MESSAGE = 'company_invitation_email_mismatch';
  END IF;

  IF v_email_confirmed_at IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2815', MESSAGE = 'company_invitation_email_not_verified';
  END IF;

  SELECT invitation.*
  INTO v_invitation
  FROM public.company_invitations invitation
  WHERE invitation.token_hash = p_token_hash
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'company_invitation_invalid';
  END IF;

  IF v_actor_email IS DISTINCT FROM v_invitation.email_normalized THEN
    RAISE EXCEPTION USING ERRCODE = 'P2814', MESSAGE = 'company_invitation_email_mismatch';
  END IF;

  IF v_invitation.status = 'revoked'::public.company_invitation_status THEN
    RAISE EXCEPTION USING ERRCODE = 'P2811', MESSAGE = 'company_invitation_revoked';
  END IF;

  IF v_invitation.status = 'expired'::public.company_invitation_status
     OR v_invitation.expires_at <= pg_catalog.now() THEN
    RAISE EXCEPTION USING ERRCODE = 'P2812', MESSAGE = 'company_invitation_expired';
  END IF;

  IF v_invitation.status = 'accepted'::public.company_invitation_status THEN
    IF v_invitation.accepted_by_user_id = v_actor_user_id THEN
      SELECT company_user.*
      INTO v_membership
      FROM public.company_users company_user
      WHERE company_user.company_id = v_invitation.company_id
        AND company_user.user_id = v_actor_user_id;

      IF FOUND THEN
        RETURN QUERY SELECT v_membership.id, v_membership.company_id, v_membership.role;
        RETURN;
      END IF;
    END IF;

    RAISE EXCEPTION USING ERRCODE = 'P2810', MESSAGE = 'company_invitation_already_accepted';
  END IF;

  PERFORM 1
  FROM public.companies company_row
  WHERE company_row.id = v_invitation.company_id
    AND company_row.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'company_not_found';
  END IF;

  SELECT company_user.*
  INTO v_existing_member
  FROM public.company_users company_user
  WHERE company_user.company_id = v_invitation.company_id
    AND company_user.user_id = v_actor_user_id
  FOR UPDATE;

  IF FOUND THEN
    IF v_existing_member.is_active THEN
      RAISE EXCEPTION USING ERRCODE = 'P2806', MESSAGE = 'company_member_already_active';
    END IF;

    RAISE EXCEPTION USING ERRCODE = 'P2807', MESSAGE = 'company_member_inactive';
  END IF;

  INSERT INTO public.company_users (
    company_id,
    user_id,
    role,
    is_active,
    created_by,
    updated_by
  )
  VALUES (
    v_invitation.company_id,
    v_actor_user_id,
    v_invitation.role,
    true,
    v_actor_user_id,
    v_actor_user_id
  )
  RETURNING * INTO v_membership;

  UPDATE public.company_invitations invitation
  SET status = 'accepted'::public.company_invitation_status,
      accepted_at = pg_catalog.now(),
      accepted_by_user_id = v_actor_user_id,
      updated_at = pg_catalog.now()
  WHERE invitation.id = v_invitation.id
  RETURNING * INTO v_invitation;

  PERFORM private.write_audit_event(
    v_invitation.company_id,
    'company_users',
    'company_invitation',
    v_invitation.id::text,
    v_invitation.email_normalized,
    'accepted',
    'company_invitation_accepted',
    pg_catalog.jsonb_build_object('status', 'pending'),
    pg_catalog.jsonb_build_object(
      'status', 'accepted',
      'role', v_invitation.role::text,
      'accepted_at', v_invitation.accepted_at
    ),
    pg_catalog.jsonb_build_object('membership_id', v_membership.id)
  );

  PERFORM private.write_audit_event(
    v_invitation.company_id,
    'company_users',
    'company_user',
    v_membership.id::text,
    v_invitation.email_normalized,
    'created',
    'company_membership_created',
    '{}'::jsonb,
    pg_catalog.jsonb_build_object(
      'user_id', v_actor_user_id,
      'role', v_membership.role::text,
      'is_active', true
    ),
    pg_catalog.jsonb_build_object('invitation_id', v_invitation.id)
  );

  RETURN QUERY SELECT v_membership.id, v_membership.company_id, v_membership.role;
END;
$$;

REVOKE ALL ON FUNCTION public.accept_company_invitation(bytea) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.accept_company_invitation(bytea) FROM anon;
GRANT EXECUTE ON FUNCTION public.accept_company_invitation(bytea) TO authenticated;

COMMIT;
