-- Issue #32: authoritative atomic tenant resource quotas.
-- Source-only until separately approved Development migration execution.
-- Preserve over-cap legacy data, existing audit/realtime and RPC signatures.
BEGIN;

-- Reuse the #354 entitlement source for BOTH read APIs and internal gates.
-- No parallel interpretation of policies or future paid-provider semantics.
CREATE FUNCTION private.resolve_company_effective_entitlement(p_company_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_company public.companies%ROWTYPE;
  v_grant public.company_subscriptions%ROWTYPE;
  v_plan public.subscription_plans%ROWTYPE;
  v_policy private.entitlement_policy_versions%ROWTYPE;
  v_status text;
BEGIN
  SELECT * INTO v_company
    FROM public.companies WHERE id = p_company_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2851',
      MESSAGE = 'entitlement_unavailable';
  END IF;

  SELECT * INTO v_grant
    FROM public.company_subscriptions WHERE company_id = p_company_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2851',
      MESSAGE = 'entitlement_unavailable';
  END IF;

  SELECT * INTO v_plan
    FROM public.subscription_plans WHERE id = v_grant.plan_id;
  SELECT * INTO v_policy
    FROM private.entitlement_policy_versions
    WHERE plan_id = v_grant.plan_id
      AND version = v_grant.policy_version;

  IF v_plan.id IS NULL OR v_policy.id IS NULL
     OR v_grant.effective_at IS NULL
     OR v_grant.policy_version IS NULL
     OR v_grant.revision <= 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P2852',
      MESSAGE = 'entitlement_integrity_error';
  END IF;

  IF v_grant.grant_source IN ('free_starter', 'legacy_backfill')
     AND (
       v_plan.code <> 'free_starter' OR v_plan.monthly_price <> 0
       OR v_grant.external_provider IS NOT NULL
       OR v_grant.external_subscription_id IS NOT NULL
       OR v_grant.trial_ends_at IS NOT NULL
     ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2852',
      MESSAGE = 'entitlement_integrity_error';
  END IF;

  v_status := CASE
    WHEN NOT v_company.is_active THEN 'suspended'
    WHEN v_grant.effective_at > pg_catalog.now() THEN 'suspended'
    WHEN v_grant.status = 'suspended'::public.subscription_status THEN 'suspended'
    WHEN v_grant.status = 'expired'::public.subscription_status THEN 'expired'
    WHEN v_grant.status = 'cancelled'::public.subscription_status THEN 'revoked'
    WHEN v_grant.expires_at IS NOT NULL
     AND v_grant.expires_at <= now() THEN 'expired'
    WHEN v_grant.status = 'active'::public.subscription_status THEN 'active'
    ELSE 'revoked'
  END;

  RETURN pg_catalog.jsonb_build_object(
    'company_id', v_company.id,
    'plan_code', v_plan.code,
    'policy_version', v_policy.version,
    'revision', v_grant.revision,
    'effective_at', v_grant.effective_at,
    'expires_at', v_grant.expires_at,
    'status', v_status,
    'limits', v_policy.limits,
    'enabled_features', v_policy.enabled_features
  );
END;
$$;

REVOKE ALL ON FUNCTION private.resolve_company_effective_entitlement(uuid)
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_company_effective_entitlement(p_company_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
  IF auth.uid() IS NULL OR p_company_id IS NULL OR NOT private.has_company_role(
    p_company_id,
    ARRAY['owner'::public.company_role, 'admin'::public.company_role]
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2850',
      MESSAGE='entitlement_permission_denied';
  END IF;
  RETURN private.resolve_company_effective_entitlement(p_company_id);
END;
$$;

REVOKE ALL ON FUNCTION public.get_company_effective_entitlement(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_company_effective_entitlement(uuid)
  TO authenticated;

-- Count only active membership and unique live invitation reservations.
-- Sent or still-unconfirmed prepared invitations reserve until expiry unless
-- definitely rejected/revoked; staged resend never counts twice.
CREATE FUNCTION private.company_quota_used(
  p_company_id uuid, p_resource text
)
RETURNS bigint
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_used bigint;
BEGIN
  IF p_resource = 'company_users' THEN
    SELECT
      (SELECT pg_catalog.count(*)
       FROM public.company_users member
       WHERE member.company_id=p_company_id AND member.is_active=true)
      +
      (SELECT pg_catalog.count(*)
       FROM public.company_invitations invitation
       WHERE invitation.company_id=p_company_id
         AND invitation.status='pending'::public.company_invitation_status
         AND GREATEST(
           invitation.expires_at,
           COALESCE(
             invitation.pending_token_expires_at, invitation.expires_at
           )
         ) > pg_catalog.now()
         AND NOT EXISTS (
           SELECT 1
           FROM public.company_users active_member
           JOIN auth.users account ON account.id=active_member.user_id
           WHERE active_member.company_id=p_company_id
             AND active_member.is_active=true
             AND pg_catalog.lower(pg_catalog.btrim(account.email)) =
               invitation.email_normalized
         )
      )
      INTO v_used;
  ELSIF p_resource = 'combined_vehicles' THEN
    SELECT
      (SELECT pg_catalog.count(*) FROM public.tractor_heads
        WHERE company_id=p_company_id AND is_active=true)
      +
      (SELECT pg_catalog.count(*) FROM public.trailers
        WHERE company_id=p_company_id AND is_active=true)
      INTO v_used;
  ELSE
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_unsupported_resource';
  END IF;
  RETURN v_used;
END;
$$;

REVOKE ALL ON FUNCTION private.company_quota_used(uuid,text)
  FROM PUBLIC, anon, authenticated;

-- Every quota-increasing writer locks the same company row FIRST.
-- READ COMMITTED rechecks the committed occupancy after waiting for the lock.
CREATE FUNCTION private.assert_company_quota_capacity(
  p_company_id uuid, p_resource text, p_additional integer
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_entitlement jsonb;
  v_limit_text text;
  v_limit bigint;
  v_used bigint;
BEGIN
  IF p_company_id IS NULL OR p_additional IS NULL OR p_additional <= 0 THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_invalid_request';
  END IF;
  IF p_resource NOT IN ('company_users', 'combined_vehicles')
     OR p_resource IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_unsupported_resource';
  END IF;

  PERFORM 1 FROM public.companies company_row
  WHERE company_row.id=p_company_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2861',
      MESSAGE='quota_entitlement_unavailable';
  END IF;

  v_entitlement := private.resolve_company_effective_entitlement(p_company_id);
  IF v_entitlement->>'status' IS DISTINCT FROM 'active' THEN
    RAISE EXCEPTION USING ERRCODE='P2861',
      MESSAGE='quota_entitlement_unavailable';
  END IF;

  v_limit_text := v_entitlement->'limits'->>p_resource;
  IF v_limit_text IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_policy_invalid';
  END IF;
  IF v_limit_text='unlimited' THEN
    RETURN;
  END IF;
  IF v_limit_text !~ '^(0|[1-9][0-9]*)$' THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_policy_invalid';
  END IF;
  v_limit := v_limit_text::bigint;
  v_used := private.company_quota_used(p_company_id,p_resource);
  IF v_used+p_additional > v_limit THEN
    RAISE EXCEPTION USING ERRCODE='P2860',
      MESSAGE=CASE p_resource
        WHEN 'company_users' THEN 'quota_company_users_reached'
        ELSE 'quota_combined_vehicles_reached'
      END;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION private.assert_company_quota_capacity(uuid,text,integer)
  FROM PUBLIC, anon, authenticated;

CREATE FUNCTION public.get_company_quota_usage(p_company_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog
AS $$
DECLARE
  v_entitlement jsonb;
BEGIN
  IF auth.uid() IS NULL OR p_company_id IS NULL OR NOT private.has_company_role(
    p_company_id,
    ARRAY['owner'::public.company_role, 'admin'::public.company_role]
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2863',
      MESSAGE='quota_permission_denied';
  END IF;

  v_entitlement := private.resolve_company_effective_entitlement(p_company_id);
  RETURN pg_catalog.jsonb_build_object(
    'entitlement',v_entitlement,
    'usage',pg_catalog.jsonb_build_object(
      'company_users',private.company_quota_used(p_company_id,'company_users'),
      'combined_vehicles',private.company_quota_used(p_company_id,'combined_vehicles')
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_company_quota_usage(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_company_quota_usage(uuid)
  TO authenticated;

-- Direct authenticated REST INSERT/UPDATE remain possible under existing RLS.
-- These BEFORE triggers cover the untrusted API, not just Flutter clients.
CREATE FUNCTION private.enforce_combined_vehicle_quota()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog
AS $$
BEGIN
  -- BEFORE triggers may execute before RLS WITH CHECK. Authorize the
  -- signed client actor before inspecting sensitive tenant quota occupancy.
  -- Trusted internal DB fixture/maintenance roles still use the same
  -- capacity check, without requiring an end-user JWT.
  IF (auth.uid() IS NOT NULL OR
      pg_catalog.current_setting('request.jwt.claim.role', true) = 'authenticated'
     ) AND NOT private.has_company_role(
       NEW.company_id,
       ARRAY[
         'owner'::public.company_role,
         'admin'::public.company_role,
         'operations'::public.company_role
       ]
     ) THEN
    RAISE EXCEPTION USING ERRCODE='42501',
      MESSAGE='fleet_permission_denied';
  END IF;

  IF TG_OP='UPDATE' THEN
    IF NEW.company_id IS DISTINCT FROM OLD.company_id THEN
      RAISE EXCEPTION USING ERRCODE='P2864',
        MESSAGE='fleet_company_reassignment_denied';
    END IF;
    IF NOT OLD.is_active AND NEW.is_active THEN
      PERFORM private.assert_company_quota_capacity(
        NEW.company_id,'combined_vehicles',1
      );
    END IF;
  ELSIF NEW.is_active THEN
    PERFORM private.assert_company_quota_capacity(
      NEW.company_id,'combined_vehicles',1
    );
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.enforce_combined_vehicle_quota()
  FROM PUBLIC, anon, authenticated;

CREATE TRIGGER tractor_heads_enforce_combined_quota
  BEFORE INSERT OR UPDATE OF is_active,company_id
  ON public.tractor_heads
  FOR EACH ROW EXECUTE FUNCTION private.enforce_combined_vehicle_quota();

CREATE TRIGGER trailers_enforce_combined_quota
  BEFORE INSERT OR UPDATE OF is_active,company_id
  ON public.trailers
  FOR EACH ROW EXECUTE FUNCTION private.enforce_combined_vehicle_quota();

CREATE INDEX IF NOT EXISTS company_users_active_quota_idx
  ON public.company_users(company_id) WHERE is_active=true;
CREATE INDEX IF NOT EXISTS tractor_heads_active_quota_idx
  ON public.tractor_heads(company_id) WHERE is_active=true;
CREATE INDEX IF NOT EXISTS trailers_active_quota_idx
  ON public.trailers(company_id) WHERE is_active=true;

-- Retain existing public RPC signatures, role gates, idempotency and audit.
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
    AND invitation.expires_at <= pg_catalog.now()
    AND (invitation.pending_token_expires_at IS NULL
      OR invitation.pending_token_expires_at <= pg_catalog.now());

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

  -- The company row is locked above; this check and the reservation commit
  -- are serialized with other seat-consuming transitions.
  PERFORM private.assert_company_quota_capacity(
    p_company_id, 'company_users', 1
  );

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

CREATE OR REPLACE FUNCTION public.reactivate_company_member(
  p_company_id uuid, p_membership_id uuid
)
RETURNS TABLE (
  membership_id uuid, membership_role public.company_role, is_active boolean
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
    RAISE EXCEPTION USING ERRCODE='P2820',
      MESSAGE='company_membership_auth_required';
  END IF;

  PERFORM 1 FROM public.companies company_row
  WHERE company_row.id=p_company_id AND company_row.is_active=true FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2822', MESSAGE='company_not_found';
  END IF;

  SELECT company_user.role INTO v_actor_role
  FROM public.company_users company_user
  WHERE company_user.company_id=p_company_id
    AND company_user.user_id=v_actor_user_id AND company_user.is_active=true
  FOR UPDATE;
  IF NOT FOUND OR v_actor_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING ERRCODE='P2826',
      MESSAGE='company_member_status_change_not_allowed';
  END IF;

  SELECT company_user.* INTO v_target FROM public.company_users company_user
  WHERE company_user.company_id=p_company_id
    AND company_user.id=p_membership_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2824', MESSAGE='company_member_not_found';
  END IF;
  IF v_target.is_active THEN
    RETURN QUERY SELECT v_target.id,v_target.role,v_target.is_active;
    RETURN;
  END IF;
  IF v_target.role='owner'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE='P2827',
      MESSAGE='company_ownership_command_required';
  END IF;
  IF v_actor_role='admin'::public.company_role
    AND v_target.role='admin'::public.company_role THEN
    RAISE EXCEPTION USING ERRCODE='P2826',
      MESSAGE='company_member_status_change_not_allowed';
  END IF;

  PERFORM private.assert_company_quota_capacity(
    p_company_id, 'company_users', 1
  );

  UPDATE public.company_users company_user
  SET is_active=true,updated_by=v_actor_user_id,updated_at=pg_catalog.now()
  WHERE company_user.id=v_target.id RETURNING * INTO v_target;
  PERFORM private.write_audit_event(
    p_company_id,'company_users','company_user',v_target.id::text,
    v_target.user_id::text,'reactivated','company_membership_reactivated',
    pg_catalog.jsonb_build_object('is_active',false,'role',v_target.role::text),
    pg_catalog.jsonb_build_object('is_active',true,'role',v_target.role::text),
    pg_catalog.jsonb_build_object('user_id',v_target.user_id)
  );
  RETURN QUERY SELECT v_target.id,v_target.role,v_target.is_active;
END;
$$;

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
  v_preflight_company_id uuid;
  v_preflight_invitation_id uuid;
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

  -- Read the invitation locator without a row lock first. Locking its row
  -- before the company row used to invert the prepare/accept lock order.
  SELECT invitation.*
  INTO v_invitation
  FROM public.company_invitations invitation
  WHERE invitation.token_hash = p_token_hash
     OR invitation.pending_token_hash = p_token_hash;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'company_invitation_invalid';
  END IF;

  v_preflight_company_id := v_invitation.company_id;
  v_preflight_invitation_id := v_invitation.id;

  -- Preserve idempotent replay of already accepted links, including
  -- historical memberships in a company which was subsequently suspended.
  IF v_invitation.status = 'accepted'::public.company_invitation_status THEN
    IF v_actor_email IS DISTINCT FROM v_invitation.email_normalized THEN
      RAISE EXCEPTION USING ERRCODE = 'P2814', MESSAGE = 'company_invitation_email_mismatch';
    END IF;
    IF v_invitation.accepted_by_user_id = v_actor_user_id THEN
      SELECT company_user.* INTO v_membership
      FROM public.company_users company_user
      WHERE company_user.company_id = v_preflight_company_id
        AND company_user.user_id = v_actor_user_id;
      IF FOUND THEN
        RETURN QUERY SELECT v_membership.id, v_membership.company_id, v_membership.role;
        RETURN;
      END IF;
    END IF;
    RAISE EXCEPTION USING ERRCODE = 'P2810', MESSAGE = 'company_invitation_already_accepted';
  END IF;

  -- One lock order for pending acceptance and invite preparation:
  -- companies -> invitations -> membership target.
  PERFORM 1 FROM public.companies company_row
  WHERE company_row.id = v_preflight_company_id
    AND company_row.is_active = true
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'company_not_found';
  END IF;

  SELECT invitation.*
  INTO v_invitation
  FROM public.company_invitations invitation
  WHERE invitation.id = v_preflight_invitation_id
    AND invitation.company_id = v_preflight_company_id
    AND (invitation.token_hash = p_token_hash
      OR invitation.pending_token_hash = p_token_hash)
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

-- A definitive FIRST-send provider rejection releases its reserved seat.
-- An ambiguous network outcome deliberately retains the reserved token.
CREATE FUNCTION public.abort_company_invitation_initial(
  p_company_id uuid,
  p_invitation_id uuid,
  p_delivery_attempt_id uuid,
  p_confirmation_proof bytea
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_actor_role public.company_role;
  v_invitation public.company_invitations%ROWTYPE;
  v_key_hash bytea;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2800',MESSAGE='company_auth_required';
  END IF;
  SELECT guard.key_hash INTO v_key_hash
  FROM private.company_invitation_confirmation_keys guard
  WHERE guard.singleton=true;
  IF v_key_hash IS NULL OR p_confirmation_proof IS DISTINCT FROM extensions.hmac(
    pg_catalog.convert_to(
      p_company_id::text||':'||p_invitation_id::text||':'||
      p_delivery_attempt_id::text||':abort_initial','UTF8'
    ),v_key_hash,'sha256'
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2813',
      MESSAGE='company_invitation_delivery_confirmation_invalid';
  END IF;
  PERFORM 1 FROM public.companies company_row
  WHERE company_row.id=p_company_id AND company_row.is_active=true
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2801',MESSAGE='company_not_found';
  END IF;
  SELECT member.role INTO v_actor_role FROM public.company_users member
  WHERE member.company_id=p_company_id
    AND member.user_id=v_actor AND member.is_active=true
  FOR UPDATE;
  IF NOT FOUND OR v_actor_role NOT IN ('owner','admin') THEN
    RAISE EXCEPTION USING ERRCODE='P2805',
      MESSAGE='company_invitation_permission_denied';
  END IF;
  SELECT invitation.* INTO v_invitation
  FROM public.company_invitations invitation
  WHERE invitation.id=p_invitation_id
    AND invitation.company_id=p_company_id FOR UPDATE;
  IF NOT FOUND OR v_invitation.status<>'pending'::public.company_invitation_status
    OR v_invitation.send_count<>0
    OR v_invitation.delivery_attempt_id IS DISTINCT FROM p_delivery_attempt_id
    OR v_invitation.last_confirmed_delivery_attempt_id IS NOT NULL
    OR v_invitation.pending_delivery_attempt_id IS NOT NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2813',
      MESSAGE='company_invitation_delivery_confirmation_invalid';
  END IF;

  UPDATE public.company_invitations invitation
  SET status='revoked'::public.company_invitation_status,
      revoked_at=pg_catalog.now(),revoked_by_user_id=v_actor,
      updated_at=pg_catalog.now()
  WHERE invitation.id=p_invitation_id;
  PERFORM private.write_audit_event(
    p_company_id,'company_users','company_invitation',
    p_invitation_id::text,v_invitation.email_normalized,
    'revoked','company_invitation_initial_send_rejected',
    pg_catalog.jsonb_build_object('status','pending'),
    pg_catalog.jsonb_build_object('status','revoked','reason','provider_rejected'),
    pg_catalog.jsonb_build_object('delivery_attempt_id',p_delivery_attempt_id)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.abort_company_invitation_initial(uuid,uuid,uuid,bytea)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.abort_company_invitation_initial(uuid,uuid,uuid,bytea)
  TO authenticated;

-- The original membership/invitation and Fleet RLS and grants remain in force.
-- Server audit/realtime triggers remain unchanged and see only committed rows.

-- Revocation releases a reserved seat even if only the staged resend is live.
-- Existing role restrictions, signature and structured audit are preserved.
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

  -- Serialize seat release with prepare/accept/reactivation: company first.
  -- Authorized revocation remains available on suspended companies.
  PERFORM 1 FROM public.companies company_row
  WHERE company_row.id = p_company_id FOR UPDATE;
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

  IF v_invitation.status = 'revoked'::public.company_invitation_status THEN
    RETURN QUERY SELECT v_invitation.id, v_invitation.status, v_invitation.revoked_at;
    RETURN;
  END IF;

  IF v_invitation.status = 'accepted'::public.company_invitation_status THEN
    RAISE EXCEPTION USING ERRCODE = 'P2810', MESSAGE = 'company_invitation_already_accepted';
  END IF;

  -- A staged resend may still reserve a seat after the original token expires.
  IF v_invitation.status = 'expired'::public.company_invitation_status
     OR GREATEST(
       v_invitation.expires_at,
       COALESCE(v_invitation.pending_token_expires_at, v_invitation.expires_at)
     ) <= pg_catalog.now() THEN
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
REVOKE ALL ON FUNCTION public.revoke_company_invitation(uuid,uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.revoke_company_invitation(uuid,uuid)
  TO authenticated;

-- Operator recovery may not bypass limits without an approved override.
-- Keep #370 role checks, owner protection, optimistic locking and audit.
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
AS $$
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
    OR v_case_reference !~ '^[A-Za-z0-9][A-Za-z0-9._:-]*
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

  -- Platform recovery is not a quota override. #358 will own audited overrides.
  -- The company row was locked before the target membership row above.
  IF v_before.is_active IS FALSE AND v_new_active IS TRUE THEN
    PERFORM private.assert_company_quota_capacity(
      p_company_id, 'company_users', 1
    );
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
$$;
REVOKE ALL ON FUNCTION public.recover_company_membership_as_platform_admin(
  uuid,uuid,public.company_role,boolean,timestamptz,text,text
) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.recover_company_membership_as_platform_admin(
  uuid,uuid,public.company_role,boolean,timestamptz,text,text
) TO authenticated;

COMMIT;
