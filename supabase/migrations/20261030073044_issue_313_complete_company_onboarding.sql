-- Issue #313: complete financial and invoice settings at first onboarding.
-- No silently invented currency, precision or invoice prefix.
-- Replace the former signature to make incomplete tenant creation unavailable.
-- Company, initial Owner, reference data and structured audits commit together.
BEGIN;

DROP FUNCTION IF EXISTS public.create_company_with_initial_owner(text, text, text, text, text, text, text);

CREATE FUNCTION public.create_company_with_initial_owner(
  p_name text,
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
  id uuid,
  name text,
  business_type text,
  phone text,
  email text,
  country text,
  city text,
  logo_url text,
  base_currency_code text,
  base_currency_fraction_digits smallint,
  business_timezone text,
  is_active boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_company public.companies%ROWTYPE;
  v_membership public.company_users%ROWTYPE;
  v_name text := NULLIF(pg_catalog.btrim(p_name), '');
  v_business_timezone text := NULLIF(pg_catalog.btrim(p_business_timezone), '');
  v_base_currency_code text := pg_catalog.upper(pg_catalog.btrim(p_base_currency_code));
  v_invoice_prefix text := pg_catalog.upper(pg_catalog.btrim(p_invoice_prefix));
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2830',
      MESSAGE = 'company_onboarding_auth_required';
  END IF;

  IF v_name IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2831',
      MESSAGE = 'company_name_required';
  END IF;

  IF v_business_timezone IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM pg_catalog.pg_timezone_names timezone_entry
       WHERE timezone_entry.name = v_business_timezone
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2832',
      MESSAGE = 'company_business_timezone_invalid';
  END IF;

  IF v_base_currency_code IS NULL
     OR v_base_currency_code !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2833',
      MESSAGE = 'company_base_currency_invalid';
  END IF;

  IF p_base_currency_fraction_digits IS NULL
     OR p_base_currency_fraction_digits NOT BETWEEN 0 AND 4 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2834',
      MESSAGE = 'company_base_currency_fraction_digits_invalid';
  END IF;

  IF v_invoice_prefix IS NULL
     OR v_invoice_prefix !~ '^[A-Z][A-Z0-9-]{0,15}$' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2835',
      MESSAGE = 'company_invoice_prefix_invalid';
  END IF;

  INSERT INTO public.companies (
    name,
    business_timezone,
    base_currency_code,
    base_currency_fraction_digits,
    business_type,
    phone,
    email,
    country,
    city,
    created_by,
    updated_by
  )
  VALUES (
    v_name,
    v_business_timezone,
    v_base_currency_code,
    p_base_currency_fraction_digits,
    NULLIF(pg_catalog.btrim(p_business_type), ''),
    NULLIF(pg_catalog.btrim(p_phone), ''),
    NULLIF(pg_catalog.btrim(p_email), ''),
    NULLIF(pg_catalog.btrim(p_country), ''),
    NULLIF(pg_catalog.btrim(p_city), ''),
    v_actor_user_id,
    v_actor_user_id
  )
  RETURNING * INTO v_company;

  INSERT INTO public.company_users (
    company_id,
    user_id,
    role,
    is_active,
    created_by,
    updated_by
  )
  VALUES (
    v_company.id,
    v_actor_user_id,
    'owner'::public.company_role,
    true,
    v_actor_user_id,
    v_actor_user_id
  )
  RETURNING * INTO v_membership;

  INSERT INTO public.company_invoice_settings (
    company_id,
    invoice_prefix,
    created_by,
    updated_by
  )
  VALUES (
    v_company.id,
    v_invoice_prefix,
    v_actor_user_id,
    v_actor_user_id
  );

  PERFORM private.write_audit_event(
    v_company.id,
    'companies',
    'company',
    v_company.id::text,
    v_company.name,
    'created',
    'company_created',
    NULL,
    pg_catalog.jsonb_strip_nulls(
      pg_catalog.jsonb_build_object(
        'name', v_company.name,
        'business_timezone', v_company.business_timezone,
        'base_currency_code', v_company.base_currency_code,
        'base_currency_fraction_digits', v_company.base_currency_fraction_digits,
        'business_type', v_company.business_type,
        'phone', v_company.phone,
        'email', v_company.email,
        'country', v_company.country,
        'city', v_company.city,
        'is_active', v_company.is_active
      )
    ),
    pg_catalog.jsonb_build_object('source', 'company_onboarding')
  );

  PERFORM private.write_audit_event(
    v_company.id,
    'company_users',
    'company_user',
    v_membership.id::text,
    v_actor_user_id::text,
    'created',
    'company_membership_created',
    NULL,
    pg_catalog.jsonb_build_object(
      'role', v_membership.role::text,
      'is_active', v_membership.is_active
    ),
    pg_catalog.jsonb_build_object(
      'user_id', v_actor_user_id,
      'source', 'company_onboarding'
    )
  );

  PERFORM private.write_audit_event(
    v_company.id,
    'invoices',
    'company_settings',
    v_company.id::text,
    v_invoice_prefix,
    'updated',
    'invoice_settings_updated',
    pg_catalog.jsonb_build_object('invoice_prefix', NULL),
    pg_catalog.jsonb_build_object('invoice_prefix', v_invoice_prefix),
    pg_catalog.jsonb_build_object('source', 'company_onboarding')
  );

  RETURN QUERY
  SELECT
    v_company.id,
    v_company.name,
    v_company.business_type,
    v_company.phone,
    v_company.email,
    v_company.country,
    v_company.city,
    v_company.logo_url,
    v_company.base_currency_code,
    v_company.base_currency_fraction_digits,
    v_company.business_timezone,
    v_company.is_active;
END;
$$;

REVOKE ALL ON FUNCTION public.create_company_with_initial_owner(text, text, text, smallint, text, text, text, text, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_company_with_initial_owner(text, text, text, smallint, text, text, text, text, text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_company_with_initial_owner(text, text, text, smallint, text, text, text, text, text, text) TO authenticated;

COMMENT ON FUNCTION public.create_company_with_initial_owner(text, text, text, smallint, text, text, text, text, text, text)
  IS 'Atomically creates a financially ready company, initial Owner, invoice settings and audit events.';

COMMIT;
