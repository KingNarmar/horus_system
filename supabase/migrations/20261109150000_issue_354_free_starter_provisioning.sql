-- Issue #354 — source-only candidate migration. Do not apply to Production.
-- Deploy only after scoped Development approval and signed-JWT verification.
-- Breaks the old onboarding RPC signature; client/API rollout must be coordinated.
BEGIN;

-- Explicit immutable policy versions, independent of any future billing SDK.
CREATE TABLE private.entitlement_policy_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES public.subscription_plans(id),
  version integer NOT NULL CHECK (version > 0),
  limits jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(limits) = 'object'),
  enabled_features jsonb NOT NULL
    CHECK (pg_catalog.jsonb_typeof(enabled_features) = 'array'),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT entitlement_policy_versions_plan_version_unique
    UNIQUE (plan_id, version)
);

ALTER TABLE private.entitlement_policy_versions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.entitlement_policy_versions
  FROM PUBLIC, anon, authenticated;

CREATE FUNCTION private.reject_entitlement_policy_changes()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
BEGIN
  RAISE EXCEPTION USING
    ERRCODE = 'P2852',
    MESSAGE = 'entitlement_policy_version_is_immutable';
END;
$$;

CREATE TRIGGER entitlement_policy_versions_immutable
BEFORE UPDATE OR DELETE ON private.entitlement_policy_versions
FOR EACH ROW EXECUTE FUNCTION private.reject_entitlement_policy_changes();

-- Retain original legacy plan definitions; seed a distinct V1 business plan.
INSERT INTO public.subscription_plans (
  code, name, monthly_price, max_users, max_vehicles, max_trips_per_month,
  has_driver_app, has_advanced_reports, has_document_upload,
  has_maintenance, has_whatsapp_notifications, is_active
)
VALUES (
  'free_starter', 'Free Starter', 0, 3, 6, 0,
  false, false, true, false, false, true
)
ON CONFLICT (code) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.subscription_plans
    WHERE code = 'free_starter'
      AND monthly_price = 0
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'Invalid Free Starter plan seed';
  END IF;
END;
$$;

INSERT INTO private.entitlement_policy_versions (
  plan_id, version, limits, enabled_features
)
SELECT
  id, 1,
  pg_catalog.jsonb_build_object(
    'owner_created_companies', 1,
    'company_users', 3,
    'customers', 10,
    'drivers', 5,
    'combined_vehicles', 6,
    'routes', 10,
    'lifetime_trips', 30,
    'lifetime_invoices', 10,
    'business_documents', 50
  ),
  pg_catalog.jsonb_build_array(
    'company_branding',
    'invoice_pdf',
    'report_pdf',
    'report_xlsx',
    'document_upload'
  )
FROM public.subscription_plans
WHERE code = 'free_starter'
ON CONFLICT (plan_id, version) DO NOTHING;

-- One company-scoped authoritative grant remains in the established table.
ALTER TABLE public.company_subscriptions
  ADD COLUMN policy_version integer,
  ADD COLUMN revision integer NOT NULL DEFAULT 1 CHECK (revision > 0),
  ADD COLUMN effective_at timestamptz,
  ADD COLUMN expires_at timestamptz,
  ADD COLUMN grant_source text,
  ADD CONSTRAINT company_subscriptions_grant_source_check
    CHECK (grant_source IS NULL OR grant_source IN (
      'free_starter', 'legacy_backfill', 'operator', 'billing'
    )),
  ADD CONSTRAINT company_subscriptions_effective_interval_check
    CHECK (effective_at IS NULL OR expires_at IS NULL
      OR expires_at > effective_at),
  ADD CONSTRAINT company_subscriptions_policy_version_fk
    FOREIGN KEY (plan_id, policy_version)
    REFERENCES private.entitlement_policy_versions(plan_id, version);

-- Existing permissive writer policies no longer have a business purpose.
DROP POLICY IF EXISTS company_subscriptions_insert_owner_admin_or_platform_admin
  ON public.company_subscriptions;
DROP POLICY IF EXISTS company_subscriptions_update_owner_admin_or_platform_admin
  ON public.company_subscriptions;
DROP POLICY IF EXISTS company_subscriptions_delete_owner_admin_or_platform_admin
  ON public.company_subscriptions;
REVOKE INSERT, UPDATE, DELETE ON public.company_subscriptions
  FROM PUBLIC, anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.subscription_plans
  FROM PUBLIC, anon, authenticated;

