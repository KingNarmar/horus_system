-- Issue #314: deterministic database protocol verification.
-- Run only on an authorized H.O.R.U.S Development database AFTER the staged
-- invitation resend migration and confirmation-key provisioning.
-- This test does not send mail. All test invitations and audit writes roll back.
-- The test impersonates an existing active company Owner solely inside its
-- transaction; it must not be run against Production.
BEGIN;

DO $issue314$
DECLARE
  v_company uuid;
  v_owner uuid;
  v_invitation uuid;
  v_original_hash bytea;
  v_attempt uuid;
  v_proof_key bytea;
  v_proof bytea;
  v_rejected boolean;
  v_preserved boolean;
  v_send_count integer;
  v_test_suffix text;
  v_viewer uuid;
  v_viewer_company uuid;
  v_unauthorized_rejected boolean := false;
BEGIN
  SELECT member.company_id, member.user_id
    INTO v_company, v_owner
  FROM public.company_users member
  JOIN public.companies company
    ON company.id = member.company_id AND company.is_active = true
  WHERE member.role = 'owner'::public.company_role
    AND member.is_active = true
  ORDER BY member.company_id
  LIMIT 1;

  IF v_owner IS NULL THEN
    RAISE EXCEPTION 'Issue 314 fixture missing active Owner';
  END IF;

  SELECT key_hash INTO v_proof_key
  FROM private.company_invitation_confirmation_keys
  WHERE singleton = true;

  IF v_proof_key IS NULL THEN
    RAISE EXCEPTION 'Issue 314 fixture missing HMAC digest';
  END IF;

  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_owner::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claim.role', 'authenticated', true);

  -- Verify an existing active Viewer cannot prepare a resend. The scope
  -- check must reject before attempting to resolve the invitation UUID.
  SELECT member.company_id, member.user_id
    INTO v_viewer_company, v_viewer
  FROM public.company_users member
  WHERE member.role = 'viewer'::public.company_role
    AND member.is_active = true
  ORDER BY member.company_id
  LIMIT 1;

  IF v_viewer IS NULL THEN
    RAISE EXCEPTION 'Issue 314 fixture missing active Viewer';
  END IF;

  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_viewer::text, true);
  BEGIN
    PERFORM public.prepare_company_invitation_resend(
      v_viewer_company,
      extensions.gen_random_uuid(),
      extensions.digest(
        pg_catalog.convert_to(extensions.gen_random_uuid()::text, 'UTF8'),
        'sha256'
      )
    );
  EXCEPTION WHEN SQLSTATE 'P2805' THEN
    v_unauthorized_rejected := true;
  END;

  IF NOT v_unauthorized_rejected THEN
    RAISE EXCEPTION 'Unauthorized Viewer resend was not rejected';
  END IF;

  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_owner::text, true);

  -- Prepare only. No provider is contacted and the generated email cannot
  -- belong to a real recipient.
  v_test_suffix := pg_catalog.replace(extensions.gen_random_uuid()::text, '-', '');
  SELECT invitation_id INTO v_invitation
  FROM public.prepare_company_invitation(
    v_company,
    'issue314-protocol-' || v_test_suffix || '@example.invalid',
    'viewer'::public.company_role,
    extensions.digest(pg_catalog.convert_to(v_test_suffix, 'UTF8'), 'sha256')
  );

  SELECT token_hash INTO v_original_hash
  FROM public.company_invitations WHERE id = v_invitation;

  SELECT delivery_attempt_id INTO v_attempt
  FROM public.prepare_company_invitation_resend(
    v_company, v_invitation,
    extensions.digest(
      pg_catalog.convert_to(extensions.gen_random_uuid()::text, 'UTF8'),
      'sha256'
    )
  );

  -- Simulate indeterminate provider transport outcome: neither confirm nor
  -- abort. The original token must remain valid at the database boundary.
  SELECT token_hash = v_original_hash
      AND pending_token_hash IS NOT NULL
      AND pending_delivery_attempt_id = v_attempt
    INTO v_preserved
  FROM public.company_invitations WHERE id = v_invitation;

  IF v_preserved IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Original token overwritten during staged resend';
  END IF;

  -- Sequential replay while an unresolved attempt exists is blocked.
  v_rejected := false;
  BEGIN
    PERFORM public.prepare_company_invitation_resend(
      v_company, v_invitation,
      extensions.digest(
        pg_catalog.convert_to(extensions.gen_random_uuid()::text, 'UTF8'),
        'sha256'
      )
    );
  EXCEPTION WHEN SQLSTATE 'P2816' THEN
    v_rejected := true;
  END;

  IF NOT v_rejected THEN
    RAISE EXCEPTION 'Duplicate resend was not blocked';
  END IF;

  -- Simulate definite provider rejection with valid Edge-like HMAC proof.
  -- The private HMAC digest is accessed only by the privileged test runner;
  -- neither the raw Edge secret nor an invitation code appears in this file.
  v_proof := extensions.hmac(
    pg_catalog.convert_to(
      v_company::text || ':' || v_invitation::text || ':' ||
      v_attempt::text || ':abort', 'UTF8'
    ), v_proof_key, 'sha256'
  );
  PERFORM public.abort_company_invitation_resend(
    v_company, v_invitation, v_attempt, v_proof
  );

  SELECT token_hash = v_original_hash
      AND pending_token_hash IS NULL
      AND pending_delivery_attempt_id IS NULL
      AND status = 'pending'::public.company_invitation_status
    INTO v_preserved
  FROM public.company_invitations WHERE id = v_invitation;

  IF v_preserved IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Definite rejection invalidated the original token';
  END IF;

  -- Confirmation is idempotent and cannot double-count an accepted delivery.
  SELECT delivery_attempt_id INTO v_attempt
  FROM public.company_invitations WHERE id = v_invitation;
  v_proof := extensions.hmac(
    pg_catalog.convert_to(
      v_company::text || ':' || v_invitation::text || ':' ||
      v_attempt::text || ':confirm', 'UTF8'
    ), v_proof_key, 'sha256'
  );

  PERFORM public.confirm_company_invitation_delivery(
    v_company, v_invitation, v_attempt, v_proof
  );
  PERFORM public.confirm_company_invitation_delivery(
    v_company, v_invitation, v_attempt, v_proof
  );

  SELECT send_count INTO v_send_count
  FROM public.company_invitations WHERE id = v_invitation;

  IF v_send_count <> 1 THEN
    RAISE EXCEPTION 'Repeated delivery confirmation changed send count: %',
      v_send_count;
  END IF;

  RAISE NOTICE 'ISSUE314_PROTOCOL_TESTS_PASSED';
