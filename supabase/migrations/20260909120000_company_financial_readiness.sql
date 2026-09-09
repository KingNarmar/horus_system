-- H.O.R.U.S System — Issue #226 / PC-02
-- Canonical company financial configuration and historical currency safety.
--
-- Existing companies may initialize their first base currency even when they
-- already contain historical monetary data. Once a base currency exists,
-- changing the currency code or fraction digits is blocked whenever any
-- currency-bound company data exists.
--
-- Operational company use remains independent from financial readiness:
-- base currency stays nullable until explicitly configured.

BEGIN;

CREATE OR REPLACE FUNCTION private.company_has_currency_bound_financial_data(
  p_company_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  RETURN
    EXISTS (
      SELECT 1
      FROM public.company_expenses AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.trip_expenses AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_financial_movements AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_advances AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_deductions AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_settlements AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_settlement_items AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.invoices AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.invoice_lines AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.payments AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.trips AS row
      WHERE row.company_id = p_company_id
        AND (
          COALESCE(row.freight_price, 0::numeric) <> 0
          OR COALESCE(row.total_expenses, 0::numeric) <> 0
        )
    )
    OR EXISTS (
      SELECT 1
      FROM public.routes AS row
      WHERE row.company_id = p_company_id
        AND COALESCE(row.default_freight_price, 0::numeric) <> 0
    )
    OR EXISTS (
      SELECT 1
      FROM public.customers AS row
      WHERE row.company_id = p_company_id
        AND COALESCE(row.credit_limit, 0::numeric) <> 0
    );
END;
$function$;

REVOKE ALL ON FUNCTION private.company_has_currency_bound_financial_data(uuid)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION private.company_has_currency_bound_financial_data(uuid)
  FROM anon;
REVOKE ALL ON FUNCTION private.company_has_currency_bound_financial_data(uuid)
  FROM authenticated;

CREATE OR REPLACE FUNCTION private.enforce_company_base_currency_lock()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_had_configuration boolean :=
    OLD.base_currency_code IS NOT NULL
    AND OLD.base_currency_fraction_digits IS NOT NULL;
  v_currency_changed boolean :=
    OLD.base_currency_code IS DISTINCT FROM NEW.base_currency_code
    OR OLD.base_currency_fraction_digits
      IS DISTINCT FROM NEW.base_currency_fraction_digits;
BEGIN
  IF v_had_configuration
     AND v_currency_changed
     AND private.company_has_currency_bound_financial_data(OLD.id) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2606',
      MESSAGE = 'company_base_currency_locked';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_company_base_currency_lock()
  FROM PUBLIC;
REVOKE ALL ON FUNCTION private.enforce_company_base_currency_lock()
  FROM anon;
REVOKE ALL ON FUNCTION private.enforce_company_base_currency_lock()
  FROM authenticated;

DROP TRIGGER IF EXISTS companies_base_currency_lock
  ON public.companies;

CREATE TRIGGER companies_base_currency_lock
BEFORE UPDATE OF base_currency_code, base_currency_fraction_digits
ON public.companies
FOR EACH ROW
EXECUTE FUNCTION private.enforce_company_base_currency_lock();

CREATE OR REPLACE FUNCTION public.update_company_financial_configuration(
  p_company_id uuid,
  p_base_currency_code text,
  p_base_currency_fraction_digits smallint
)
RETURNS public.companies
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_currency_code text :=
    pg_catalog.upper(pg_catalog.btrim(p_base_currency_code));
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

  SELECT company_row.*
  INTO v_old_company
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2605',
      MESSAGE = 'company_not_found';
  END IF;

  IF v_old_company.base_currency_code IS NOT DISTINCT FROM v_currency_code
     AND v_old_company.base_currency_fraction_digits
       IS NOT DISTINCT FROM p_base_currency_fraction_digits THEN
    RETURN v_old_company;
  END IF;

  UPDATE public.companies
  SET
    base_currency_code = v_currency_code,
    base_currency_fraction_digits = p_base_currency_fraction_digits,
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
    'company_financial_configuration_updated',
    pg_catalog.jsonb_build_object(
      'base_currency_code', v_old_company.base_currency_code,
      'base_currency_fraction_digits',
        v_old_company.base_currency_fraction_digits
    ),
    pg_catalog.jsonb_build_object(
      'base_currency_code', v_new_company.base_currency_code,
      'base_currency_fraction_digits',
        v_new_company.base_currency_fraction_digits
    ),
    pg_catalog.jsonb_build_object(
      'source', 'company_financial_settings'
    )
  );

  RETURN v_new_company;
END;
$function$;

COMMENT ON FUNCTION public.update_company_financial_configuration(
  uuid,
  text,
  smallint
) IS
  'Configures a company base currency independently from timezone while protecting historical currency-bound data.';

REVOKE ALL ON FUNCTION public.update_company_financial_configuration(
  uuid,
  text,
  smallint
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_company_financial_configuration(
  uuid,
  text,
  smallint
) FROM anon;
GRANT EXECUTE ON FUNCTION public.update_company_financial_configuration(
  uuid,
  text,
  smallint
) TO authenticated;

COMMIT;
