-- Issue #358: owner-created-company allowance is USER-scoped, not tenant-scoped.
-- Must follow the operator-security and canonical override migrations.
BEGIN;

-- Unlike tenant quotas, creation capacity belongs to the ORIGINAL creator.
-- It is an absolute extra slot allowance, not an unbounded additive counter.
CREATE TABLE private.platform_company_creation_capacity (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id),
  extra_slots integer NOT NULL CHECK (extra_slots BETWEEN 0 AND 1000),
  effective_at timestamptz NOT NULL,
  expires_at timestamptz,
  revoked_at timestamptz,
  revision integer NOT NULL CHECK (revision>0),
  updated_by uuid NOT NULL,
  updated_reason text NOT NULL CHECK(length(btrim(updated_reason)) BETWEEN 8 AND 500),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT platform_creation_capacity_dates CHECK (
    expires_at IS NULL OR expires_at>effective_at
  )
);
ALTER TABLE private.platform_company_creation_capacity ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.platform_company_creation_capacity
  FROM PUBLIC,anon,authenticated;


CREATE FUNCTION public.platform_set_company_creation_capacity(
  p_user_id uuid, p_extra_slots integer, p_effective_at timestamptz,
  p_expires_at timestamptz,p_expected_revision integer,
  p_reason text,p_request_id uuid
)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE
  v_actor uuid;
  v_reason text:=NULLIF(btrim(p_reason),'');
  v_effective timestamptz:=COALESCE(p_effective_at,now());
  v_hash text;
  v_prior private.platform_operator_audit%ROWTYPE;
  v_current private.platform_company_creation_capacity%ROWTYPE;
  v_revision integer;
  v_before jsonb;
  v_response jsonb;
BEGIN
  v_actor:=private.require_platform_operator('creation_grant_write',true);
  IF p_user_id IS NULL OR p_user_id=v_actor OR p_extra_slots IS NULL
    OR p_extra_slots NOT BETWEEN 0 AND 1000
    OR p_expected_revision IS NULL OR p_expected_revision<0
    OR p_request_id IS NULL OR v_reason IS NULL
    OR length(v_reason) NOT BETWEEN 8 AND 500
    OR (p_expires_at IS NOT NULL AND p_expires_at<=v_effective)
  THEN
    RAISE EXCEPTION USING ERRCODE='22023',
      MESSAGE='platform_creation_capacity_invalid';
  END IF;
  v_hash:=encode(extensions.digest(convert_to(jsonb_build_object(
    'op','capacity','user',p_user_id,'slots',p_extra_slots,
    'effective_at',p_effective_at,'expires_at',p_expires_at,
    'revision',p_expected_revision,'reason',v_reason
  )::text,'UTF8'),'sha256'),'hex');

  -- Match the advisory lock used by #354 onboarding BEFORE reading history.
  PERFORM pg_advisory_xact_lock(hashtextextended(p_user_id::text,354));
  IF NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id=p_user_id
    AND u.deleted_at IS NULL AND u.is_anonymous IS NOT TRUE) THEN
    RAISE EXCEPTION USING ERRCODE='P3587',
      MESSAGE='platform_capacity_target_not_found';
  END IF;
  SELECT * INTO v_prior FROM private.platform_operator_audit a
  WHERE a.actor_user_id=v_actor AND a.request_id=p_request_id;
  IF FOUND THEN
    IF v_prior.request_fingerprint IS DISTINCT FROM v_hash
      OR v_prior.action IS DISTINCT FROM 'creation_capacity_set' THEN
      RAISE EXCEPTION USING ERRCODE='P3582',MESSAGE='platform_request_id_conflict';
    END IF;
    RETURN v_prior.new_values;
  END IF;

  SELECT * INTO v_current FROM private.platform_company_creation_capacity c
  WHERE c.user_id=p_user_id FOR UPDATE;
  IF COALESCE(v_current.revision,0)<>p_expected_revision THEN
    RAISE EXCEPTION USING ERRCODE='P3583',MESSAGE='platform_revision_conflict';
  END IF;
  v_before:=CASE WHEN FOUND THEN
    jsonb_build_object('extra_slots',v_current.extra_slots,
      'revision',v_current.revision,'effective_at',v_current.effective_at,
      'expires_at',v_current.expires_at,'revoked_at',v_current.revoked_at)
    ELSE NULL END;
  v_revision:=p_expected_revision+1;
  INSERT INTO private.platform_company_creation_capacity(
    user_id,extra_slots,effective_at,expires_at,revoked_at,
    revision,updated_by,updated_reason
  ) VALUES (
    p_user_id,p_extra_slots,v_effective,p_expires_at,
    CASE WHEN p_extra_slots=0 THEN now() ELSE NULL END,
    v_revision,v_actor,v_reason
  )
  ON CONFLICT (user_id) DO UPDATE SET
    extra_slots=EXCLUDED.extra_slots,effective_at=EXCLUDED.effective_at,
    expires_at=EXCLUDED.expires_at,revoked_at=EXCLUDED.revoked_at,
    revision=EXCLUDED.revision,updated_by=EXCLUDED.updated_by,
    updated_reason=EXCLUDED.updated_reason,updated_at=now();
  v_response:=jsonb_build_object('user_id',p_user_id,'revision',v_revision,
    'extra_slots',p_extra_slots,'effective_at',v_effective,
    'expires_at',p_expires_at,'revoked',p_extra_slots=0);
  INSERT INTO private.platform_operator_audit(
    target_user_id,actor_user_id,actor_session_id,action,reason,
    request_id,request_fingerprint,old_values,new_values
  ) VALUES (
    p_user_id,v_actor,(auth.jwt()->>'session_id')::uuid,
    'creation_capacity_set',v_reason,p_request_id,v_hash,
    v_before,v_response
  );
  RETURN v_response;
END;
$$;
REVOKE ALL ON FUNCTION public.platform_set_company_creation_capacity(
  uuid,integer,timestamptz,timestamptz,integer,text,uuid)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.platform_set_company_creation_capacity(
  uuid,integer,timestamptz,timestamptz,integer,text,uuid)
  TO authenticated;


CREATE OR REPLACE FUNCTION public.create_company_with_initial_owner(p_name text, p_request_id uuid, p_business_timezone text, p_base_currency_code text, p_base_currency_fraction_digits smallint, p_invoice_prefix text, p_business_type text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_country text DEFAULT NULL::text, p_city text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, name text, business_type text, phone text, email text, country text, city text, logo_url text, base_currency_code text, base_currency_fraction_digits smallint, business_timezone text, is_active boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
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
  v_extra_slots integer;
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

    -- Operator-created allowance is per USER, never a company entitlement.
    -- The original immutable creation ledger still counts all successes.
    SELECT capacity.extra_slots INTO v_extra_slots
    FROM private.platform_company_creation_capacity capacity
    WHERE capacity.user_id=v_actor
      AND capacity.revoked_at IS NULL
      AND capacity.effective_at<=pg_catalog.now()
      AND (capacity.expires_at IS NULL
           OR capacity.expires_at>pg_catalog.now());
    v_limit := v_limit + COALESCE(v_extra_slots,0);
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
$function$;


COMMIT;