-- Creator attribution must survive ownership transfers and tenant deletion.
-- UUIDs are stored in a private append-only audit ledger, not as cascading FKs.
CREATE TABLE private.company_creation_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id uuid NOT NULL,
  company_id uuid NOT NULL UNIQUE,
  request_id uuid,
  payload_fingerprint text,
  source text NOT NULL CHECK (source IN ('onboarding', 'legacy_backfill')),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT creation_request_fingerprint_pair CHECK (
    (request_id IS NULL AND payload_fingerprint IS NULL)
    OR (request_id IS NOT NULL AND payload_fingerprint IS NOT NULL)
  ),
  CONSTRAINT creator_request_id_unique UNIQUE (creator_user_id, request_id)
);
CREATE INDEX company_creation_ledger_creator_idx
  ON private.company_creation_ledger (creator_user_id);

ALTER TABLE private.company_creation_ledger ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.company_creation_ledger
  FROM PUBLIC, anon, authenticated;

CREATE FUNCTION private.reject_company_creation_ledger_changes()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
BEGIN
  RAISE EXCEPTION USING
    ERRCODE = 'P2839',
    MESSAGE = 'company_creation_history_is_immutable';
END;
$$;
CREATE TRIGGER company_creation_ledger_append_only
BEFORE UPDATE OR DELETE ON private.company_creation_ledger
FOR EACH ROW EXECUTE FUNCTION private.reject_company_creation_ledger_changes();

-- Attribution by original creator, not by current Owner; never restore slots.
INSERT INTO private.company_creation_ledger (
  creator_user_id, company_id, source
)
SELECT created_by, id, 'legacy_backfill'
FROM public.companies
WHERE created_by IS NOT NULL
ON CONFLICT (company_id) DO NOTHING;

-- Preserve any demonstrably valid pre-existing subscriptions without changes.
-- Grant Starter only to companies with no subscription row.
INSERT INTO public.company_subscriptions (
  company_id, plan_id, policy_version, status,
  effective_at, expires_at, grant_source, created_by, updated_by
)
SELECT c.id, sp.id, 1, 'active'::public.subscription_status,
       now(), NULL, 'legacy_backfill', c.created_by, c.created_by
FROM public.companies c
CROSS JOIN public.subscription_plans sp
WHERE sp.code = 'free_starter'
  AND NOT EXISTS (
    SELECT 1 FROM public.company_subscriptions prior
    WHERE prior.company_id = c.id
  )
ON CONFLICT (company_id) DO NOTHING;

-- System-authored, company-scoped legacy migration evidence.
-- Does not call the user-actor audit helper without a real user JWT.
INSERT INTO public.audit_logs (
  company_id, actor_user_id, actor_role, module, entity_type,
  entity_id, entity_display_name, action, description,
  old_values, new_values, metadata
)
SELECT cs.company_id, NULL, 'system', 'subscriptions',
       'company_entitlement', cs.id::text, c.name, 'created',
       'company_entitlement_backfilled',
       NULL,
       pg_catalog.jsonb_build_object(
         'plan_code', sp.code,
         'policy_version', cs.policy_version,
         'status', cs.status::text
       ),
       pg_catalog.jsonb_build_object(
         'audit_event', 'company_entitlement_backfilled',
         'source', 'issue_354_legacy_backfill'
       )
FROM public.company_subscriptions cs
JOIN public.companies c ON c.id = cs.company_id
JOIN public.subscription_plans sp ON sp.id = cs.plan_id
WHERE cs.grant_source = 'legacy_backfill'
  AND NOT EXISTS (
    SELECT 1 FROM public.audit_logs a
    WHERE a.company_id = cs.company_id
      AND a.entity_id = cs.id::text
      AND a.metadata ->> 'audit_event' = 'company_entitlement_backfilled'
  );

-- All authorized members read this one effective server projection.
CREATE FUNCTION public.get_company_effective_entitlement(p_company_id uuid)
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
  IF auth.uid() IS NULL
     OR p_company_id IS NULL
     OR NOT private.is_company_member(p_company_id) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2850',
      MESSAGE = 'entitlement_permission_denied';
  END IF;

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

