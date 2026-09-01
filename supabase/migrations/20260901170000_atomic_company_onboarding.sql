-- H.O.R.U.S System — Issue #204 Atomic company onboarding
-- Create a company and its initial Owner membership in one server-authoritative
-- transaction, then remove the temporary client-side INSERT seams.

BEGIN;

CREATE OR REPLACE FUNCTION public.create_company_with_initial_owner(
  p_name text,
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

  INSERT INTO public.companies (
    name,
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
  text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_company_with_initial_owner(
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
  text
) TO authenticated;

-- Once company creation is routed through the transactional command, the client
-- no longer needs direct INSERT access to either table.
REVOKE INSERT ON TABLE public.companies FROM authenticated;
REVOKE INSERT ON TABLE public.company_users FROM authenticated;

DROP POLICY IF EXISTS companies_insert_authenticated
  ON public.companies;
DROP POLICY IF EXISTS company_users_insert_initial_owner_or_platform_admin
  ON public.company_users;

COMMIT;
