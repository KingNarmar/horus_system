-- H.O.R.U.S System — Issue #233 / PC-09
-- Align Driver Finance and Driver Settlements with canonical money semantics.
--
-- This migration is additive:
-- - preserves legacy numeric columns for backward-compatible historical reads;
-- - adds exact minor-unit/currency snapshots;
-- - backfills exact values only from the company's locked base currency;
-- - never infers compensation history from legacy settlement gross_salary;
-- - requires every NEW settlement to reference one PC-08 compensation revision
--   that fully covers the settlement period and matches the snapshotted salary.

BEGIN;

-- ---------------------------------------------------------------------------
-- Preflight: historical company currency must be configured and every legacy
-- numeric value must be exactly representable using the configured fraction
-- digits. Abort atomically instead of silently rounding history.
-- ---------------------------------------------------------------------------

DO $block$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.companies c
    WHERE (
      EXISTS (
        SELECT 1
        FROM public.driver_financial_movements m
        WHERE m.company_id = c.id
      )
      OR EXISTS (
        SELECT 1
        FROM public.driver_settlements s
        WHERE s.company_id = c.id
      )
      OR EXISTS (
        SELECT 1
        FROM public.driver_settlement_items i
        WHERE i.company_id = c.id
      )
    )
      AND (
        c.base_currency_code IS NULL
        OR c.base_currency_fraction_digits IS NULL
        OR c.base_currency_fraction_digits NOT BETWEEN 0 AND 4
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2331',
      MESSAGE = 'pc09_company_financial_configuration_required';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.driver_financial_movements m
    JOIN public.companies c ON c.id = m.company_id
    WHERE m.amount * pg_catalog.power(
            10::numeric,
            c.base_currency_fraction_digits
          )
          <> pg_catalog.trunc(
            m.amount * pg_catalog.power(
              10::numeric,
              c.base_currency_fraction_digits
            )
          )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2332',
      MESSAGE = 'pc09_driver_financial_movement_precision_mismatch';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.driver_settlement_items i
    JOIN public.companies c ON c.id = i.company_id
    WHERE i.amount * pg_catalog.power(
            10::numeric,
            c.base_currency_fraction_digits
          )
          <> pg_catalog.trunc(
            i.amount * pg_catalog.power(
              10::numeric,
              c.base_currency_fraction_digits
            )
          )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2333',
      MESSAGE = 'pc09_driver_settlement_item_precision_mismatch';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.driver_settlements s
    JOIN public.companies c ON c.id = s.company_id
    CROSS JOIN LATERAL (
      VALUES
        (s.opening_driver_balance),
        (s.advances_total),
        (s.driver_paid_trip_expenses_total),
        (s.returned_cash_total),
        (s.deductions_total),
        (s.settlement_deductions_total),
        (s.gross_salary),
        (s.salary_deductions_total),
        (s.balance_deduction_applied),
        (s.net_salary_payable),
        (s.closing_driver_balance)
    ) AS value(amount)
    WHERE value.amount * pg_catalog.power(
            10::numeric,
            c.base_currency_fraction_digits
          )
          <> pg_catalog.trunc(
            value.amount * pg_catalog.power(
              10::numeric,
              c.base_currency_fraction_digits
            )
          )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2334',
      MESSAGE = 'pc09_driver_settlement_precision_mismatch';
  END IF;
END;
$block$;

-- ---------------------------------------------------------------------------
-- Driver financial movements: exact amount snapshot.
-- ---------------------------------------------------------------------------

ALTER TABLE public.driver_financial_movements
  ADD COLUMN amount_minor_units bigint,
  ADD COLUMN currency_code text,
  ADD COLUMN currency_fraction_digits smallint;

UPDATE public.driver_financial_movements m
SET
  amount_minor_units = (
    m.amount * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  currency_code = c.base_currency_code,
  currency_fraction_digits = c.base_currency_fraction_digits
FROM public.companies c
WHERE c.id = m.company_id;

ALTER TABLE public.driver_financial_movements
  ALTER COLUMN amount_minor_units SET NOT NULL,
  ALTER COLUMN currency_code SET NOT NULL,
  ALTER COLUMN currency_fraction_digits SET NOT NULL,
  ADD CONSTRAINT driver_financial_movements_amount_minor_units_positive
    CHECK (amount_minor_units > 0),
  ADD CONSTRAINT driver_financial_movements_currency_code_check
    CHECK (currency_code ~ '^[A-Z]{3}$'),
  ADD CONSTRAINT driver_financial_movements_currency_fraction_digits_check
    CHECK (currency_fraction_digits BETWEEN 0 AND 4);

-- ---------------------------------------------------------------------------
-- Settlement headers: exact snapshots plus optional legacy compensation link.
-- All exact money columns are backfilled safely. compensation_revision_id is
-- intentionally NOT backfilled from gross_salary.
-- ---------------------------------------------------------------------------

ALTER TABLE public.driver_settlements
  ADD COLUMN compensation_revision_id uuid,
  ADD COLUMN currency_code text,
  ADD COLUMN currency_fraction_digits smallint,
  ADD COLUMN opening_driver_balance_minor_units bigint,
  ADD COLUMN advances_total_minor_units bigint,
  ADD COLUMN driver_paid_trip_expenses_total_minor_units bigint,
  ADD COLUMN returned_cash_total_minor_units bigint,
  ADD COLUMN deductions_total_minor_units bigint,
  ADD COLUMN settlement_deductions_total_minor_units bigint,
  ADD COLUMN gross_salary_minor_units bigint,
  ADD COLUMN salary_deductions_total_minor_units bigint,
  ADD COLUMN balance_deduction_applied_minor_units bigint,
  ADD COLUMN net_salary_payable_minor_units bigint,
  ADD COLUMN closing_driver_balance_minor_units bigint;

UPDATE public.driver_settlements s
SET
  currency_code = c.base_currency_code,
  currency_fraction_digits = c.base_currency_fraction_digits,
  opening_driver_balance_minor_units = (
    s.opening_driver_balance * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  advances_total_minor_units = (
    s.advances_total * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  driver_paid_trip_expenses_total_minor_units = (
    s.driver_paid_trip_expenses_total * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  returned_cash_total_minor_units = (
    s.returned_cash_total * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  deductions_total_minor_units = (
    s.deductions_total * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  settlement_deductions_total_minor_units = (
    s.settlement_deductions_total * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  gross_salary_minor_units = (
    s.gross_salary * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  salary_deductions_total_minor_units = (
    s.salary_deductions_total * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  balance_deduction_applied_minor_units = (
    s.balance_deduction_applied * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  net_salary_payable_minor_units = (
    s.net_salary_payable * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  closing_driver_balance_minor_units = (
    s.closing_driver_balance * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint
FROM public.companies c
WHERE c.id = s.company_id;

ALTER TABLE public.driver_settlements
  ALTER COLUMN currency_code SET NOT NULL,
  ALTER COLUMN currency_fraction_digits SET NOT NULL,
  ALTER COLUMN opening_driver_balance_minor_units SET NOT NULL,
  ALTER COLUMN advances_total_minor_units SET NOT NULL,
  ALTER COLUMN driver_paid_trip_expenses_total_minor_units SET NOT NULL,
  ALTER COLUMN returned_cash_total_minor_units SET NOT NULL,
  ALTER COLUMN deductions_total_minor_units SET NOT NULL,
  ALTER COLUMN settlement_deductions_total_minor_units SET NOT NULL,
  ALTER COLUMN gross_salary_minor_units SET NOT NULL,
  ALTER COLUMN salary_deductions_total_minor_units SET NOT NULL,
  ALTER COLUMN balance_deduction_applied_minor_units SET NOT NULL,
  ALTER COLUMN net_salary_payable_minor_units SET NOT NULL,
  ALTER COLUMN closing_driver_balance_minor_units SET NOT NULL,
  ADD CONSTRAINT driver_settlements_compensation_revision_company_fk
    FOREIGN KEY (company_id, compensation_revision_id)
    REFERENCES public.driver_compensation_revisions(company_id, id)
    ON DELETE RESTRICT,
  ADD CONSTRAINT driver_settlements_currency_code_check
    CHECK (currency_code ~ '^[A-Z]{3}$'),
  ADD CONSTRAINT driver_settlements_currency_fraction_digits_check
    CHECK (currency_fraction_digits BETWEEN 0 AND 4),
  ADD CONSTRAINT driver_settlements_exact_non_negative_totals_check
    CHECK (
      advances_total_minor_units >= 0
      AND driver_paid_trip_expenses_total_minor_units >= 0
      AND returned_cash_total_minor_units >= 0
      AND deductions_total_minor_units >= 0
      AND settlement_deductions_total_minor_units >= 0
      AND gross_salary_minor_units >= 0
      AND salary_deductions_total_minor_units >= 0
      AND balance_deduction_applied_minor_units >= 0
      AND net_salary_payable_minor_units >= 0
    );

CREATE INDEX driver_settlements_compensation_revision_idx
  ON public.driver_settlements(company_id, compensation_revision_id)
  WHERE compensation_revision_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Settlement items: exact snapshot. Existing rows retain their legacy amount
-- and gain an exact company-currency representation.
-- ---------------------------------------------------------------------------

ALTER TABLE public.driver_settlement_items
  ADD COLUMN amount_minor_units bigint,
  ADD COLUMN currency_code text,
  ADD COLUMN currency_fraction_digits smallint;

UPDATE public.driver_settlement_items i
SET
  amount_minor_units = (
    i.amount * pg_catalog.power(
      10::numeric,
      c.base_currency_fraction_digits
    )
  )::bigint,
  currency_code = c.base_currency_code,
  currency_fraction_digits = c.base_currency_fraction_digits
FROM public.companies c
WHERE c.id = i.company_id;

ALTER TABLE public.driver_settlement_items
  ALTER COLUMN amount_minor_units SET NOT NULL,
  ALTER COLUMN currency_code SET NOT NULL,
  ALTER COLUMN currency_fraction_digits SET NOT NULL,
  ADD CONSTRAINT driver_settlement_items_amount_minor_units_check
    CHECK (amount_minor_units >= 0),
  ADD CONSTRAINT driver_settlement_items_currency_code_check
    CHECK (currency_code ~ '^[A-Z]{3}$'),
  ADD CONSTRAINT driver_settlement_items_currency_fraction_digits_check
    CHECK (currency_fraction_digits BETWEEN 0 AND 4);

-- ---------------------------------------------------------------------------
-- Integrity helpers for NEW writes.
-- These preserve legacy rows but make DB integrity independent of UI/Cubit.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.pc09_numeric_matches_minor_units(
  p_amount numeric,
  p_minor_units bigint,
  p_fraction_digits smallint
)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog
AS $function$
  SELECT
    p_fraction_digits BETWEEN 0 AND 4
    AND p_amount * pg_catalog.power(10::numeric, p_fraction_digits)
      = p_minor_units::numeric;
$function$;

REVOKE ALL ON FUNCTION private.pc09_numeric_matches_minor_units(
  numeric,
  bigint,
  smallint
) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.pc09_numeric_matches_minor_units(
  numeric,
  bigint,
  smallint
) FROM anon;
REVOKE ALL ON FUNCTION private.pc09_numeric_matches_minor_units(
  numeric,
  bigint,
  smallint
) FROM authenticated;

CREATE OR REPLACE FUNCTION private.enforce_pc09_driver_financial_movement_money()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
BEGIN
  SELECT c.base_currency_code, c.base_currency_fraction_digits
  INTO v_currency_code, v_fraction_digits
  FROM public.companies c
  WHERE c.id = NEW.company_id;

  IF v_currency_code IS NULL OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2331',
      MESSAGE = 'pc09_company_financial_configuration_required';
  END IF;

  IF NEW.currency_code IS DISTINCT FROM v_currency_code
     OR NEW.currency_fraction_digits IS DISTINCT FROM v_fraction_digits THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2335',
      MESSAGE = 'pc09_driver_financial_movement_currency_mismatch';
  END IF;

  IF NOT private.pc09_numeric_matches_minor_units(
    NEW.amount,
    NEW.amount_minor_units,
    NEW.currency_fraction_digits
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2336',
      MESSAGE = 'pc09_driver_financial_movement_amount_mismatch';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_pc09_driver_financial_movement_money()
  FROM PUBLIC;
REVOKE ALL ON FUNCTION private.enforce_pc09_driver_financial_movement_money()
  FROM anon;
REVOKE ALL ON FUNCTION private.enforce_pc09_driver_financial_movement_money()
  FROM authenticated;

CREATE TRIGGER driver_financial_movements_pc09_money_guard
BEFORE INSERT OR UPDATE OF
  amount,
  amount_minor_units,
  currency_code,
  currency_fraction_digits,
  company_id
ON public.driver_financial_movements
FOR EACH ROW
EXECUTE FUNCTION private.enforce_pc09_driver_financial_movement_money();

CREATE OR REPLACE FUNCTION private.enforce_pc09_driver_settlement_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_company_currency_code text;
  v_company_fraction_digits smallint;
  v_revision public.driver_compensation_revisions%ROWTYPE;
BEGIN
  SELECT c.base_currency_code, c.base_currency_fraction_digits
  INTO v_company_currency_code, v_company_fraction_digits
  FROM public.companies c
  WHERE c.id = NEW.company_id;

  IF v_company_currency_code IS NULL OR v_company_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2331',
      MESSAGE = 'pc09_company_financial_configuration_required';
  END IF;

  IF NEW.compensation_revision_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2337',
      MESSAGE = 'pc09_compensation_revision_required';
  END IF;

  SELECT revision.*
  INTO v_revision
  FROM public.driver_compensation_revisions revision
  WHERE revision.company_id = NEW.company_id
    AND revision.id = NEW.compensation_revision_id;

  IF NOT FOUND
     OR v_revision.driver_id IS DISTINCT FROM NEW.driver_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2338',
      MESSAGE = 'pc09_compensation_revision_driver_mismatch';
  END IF;

  IF v_revision.effective_from > NEW.period_start
     OR (
       v_revision.effective_to IS NOT NULL
       AND v_revision.effective_to < NEW.period_end
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2339',
      MESSAGE = 'pc09_compensation_revision_period_mismatch';
  END IF;

  IF NEW.currency_code IS DISTINCT FROM v_company_currency_code
     OR NEW.currency_fraction_digits IS DISTINCT FROM v_company_fraction_digits
     OR NEW.currency_code IS DISTINCT FROM v_revision.currency_code
     OR NEW.currency_fraction_digits IS DISTINCT FROM v_revision.currency_fraction_digits THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2340',
      MESSAGE = 'pc09_settlement_currency_mismatch';
  END IF;

  IF NEW.gross_salary_minor_units IS DISTINCT FROM v_revision.amount_minor_units THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2341',
      MESSAGE = 'pc09_settlement_compensation_amount_mismatch';
  END IF;

  IF NOT private.pc09_numeric_matches_minor_units(
      NEW.opening_driver_balance,
      NEW.opening_driver_balance_minor_units,
      NEW.currency_fraction_digits
    )
    OR NOT private.pc09_numeric_matches_minor_units(
      NEW.advances_total,
      NEW.advances_total_minor_units,
      NEW.currency_fraction_digits
    )
    OR NOT private.pc09_numeric_matches_minor_units(
      NEW.driver_paid_trip_expenses_total,
      NEW.driver_paid_trip_expenses_total_minor_units,
      NEW.currency_fraction_digits
    )
    OR NOT private.pc09_numeric_matches_minor_units(
      NEW.returned_cash_total,
      NEW.returned_cash_total_minor_units,
      NEW.currency_fraction_digits
    )
    OR NOT private.pc09_numeric_matches_minor_units(
      NEW.deductions_total,
      NEW.deductions_total_minor_units,
      NEW.currency_fraction_digits
    )
    OR NOT private.pc09_numeric_matches_minor_units(
      NEW.settlement_deductions_total,
      NEW.settlement_deductions_total_minor_units,
      NEW.currency_fraction_digits
    )
    OR NOT private.pc09_numeric_matches_minor_units(
      NEW.gross_salary,
      NEW.gross_salary_minor_units,
      NEW.currency_fraction_digits
    )
    OR NOT private.pc09_numeric_matches_minor_units(
      NEW.salary_deductions_total,
      NEW.salary_deductions_total_minor_units,
      NEW.currency_fraction_digits
    )
    OR NOT private.pc09_numeric_matches_minor_units(
      NEW.balance_deduction_applied,
      NEW.balance_deduction_applied_minor_units,
      NEW.currency_fraction_digits
    )
    OR NOT private.pc09_numeric_matches_minor_units(
      NEW.net_salary_payable,
      NEW.net_salary_payable_minor_units,
      NEW.currency_fraction_digits
    )
    OR NOT private.pc09_numeric_matches_minor_units(
      NEW.closing_driver_balance,
      NEW.closing_driver_balance_minor_units,
      NEW.currency_fraction_digits
    ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2342',
      MESSAGE = 'pc09_settlement_money_snapshot_mismatch';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_pc09_driver_settlement_insert()
  FROM PUBLIC;
REVOKE ALL ON FUNCTION private.enforce_pc09_driver_settlement_insert()
  FROM anon;
REVOKE ALL ON FUNCTION private.enforce_pc09_driver_settlement_insert()
  FROM authenticated;

CREATE TRIGGER driver_settlements_pc09_insert_guard
BEFORE INSERT ON public.driver_settlements
FOR EACH ROW
EXECUTE FUNCTION private.enforce_pc09_driver_settlement_insert();

CREATE OR REPLACE FUNCTION private.enforce_pc09_driver_settlement_item_money()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
BEGIN
  SELECT s.currency_code, s.currency_fraction_digits
  INTO v_currency_code, v_fraction_digits
  FROM public.driver_settlements s
  WHERE s.company_id = NEW.company_id
    AND s.id = NEW.settlement_id;

  IF v_currency_code IS NULL OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2343',
      MESSAGE = 'pc09_settlement_item_parent_money_snapshot_required';
  END IF;

  IF NEW.currency_code IS DISTINCT FROM v_currency_code
     OR NEW.currency_fraction_digits IS DISTINCT FROM v_fraction_digits THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2344',
      MESSAGE = 'pc09_settlement_item_currency_mismatch';
  END IF;

  IF NOT private.pc09_numeric_matches_minor_units(
    NEW.amount,
    NEW.amount_minor_units,
    NEW.currency_fraction_digits
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2345',
      MESSAGE = 'pc09_settlement_item_amount_mismatch';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_pc09_driver_settlement_item_money()
  FROM PUBLIC;
REVOKE ALL ON FUNCTION private.enforce_pc09_driver_settlement_item_money()
  FROM anon;
REVOKE ALL ON FUNCTION private.enforce_pc09_driver_settlement_item_money()
  FROM authenticated;

CREATE TRIGGER driver_settlement_items_pc09_money_guard
BEFORE INSERT OR UPDATE OF
  amount,
  amount_minor_units,
  currency_code,
  currency_fraction_digits,
  company_id,
  settlement_id
ON public.driver_settlement_items
FOR EACH ROW
EXECUTE FUNCTION private.enforce_pc09_driver_settlement_item_money();

COMMIT;