END
$issue314$;


-- Negative authorization matrix. All identities and test addresses are
-- Development-only fixtures; no email provider is contacted.
-- These RPC checks use simulated JWT claims in an administrative transaction,
-- not real HTTP requests carrying signed user JWTs.
DO $issue314_authorization$
DECLARE
  v_viewer uuid;
  v_viewer_company uuid;
  v_admin uuid;
  v_admin_company uuid;
  v_owner uuid;
  v_foreign_company uuid;
  v_denied boolean;
  v_hash bytea := pg_catalog.decode(pg_catalog.repeat('ab', 32), 'hex');
BEGIN
  SELECT member.user_id, member.company_id INTO v_viewer, v_viewer_company
  FROM public.company_users member
  JOIN public.companies company ON company.id = member.company_id
  WHERE member.role = 'viewer'::public.company_role
    AND member.is_active AND company.is_active
  LIMIT 1;

  SELECT member.user_id, member.company_id INTO v_admin, v_admin_company
  FROM public.company_users member
  JOIN public.companies company ON company.id = member.company_id
  WHERE member.role = 'admin'::public.company_role
    AND member.is_active AND company.is_active
  LIMIT 1;

  SELECT member.user_id, target.id INTO v_owner, v_foreign_company
  FROM public.company_users member
  JOIN public.companies source ON source.id = member.company_id
  JOIN public.companies target ON target.id <> member.company_id
  WHERE member.role = 'owner'::public.company_role AND member.is_active
    AND source.is_active AND target.is_active
    AND NOT EXISTS (
      SELECT 1 FROM public.company_users membership
      WHERE membership.company_id = target.id
        AND membership.user_id = member.user_id
        AND membership.is_active
    )
  LIMIT 1;

  IF v_viewer IS NULL OR v_admin IS NULL OR v_owner IS NULL THEN
    RAISE EXCEPTION 'Issue 314 negative tests require active Viewer, Admin, and cross-company Owner fixtures';
  END IF;

  PERFORM pg_catalog.set_config('request.jwt.claim.role', 'authenticated', true);
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_viewer::text, true);
  v_denied := false;
  BEGIN
    PERFORM public.prepare_company_invitation(
      v_viewer_company, 'issue314-viewer-create@example.invalid',
      'viewer'::public.company_role, v_hash
    );
  EXCEPTION WHEN SQLSTATE 'P2805' THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'Viewer invitation creation must fail with P2805';
  END IF;

  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_admin::text, true);
  v_denied := false;
  BEGIN
    PERFORM public.prepare_company_invitation(
      v_admin_company, 'issue314-admin-create@example.invalid',
      'admin'::public.company_role, v_hash
    );
  EXCEPTION WHEN SQLSTATE 'P2803' THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'Admin inviting Admin must fail with P2803';
  END IF;

  v_denied := false;
  BEGIN
    PERFORM public.prepare_company_invitation(
      v_admin_company, 'issue314-owner-create@example.invalid',
      'owner'::public.company_role, v_hash
    );
  EXCEPTION WHEN SQLSTATE 'P2803' THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'Inviting an Owner must fail with P2803';
  END IF;

  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_owner::text, true);
  v_denied := false;
  BEGIN
    PERFORM public.prepare_company_invitation(
      v_foreign_company, 'issue314-cross-company@example.invalid',
      'viewer'::public.company_role, v_hash
    );
  EXCEPTION WHEN SQLSTATE 'P2805' THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'Cross-company invitation must fail with P2805';
  END IF;

  PERFORM pg_catalog.set_config('request.jwt.claim.sub', '', true);
  PERFORM pg_catalog.set_config('request.jwt.claim.role', 'anon', true);
  v_denied := false;
  BEGIN
    PERFORM public.prepare_company_invitation(
      v_viewer_company, 'issue314-anonymous-create@example.invalid',
      'viewer'::public.company_role, v_hash
    );
  EXCEPTION WHEN SQLSTATE 'P2800' THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'Unauthenticated invitation must fail with P2800';
  END IF;

  RAISE NOTICE 'ISSUE314_AUTHORIZATION_NEGATIVE_TESTS_PASSED';
END
$issue314_authorization$;

ROLLBACK;
