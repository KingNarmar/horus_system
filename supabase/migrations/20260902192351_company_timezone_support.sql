-- H.O.R.U.S System — Issue #37 Company timezone support
-- Keep timezone independent from financial currency completeness, expose the
-- canonical PostgreSQL timezone catalog, provide a focused audited mutation,
-- and require a timezone during atomic company onboarding.

BEGIN;

-- Business timezone is an independent company setting. Currency code and
-- fraction digits remain an atomic pair, while a timezone can be configured
-- before financial regional settings are completed.
ALTER TABLE public.companies
  DROP CONSTRAINT IF EXISTS companies_regional_settings_complete_check;

ALTER TABLE public.companies
  DROP CONSTRAINT IF EXISTS companies_base_currency_complete_check;

ALTER TABLE public.companies
  ADD CONSTRAINT companies_base_currency_complete_check
  CHECK (
    (base_currency_code IS NULL AND base_currency_fraction_digits IS NULL)
    OR
    (base_currency_code IS NOT NULL AND base_currency_fraction_digits IS NOT NULL)
  );

-- Authenticated users need the canonical PostgreSQL IANA timezone catalog
-- during company onboarding, before a company membership exists.
CREATE OR REPLACE FUNCTION public.list_company_timezones()
RETURNS TABLE (name text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2610',
      MESSAGE = 'company_timezone_auth_required';
  END IF;

  RETURN QUERY
  SELECT timezone_entry.name::text
  FROM pg_catalog.pg_timezone_names timezone_entry
  ORDER BY timezone_entry.name;
END;
$$;

REVOKE ALL ON FUNCTION public.list_company_timezones() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_company_timezones() FROM anon;
GRANT EXECUTE ON FUNCTION public.list_company_timezones() TO authenticated;

-- Focused timezone mutation. UI visibility is only UX; owner/admin permission
-- is enforced here and the write remains server-authoritative and audited.
CREATE OR REPLACE FUNCTION public.update_company_business_timezone(
  p_company_id uuid,
  p_business_timezone text
)
RETURNS public.companies
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_business_timezone text := NULLIF(pg_catalog.btrim(p_business_timezone), '');
  v_old_company public.companies%ROWTYPE;
  v_new_company public.companies%ROWTYPE;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2601',
      MESSAGE = 'company_settings_permission_denied';
  END IF;

  IF v_business_timezone IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM pg_catalog.pg_timezone_names timezone_entry
       WHERE timezone_entry.name = v_business_timezone
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2604',
      MESSAGE = 'company_business_timezone_invalid';
  END IF;

  SELECT company_row.*
  INTO v_old_company
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2605',
      MESSAGE = 'company_not_found';
  END IF;

  IF v_old_company.business_timezone IS NOT DISTINCT FROM v_business_timezone THEN
    RETURN v_old_company;
  END IF;

  UPDATE public.companies
  SET
    business_timezone = v_business_timezone,
    updated_by = v_actor_user_id,
    updated_at = pg_catalog.now()
  WHERE id = p_company_id
  RETURNING * INTO v_new_company;

  PERFORM private.write_audit_event(
    p_company_id,
    'company_settings',
    'company',
    p_company_id::text,
    v_new_company.name,
    'updated',
    'company_business_timezone_updated',
    pg_catalog.jsonb_build_object(
      'business_timezone', v_old_company.business_timezone
    ),
    pg_catalog.jsonb_build_object(
      'business_timezone', v_new_company.business_timezone
    ),
    pg_catalog.jsonb_build_object(
      'source', 'company_timezone_settings'
    )
  );

  RETURN v_new_company;
END;
$$;

REVOKE ALL ON FUNCTION public.update_company_business_timezone(uuid, text)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_company_business_timezone(uuid, text)
  FROM anon;
GRANT EXECUTE ON FUNCTION public.update_company_business_timezone(uuid, text)
  TO authenticated;

-- Replace the old onboarding command so a new tenant cannot be created without
-- a canonical business timezone. The remaining onboarding behavior is preserved.
DROP FUNCTION IF EXISTS public.create_company_with_initial_owner(
  text,
  text,
  text,
  text,
  text,
  text
);

CREATE FUNCTION public.create_company_with_initial_owner(
  p_name text,
  p_business_timezone text,
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

  INSERT INTO public.companies (
    name,
    business_timezone,
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

REVOKE ALL ON FUNCTION public.create_company_with_initial_owner(
  text,
  text,
  text,
  text,
  text,
  text,
  text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_company_with_initial_owner(
  text,
  text,
  text,
  text,
  text,
  text,
  text
) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_company_with_initial_owner(
  text,
  text,
  text,
  text,
  text,
  text,
  text
) TO authenticated;

COMMIT;