REVOKE ALL ON FUNCTION public.get_company_effective_entitlement(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_company_effective_entitlement(uuid)
  TO authenticated;

-- Atomic onboarding API with an explicit, authenticated idempotency key.
-- A new signature is mandatory: old clients must upgrade before DB rollout.
DROP FUNCTION public.create_company_with_initial_owner(
  text, text, text, smallint, text, text, text, text, text, text
);

CREATE FUNCTION public.create_company_with_initial_owner(
  p_name text,
  p_request_id uuid,
  p_business_timezone text,
  p_base_currency_code text,
  p_base_currency_fraction_digits smallint,
  p_invoice_prefix text,
  p_business_type text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_country text DEFAULT NULL,
  p_city text DEFAULT NULL
)
RETURNS TABLE (
  id uuid, name text, business_type text, phone text, email text,
  country text, city text, logo_url text, base_currency_code text,
  base_currency_fraction_digits smallint, business_timezone text,
  is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_company public.companies%ROWTYPE;
  v_member public.company_users%ROWTYPE;
  v_prior private.company_creation_ledger%ROWTYPE;
  v_name text := NULLIF(pg_catalog.btrim(p_name), '');
  v_timezone text := NULLIF(pg_catalog.btrim(p_business_timezone), '');
  v_currency text := pg_catalog.upper(pg_catalog.btrim(p_base_currency_code));
  v_prefix text := pg_catalog.upper(pg_catalog.btrim(p_invoice_prefix));
  v_business_type text := NULLIF(pg_catalog.btrim(p_business_type), '');
  v_phone text := NULLIF(pg_catalog.btrim(p_phone), '');
  v_email text := NULLIF(pg_catalog.btrim(p_email), '');
  v_country text := NULLIF(pg_catalog.btrim(p_country), '');
  v_city text := NULLIF(pg_catalog.btrim(p_city), '');
  v_fingerprint text;
  v_plan uuid;
  v_limit integer;
  v_used bigint;
  v_subscription_id uuid;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2830',
      MESSAGE='company_onboarding_auth_required';
  END IF;
  IF p_request_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2837',
      MESSAGE='company_creation_request_id_required';
  END IF;
  IF v_name IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2831',
      MESSAGE='company_name_required';
  END IF;
  IF v_timezone IS NULL OR NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_timezone_names t WHERE t.name=v_timezone
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2832',
      MESSAGE='company_business_timezone_invalid';
  END IF;
  IF v_currency IS NULL OR v_currency !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION USING ERRCODE='P2833',
      MESSAGE='company_base_currency_invalid';
  END IF;
  IF p_base_currency_fraction_digits IS NULL
     OR p_base_currency_fraction_digits NOT BETWEEN 0 AND 4 THEN
    RAISE EXCEPTION USING ERRCODE='P2834',
      MESSAGE='company_base_currency_fraction_digits_invalid';
  END IF;
  IF v_prefix IS NULL OR v_prefix !~ '^[A-Z][A-Z0-9-]{0,15}$' THEN
    RAISE EXCEPTION USING ERRCODE='P2835',
      MESSAGE='company_invoice_prefix_invalid';
  END IF;

  -- Canonicalize payload so retry cannot change the meaning of the request.
  v_fingerprint := pg_catalog.encode(
    extensions.digest(
      pg_catalog.convert_to(pg_catalog.jsonb_build_object(
        'name', v_name,
        'timezone', v_timezone,
        'currency', v_currency,
        'digits', p_base_currency_fraction_digits,
        'prefix', v_prefix,
        'business_type', v_business_type,
        'phone', v_phone,
        'email', v_email,
        'country', v_country,
        'city', v_city
      )::text, 'UTF8'),
      'sha256'
    ),
    'hex'
  );

  -- Serialize all creation attempts for the same actor across devices.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_actor::text, 354)
  );

  SELECT * INTO v_prior
  FROM private.company_creation_ledger
  WHERE creator_user_id=v_actor AND request_id=p_request_id;

  IF FOUND THEN
    IF v_prior.payload_fingerprint IS DISTINCT FROM v_fingerprint THEN
      RAISE EXCEPTION USING ERRCODE='P2838',
        MESSAGE='company_creation_request_payload_conflict';
    END IF;
    IF NOT private.is_company_member(v_prior.company_id) THEN
      RAISE EXCEPTION USING ERRCODE='P2839',
        MESSAGE='company_creation_request_no_longer_accessible';
    END IF;
    SELECT * INTO v_company
    FROM public.companies WHERE companies.id=v_prior.company_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE='P2839',
        MESSAGE='company_creation_request_no_longer_accessible';
    END IF;
  ELSE
    SELECT sp.id, (pv.limits ->> 'owner_created_companies')::integer
      INTO v_plan, v_limit
    FROM public.subscription_plans sp
    JOIN private.entitlement_policy_versions pv
      ON pv.plan_id=sp.id AND pv.version=1
    WHERE sp.code='free_starter' AND sp.monthly_price=0
      AND sp.is_active;
    IF v_plan IS NULL OR v_limit IS NULL OR v_limit < 1 THEN
      RAISE EXCEPTION USING ERRCODE='P2852',
        MESSAGE='entitlement_integrity_error';
    END IF;

    SELECT count(*) INTO v_used
    FROM private.company_creation_ledger
    WHERE creator_user_id=v_actor;

    IF v_used >= v_limit THEN
      RAISE EXCEPTION USING ERRCODE='P2836',
        MESSAGE='company_creation_allowance_exhausted';
    END IF;

    INSERT INTO public.companies (
      name, business_timezone, base_currency_code,
      base_currency_fraction_digits, business_type, phone, email,
      country, city, created_by, updated_by
    )
    VALUES (
      v_name, v_timezone, v_currency, p_base_currency_fraction_digits,
      v_business_type, v_phone, v_email, v_country, v_city,
      v_actor, v_actor
    )
    RETURNING * INTO v_company;

    INSERT INTO public.company_users (
      company_id, user_id, role, is_active, created_by, updated_by
    )
    VALUES (
      v_company.id, v_actor, 'owner'::public.company_role,
      true, v_actor, v_actor
    )
    RETURNING * INTO v_member;

    INSERT INTO public.company_invoice_settings (
      company_id, invoice_prefix, created_by, updated_by
    )
    VALUES (v_company.id, v_prefix, v_actor, v_actor);

    INSERT INTO public.company_subscriptions (
      company_id, plan_id, policy_version, revision,
      status, effective_at, expires_at, grant_source,
      created_by, updated_by
    )
    VALUES (
      v_company.id, v_plan, 1, 1,
      'active'::public.subscription_status, now(), NULL,
      'free_starter', v_actor, v_actor
    )
    RETURNING company_subscriptions.id INTO v_subscription_id;

    INSERT INTO private.company_creation_ledger (
      creator_user_id, company_id, request_id,
      payload_fingerprint, source
    )
    VALUES (
      v_actor, v_company.id, p_request_id, v_fingerprint, 'onboarding'
    );

    PERFORM private.write_audit_event(
      v_company.id, 'companies', 'company', v_company.id::text,
      v_company.name, 'created', 'company_created', NULL,
      pg_catalog.jsonb_build_object(
        'name', v_company.name,
        'business_timezone', v_timezone,
        'base_currency_code', v_currency,
        'base_currency_fraction_digits', p_base_currency_fraction_digits,
        'business_type', v_business_type,
        'phone', v_phone, 'email', v_email, 'country', v_country,
        'city', v_city, 'is_active', true
      ),
      pg_catalog.jsonb_build_object('source','company_onboarding')
    );
    PERFORM private.write_audit_event(
      v_company.id, 'company_users', 'company_user',
      v_member.id::text, v_actor::text, 'created',
      'company_membership_created', NULL,
      pg_catalog.jsonb_build_object('role','owner','is_active',true),
      pg_catalog.jsonb_build_object(
        'user_id',v_actor,'source','company_onboarding'
      )
    );
    PERFORM private.write_audit_event(
      v_company.id, 'invoices', 'company_settings',
      v_company.id::text, v_prefix, 'updated',
      'invoice_settings_updated',
      pg_catalog.jsonb_build_object('invoice_prefix',NULL),
      pg_catalog.jsonb_build_object('invoice_prefix',v_prefix),
      pg_catalog.jsonb_build_object('source','company_onboarding')
    );
    PERFORM private.write_audit_event(
      v_company.id, 'subscriptions', 'company_entitlement',
      v_subscription_id::text, v_company.name, 'created',
      'company_entitlement_granted', NULL,
      pg_catalog.jsonb_build_object(
        'plan_code','free_starter','policy_version',1,
        'status','active','expires_at',NULL
      ),
      pg_catalog.jsonb_build_object(
        'source','company_onboarding','request_id',p_request_id
      )
    );
  END IF;

  RETURN QUERY SELECT
    v_company.id, v_company.name, v_company.business_type,
    v_company.phone, v_company.email, v_company.country,
    v_company.city, v_company.logo_url, v_company.base_currency_code,
    v_company.base_currency_fraction_digits,
    v_company.business_timezone, v_company.is_active;
END;
$$;

REVOKE ALL ON FUNCTION public.create_company_with_initial_owner(
  text, uuid, text, text, smallint, text,
  text, text, text, text, text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_company_with_initial_owner(
  text, uuid, text, text, smallint, text,
  text, text, text, text, text
) TO authenticated;

COMMIT;
