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

ROLLBACK;
