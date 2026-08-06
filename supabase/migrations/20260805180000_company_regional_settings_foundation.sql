-- Issue #26 prerequisite: reusable company regional settings foundation.
-- Values are intentionally optional until a financial feature is configured.
-- No country, currency, precision, or timezone is inferred or backfilled.

BEGIN;

ALTER TABLE public.companies
  ADD COLUMN IF NOT EXISTS base_currency_code text,
  ADD COLUMN IF NOT EXISTS base_currency_fraction_digits smallint,
  ADD COLUMN IF NOT EXISTS business_timezone text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint
    WHERE conname = 'companies_regional_settings_complete_check'
      AND conrelid = 'public.companies'::pg_catalog.regclass
  ) THEN
    ALTER TABLE public.companies
      ADD CONSTRAINT companies_regional_settings_complete_check
      CHECK (
        (
          base_currency_code IS NULL
          AND base_currency_fraction_digits IS NULL
          AND business_timezone IS NULL
        )
        OR
        (
          base_currency_code IS NOT NULL
          AND base_currency_fraction_digits IS NOT NULL
          AND business_timezone IS NOT NULL
        )
      );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint
    WHERE conname = 'companies_base_currency_code_check'
      AND conrelid = 'public.companies'::pg_catalog.regclass
  ) THEN
    ALTER TABLE public.companies
      ADD CONSTRAINT companies_base_currency_code_check
      CHECK (
        base_currency_code IS NULL
        OR base_currency_code ~ '^[A-Z]{3}$'
      );
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint
    WHERE conname = 'companies_base_currency_fraction_digits_check'
      AND conrelid = 'public.companies'::pg_catalog.regclass
  ) THEN
    ALTER TABLE public.companies
      ADD CONSTRAINT companies_base_currency_fraction_digits_check
      CHECK (
        base_currency_fraction_digits IS NULL
        OR base_currency_fraction_digits BETWEEN 0 AND 4
      );
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.update_company_regional_settings(
  p_company_id uuid,
  p_base_currency_code text,
  p_base_currency_fraction_digits smallint,
  p_business_timezone text
)
RETURNS public.companies
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role text;
  v_actor_display_name text;
  v_actor_email text;
  v_currency_code text := pg_catalog.upper(pg_catalog.btrim(p_base_currency_code));
  v_business_timezone text := pg_catalog.btrim(p_business_timezone);
  v_old_company public.companies%ROWTYPE;
  v_new_company public.companies%ROWTYPE;
  v_currency_changed boolean;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2601',
      MESSAGE = 'company_settings_permission_denied';
  END IF;

  IF NOT private.has_company_role(
    p_company_id,
    ARRAY['owner', 'admin']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2601',
      MESSAGE = 'company_settings_permission_denied';
  END IF;

  IF v_currency_code IS NULL
     OR v_currency_code !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2602',
      MESSAGE = 'company_base_currency_invalid';
  END IF;

  IF p_base_currency_fraction_digits IS NULL
     OR p_base_currency_fraction_digits NOT BETWEEN 0 AND 4 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2603',
      MESSAGE = 'company_base_currency_fraction_digits_invalid';
  END IF;

  IF v_business_timezone IS NULL
     OR v_business_timezone = ''
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

  v_currency_changed :=
    v_old_company.base_currency_code IS NOT NULL
    AND (
      v_old_company.base_currency_code IS DISTINCT FROM v_currency_code
      OR v_old_company.base_currency_fraction_digits
        IS DISTINCT FROM p_base_currency_fraction_digits
    );

  IF v_currency_changed
     AND EXISTS (
       SELECT 1
       FROM public.trips trip_row
       WHERE trip_row.company_id = p_company_id
         AND COALESCE(trip_row.freight_price, 0) <> 0
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2606',
      MESSAGE = 'company_base_currency_locked';
  END IF;

  SELECT
    company_user.role::text,
    COALESCE(
      NULLIF(pg_catalog.btrim(user_profile.full_name), ''),
      auth_user.email,
      v_actor_user_id::text
    ),
    auth_user.email
  INTO
    v_actor_role,
    v_actor_display_name,
    v_actor_email
  FROM public.company_users company_user
  LEFT JOIN public.user_profiles user_profile
    ON user_profile.id = company_user.user_id
  LEFT JOIN auth.users auth_user
    ON auth_user.id = company_user.user_id
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true;

  UPDATE public.companies
  SET
    base_currency_code = v_currency_code,
    base_currency_fraction_digits = p_base_currency_fraction_digits,
    business_timezone = v_business_timezone,
    updated_by = v_actor_user_id,
    updated_at = pg_catalog.now()
  WHERE id = p_company_id
  RETURNING * INTO v_new_company;

  INSERT INTO public.audit_logs (
    company_id,
    actor_user_id,
    actor_role,
    actor_display_name,
    actor_email,
    module,
    entity_type,
    entity_id,
    entity_display_name,
    action,
    description,
    old_values,
    new_values,
    metadata
  )
  VALUES (
    p_company_id,
    v_actor_user_id,
    v_actor_role,
    v_actor_display_name,
    v_actor_email,
    'company_settings',
    'company_settings',
    p_company_id::text,
    v_new_company.name,
    'updated',
    'company_regional_settings_updated',
    pg_catalog.jsonb_build_object(
      'base_currency_code', v_old_company.base_currency_code,
      'base_currency_fraction_digits',
        v_old_company.base_currency_fraction_digits,
      'business_timezone', v_old_company.business_timezone
    ),
    pg_catalog.jsonb_build_object(
      'base_currency_code', v_new_company.base_currency_code,
      'base_currency_fraction_digits',
        v_new_company.base_currency_fraction_digits,
      'business_timezone', v_new_company.business_timezone
    ),
    pg_catalog.jsonb_build_object(
      'audit_event', 'company_regional_settings_updated'
    )
  );

  RETURN v_new_company;
END;
$$;

COMMENT ON FUNCTION public.update_company_regional_settings(
  uuid,
  text,
  smallint,
  text
) IS
  'Updates complete company currency and business timezone settings with role checks and an atomic audit log.';

REVOKE ALL ON FUNCTION public.update_company_regional_settings(
  uuid,
  text,
  smallint,
  text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_company_regional_settings(
  uuid,
  text,
  smallint,
  text
) FROM anon;
GRANT EXECUTE ON FUNCTION public.update_company_regional_settings(
  uuid,
  text,
  smallint,
  text
) TO authenticated;

COMMIT;
