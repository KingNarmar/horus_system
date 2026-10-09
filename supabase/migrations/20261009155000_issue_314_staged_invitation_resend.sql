-- H.O.R.U.S System Issue #314: staged resend token prevents invalidating a live link
-- This migration is for review only; DO NOT apply to Production without explicit approval.
BEGIN;

ALTER TABLE public.company_invitations
  ADD COLUMN pending_token_hash bytea,
  ADD COLUMN pending_token_expires_at timestamptz,
  ADD COLUMN pending_delivery_attempt_id uuid,
  ADD CONSTRAINT company_invitation_pending_token_consistency CHECK (
    (pending_token_hash IS NULL AND pending_token_expires_at IS NULL
      AND pending_delivery_attempt_id IS NULL)
    OR (pending_token_hash IS NOT NULL
      AND pg_catalog.octet_length(pending_token_hash) = 32
      AND pending_token_expires_at IS NOT NULL
      AND pending_delivery_attempt_id IS NOT NULL)
  );

CREATE UNIQUE INDEX company_invitation_pending_token_hash_uidx
  ON public.company_invitations(pending_token_hash)
  WHERE pending_token_hash IS NOT NULL;

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

  IF v_invitation.pending_delivery_attempt_id IS NOT NULL
     AND v_invitation.pending_token_expires_at > pg_catalog.now() THEN
    RAISE EXCEPTION USING ERRCODE = 'P2816', MESSAGE = 'company_invitation_resend_pending';
  END IF;

  v_old_expires_at := v_invitation.expires_at;

  UPDATE public.company_invitations invitation
  SET pending_token_hash = p_token_hash,
      pending_token_expires_at = pg_catalog.now() + private.company_invitation_ttl(),
      pending_delivery_attempt_id = extensions.gen_random_uuid(),
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
    pg_catalog.jsonb_build_object('candidate_expires_at', v_invitation.pending_token_expires_at),
    '{}'::jsonb
  );

  RETURN QUERY
  SELECT
    v_invitation.id,
    v_invitation.company_id,
    v_invitation.email_normalized,
    v_invitation.role,
    v_invitation.pending_token_expires_at,
    v_invitation.pending_delivery_attempt_id;
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

  IF v_invitation.delivery_attempt_id IS DISTINCT FROM p_delivery_attempt_id
     AND v_invitation.pending_delivery_attempt_id IS DISTINCT FROM p_delivery_attempt_id THEN
    RAISE EXCEPTION USING ERRCODE = 'P2813', MESSAGE = 'company_invitation_delivery_confirmation_invalid';
  END IF;

  IF v_invitation.last_confirmed_delivery_attempt_id = p_delivery_attempt_id THEN
    RETURN QUERY
    SELECT v_invitation.id, v_invitation.status, v_invitation.send_count, v_invitation.last_sent_at;
    RETURN;
  END IF;

  IF v_invitation.pending_delivery_attempt_id = p_delivery_attempt_id THEN
    IF v_invitation.pending_token_expires_at <= pg_catalog.now() THEN
      RAISE EXCEPTION USING ERRCODE = 'P2812', MESSAGE = 'company_invitation_expired';
    END IF;

    UPDATE public.company_invitations invitation
    SET token_hash = invitation.pending_token_hash,
        expires_at = invitation.pending_token_expires_at,
        delivery_attempt_id = invitation.pending_delivery_attempt_id,
        pending_token_hash = NULL,
        pending_token_expires_at = NULL,
        pending_delivery_attempt_id = NULL,
        updated_at = pg_catalog.now()
    WHERE invitation.id = p_invitation_id
    RETURNING * INTO v_invitation;
  ELSIF v_invitation.expires_at <= pg_catalog.now() THEN
    RAISE EXCEPTION USING ERRCODE = 'P2812', MESSAGE = 'company_invitation_expired';
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
CREATE OR REPLACE FUNCTION public.abort_company_invitation_resend(
  p_company_id uuid,
  p_invitation_id uuid,
  p_delivery_attempt_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_id uuid := auth.uid();
  v_role public.company_role;
  v_invitation public.company_invitations%ROWTYPE;
BEGIN
  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2800', MESSAGE = 'company_auth_required';
  END IF;

  SELECT company_user.role INTO v_role
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_id
    AND company_user.is_active = true
  FOR UPDATE;

  IF NOT FOUND OR v_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING ERRCODE = 'P2805', MESSAGE = 'company_invitation_permission_denied';
  END IF;

  SELECT invitation.* INTO v_invitation
  FROM public.company_invitations invitation
  WHERE invitation.company_id = p_company_id
    AND invitation.id = p_invitation_id
  FOR UPDATE;

  IF NOT FOUND OR v_invitation.status <> 'pending'::public.company_invitation_status THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'company_invitation_invalid';
  END IF;

  IF v_role = 'admin'::public.company_role
     AND v_invitation.role = 'admin'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE = 'P2803', MESSAGE = 'company_invitation_role_not_allowed';
  END IF;

  IF v_invitation.pending_delivery_attempt_id IS DISTINCT FROM p_delivery_attempt_id THEN
    RAISE EXCEPTION USING ERRCODE = 'P2813', MESSAGE = 'company_invitation_delivery_confirmation_invalid';
  END IF;

  UPDATE public.company_invitations invitation
  SET pending_token_hash = NULL,
      pending_token_expires_at = NULL,
      pending_delivery_attempt_id = NULL,
      updated_at = pg_catalog.now()
  WHERE invitation.id = p_invitation_id;

  PERFORM private.write_audit_event(
    p_company_id, 'company_users', 'company_invitation',
    p_invitation_id::text, v_invitation.email_normalized,
    'updated', 'company_invitation_resend_rejected',
    '{}'::jsonb, pg_catalog.jsonb_build_object('attempt_rejected', true),
    '{}'::jsonb
  );
END;
$$;

REVOKE ALL ON FUNCTION public.abort_company_invitation_resend(uuid, uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.abort_company_invitation_resend(uuid, uuid, uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.abort_company_invitation_resend(uuid, uuid, uuid) TO authenticated;
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
      pending_token_hash = NULL,
      pending_token_expires_at = NULL,
      pending_delivery_attempt_id = NULL,
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
  v_token_expires_at timestamptz;
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
  WHERE invitation.token_hash = p_token_hash
     OR invitation.pending_token_hash = p_token_hash;

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

  v_token_expires_at := CASE
    WHEN v_invitation.pending_token_hash = p_token_hash
      THEN v_invitation.pending_token_expires_at
    ELSE v_invitation.expires_at
  END;

  v_effective_status := CASE
    WHEN v_invitation.status = 'pending'::public.company_invitation_status
         AND v_token_expires_at <= pg_catalog.now()
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
    v_token_expires_at;
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
  v_token_expires_at timestamptz;
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
     OR invitation.pending_token_hash = p_token_hash
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'company_invitation_invalid';
  END IF;

  IF v_actor_email IS DISTINCT FROM v_invitation.email_normalized THEN
    RAISE EXCEPTION USING ERRCODE = 'P2814', MESSAGE = 'company_invitation_email_mismatch';
  END IF;

  v_token_expires_at := CASE
    WHEN v_invitation.pending_token_hash = p_token_hash
      THEN v_invitation.pending_token_expires_at
    ELSE v_invitation.expires_at
  END;

  IF v_invitation.status = 'revoked'::public.company_invitation_status THEN
    RAISE EXCEPTION USING ERRCODE = 'P2811', MESSAGE = 'company_invitation_revoked';
  END IF;

  IF v_invitation.status = 'expired'::public.company_invitation_status
     OR v_token_expires_at <= pg_catalog.now() THEN
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
      -- Preserve idempotent acceptance when an unconfirmed candidate link wins.
      token_hash = CASE
        WHEN invitation.pending_token_hash = p_token_hash
          THEN invitation.pending_token_hash
        ELSE invitation.token_hash
      END,
      expires_at = CASE
        WHEN invitation.pending_token_hash = p_token_hash
          THEN invitation.pending_token_expires_at
        ELSE invitation.expires_at
      END,
      pending_token_hash = NULL,
      pending_token_expires_at = NULL,
      pending_delivery_attempt_id = NULL,
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
