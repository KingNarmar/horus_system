-- H.O.R.U.S System — Issue #233 / PC-09
-- Align Driver Finance and Driver Settlements with canonical financial sources.
--
-- Additive migration only:
-- - legacy numeric columns stay readable during the transition;
-- - exact minor-unit and currency snapshots are added alongside them;
-- - existing rows are backfilled only when conversion is exact;
-- - historical settlements are NOT linked to compensation revisions retroactively;
-- - future PC-09 drafts may snapshot the resolved PC-08 compensation revision;
-- - a v2 checkpoint RPC exposes exact money without breaking the legacy RPC.

BEGIN;

ALTER TABLE public.driver_financial_movements
  ADD COLUMN IF NOT EXISTS amount_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS currency_code text NULL,
  ADD COLUMN IF NOT EXISTS currency_fraction_digits smallint NULL;

ALTER TABLE public.driver_settlements
  ADD COLUMN IF NOT EXISTS compensation_revision_id uuid NULL,
  ADD COLUMN IF NOT EXISTS currency_code text NULL,
  ADD COLUMN IF NOT EXISTS currency_fraction_digits smallint NULL,
  ADD COLUMN IF NOT EXISTS opening_driver_balance_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS advances_total_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS driver_paid_trip_expenses_total_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS returned_cash_total_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS deductions_total_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS settlement_deductions_total_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS gross_salary_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS salary_deductions_total_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS balance_deduction_applied_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS net_salary_payable_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS closing_driver_balance_minor_units bigint NULL;

ALTER TABLE public.driver_settlement_items
  ADD COLUMN IF NOT EXISTS amount_minor_units bigint NULL,
  ADD COLUMN IF NOT EXISTS currency_code text NULL,
  ADD COLUMN IF NOT EXISTS currency_fraction_digits smallint NULL;

DO $validation$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.driver_financial_movements AS row
    JOIN public.companies AS company ON company.id = row.company_id
    WHERE company.base_currency_code IS NULL
      OR company.base_currency_fraction_digits IS NULL
      OR company.base_currency_fraction_digits NOT BETWEEN 0 AND 4
  ) OR EXISTS (
    SELECT 1
    FROM public.driver_settlements AS row
    JOIN public.companies AS company ON company.id = row.company_id
    WHERE company.base_currency_code IS NULL
      OR company.base_currency_fraction_digits IS NULL
      OR company.base_currency_fraction_digits NOT BETWEEN 0 AND 4
  ) OR EXISTS (
    SELECT 1
    FROM public.driver_settlement_items AS row
    JOIN public.companies AS company ON company.id = row.company_id
    WHERE company.base_currency_code IS NULL
      OR company.base_currency_fraction_digits IS NULL
      OR company.base_currency_fraction_digits NOT BETWEEN 0 AND 4
  ) THEN
    RAISE EXCEPTION 'pc09_financial_configuration_required'
      USING ERRCODE = '23514';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.driver_financial_movements AS row
    JOIN public.companies AS company ON company.id = row.company_id
    WHERE row.amount
        * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
        <> pg_catalog.trunc(
          row.amount
            * pg_catalog.power(
              10::numeric,
              company.base_currency_fraction_digits
            )
        )
  ) OR EXISTS (
    SELECT 1
    FROM public.driver_settlement_items AS row
    JOIN public.companies AS company ON company.id = row.company_id
    WHERE row.amount
        * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
        <> pg_catalog.trunc(
          row.amount
            * pg_catalog.power(
              10::numeric,
              company.base_currency_fraction_digits
            )
        )
  ) OR EXISTS (
    SELECT 1
    FROM public.driver_settlements AS row
    JOIN public.companies AS company ON company.id = row.company_id
    WHERE EXISTS (
      SELECT 1
      FROM unnest(ARRAY[
        row.opening_driver_balance,
        row.advances_total,
        row.driver_paid_trip_expenses_total,
        row.returned_cash_total,
        row.deductions_total,
        row.settlement_deductions_total,
        row.gross_salary,
        row.salary_deductions_total,
        row.balance_deduction_applied,
        row.net_salary_payable,
        row.closing_driver_balance
      ]) AS amount(value)
      WHERE amount.value
          * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
          <> pg_catalog.trunc(
            amount.value
              * pg_catalog.power(
                10::numeric,
                company.base_currency_fraction_digits
              )
          )
    )
  ) THEN
    RAISE EXCEPTION 'pc09_legacy_money_precision_invalid'
      USING ERRCODE = '23514';
  END IF;
END;
$validation$;

UPDATE public.driver_financial_movements AS movement
SET
  amount_minor_units = (
    movement.amount
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  currency_code = company.base_currency_code,
  currency_fraction_digits = company.base_currency_fraction_digits
FROM public.companies AS company
WHERE company.id = movement.company_id
  AND movement.amount_minor_units IS NULL
  AND movement.currency_code IS NULL
  AND movement.currency_fraction_digits IS NULL;

UPDATE public.driver_settlements AS settlement
SET
  currency_code = company.base_currency_code,
  currency_fraction_digits = company.base_currency_fraction_digits,
  opening_driver_balance_minor_units = (
    settlement.opening_driver_balance
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  advances_total_minor_units = (
    settlement.advances_total
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  driver_paid_trip_expenses_total_minor_units = (
    settlement.driver_paid_trip_expenses_total
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  returned_cash_total_minor_units = (
    settlement.returned_cash_total
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  deductions_total_minor_units = (
    settlement.deductions_total
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  settlement_deductions_total_minor_units = (
    settlement.settlement_deductions_total
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  gross_salary_minor_units = (
    settlement.gross_salary
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  salary_deductions_total_minor_units = (
    settlement.salary_deductions_total
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  balance_deduction_applied_minor_units = (
    settlement.balance_deduction_applied
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  net_salary_payable_minor_units = (
    settlement.net_salary_payable
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  closing_driver_balance_minor_units = (
    settlement.closing_driver_balance
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint
FROM public.companies AS company
WHERE company.id = settlement.company_id
  AND settlement.currency_code IS NULL
  AND settlement.currency_fraction_digits IS NULL;

UPDATE public.driver_settlement_items AS item
SET
  amount_minor_units = (
    item.amount
      * pg_catalog.power(10::numeric, company.base_currency_fraction_digits)
  )::bigint,
  currency_code = company.base_currency_code,
  currency_fraction_digits = company.base_currency_fraction_digits
FROM public.companies AS company
WHERE company.id = item.company_id
  AND item.amount_minor_units IS NULL
  AND item.currency_code IS NULL
  AND item.currency_fraction_digits IS NULL;

ALTER TABLE public.driver_financial_movements
  DROP CONSTRAINT IF EXISTS driver_financial_movements_exact_money_check,
  ADD CONSTRAINT driver_financial_movements_exact_money_check
  CHECK (
    (
      amount_minor_units IS NULL
      AND currency_code IS NULL
      AND currency_fraction_digits IS NULL
    )
    OR (
      amount_minor_units IS NOT NULL
      AND amount_minor_units > 0
      AND currency_code IS NOT NULL
      AND currency_code ~ '^[A-Z]{3}$'
      AND currency_fraction_digits IS NOT NULL
      AND currency_fraction_digits BETWEEN 0 AND 4
    )
  );

ALTER TABLE public.driver_settlements
  DROP CONSTRAINT IF EXISTS driver_settlements_exact_money_snapshot_check,
  ADD CONSTRAINT driver_settlements_exact_money_snapshot_check
  CHECK (
    (
      currency_code IS NULL
      AND currency_fraction_digits IS NULL
      AND opening_driver_balance_minor_units IS NULL
      AND advances_total_minor_units IS NULL
      AND driver_paid_trip_expenses_total_minor_units IS NULL
      AND returned_cash_total_minor_units IS NULL
      AND deductions_total_minor_units IS NULL
      AND settlement_deductions_total_minor_units IS NULL
      AND gross_salary_minor_units IS NULL
      AND salary_deductions_total_minor_units IS NULL
      AND balance_deduction_applied_minor_units IS NULL
      AND net_salary_payable_minor_units IS NULL
      AND closing_driver_balance_minor_units IS NULL
    )
    OR (
      currency_code IS NOT NULL
      AND currency_code ~ '^[A-Z]{3}$'
      AND currency_fraction_digits IS NOT NULL
      AND currency_fraction_digits BETWEEN 0 AND 4
      AND opening_driver_balance_minor_units IS NOT NULL
      AND advances_total_minor_units IS NOT NULL
      AND advances_total_minor_units >= 0
      AND driver_paid_trip_expenses_total_minor_units IS NOT NULL
      AND driver_paid_trip_expenses_total_minor_units >= 0
      AND returned_cash_total_minor_units IS NOT NULL
      AND returned_cash_total_minor_units >= 0
      AND deductions_total_minor_units IS NOT NULL
      AND deductions_total_minor_units >= 0
      AND settlement_deductions_total_minor_units IS NOT NULL
      AND settlement_deductions_total_minor_units >= 0
      AND gross_salary_minor_units IS NOT NULL
      AND gross_salary_minor_units >= 0
      AND salary_deductions_total_minor_units IS NOT NULL
      AND salary_deductions_total_minor_units >= 0
      AND balance_deduction_applied_minor_units IS NOT NULL
      AND balance_deduction_applied_minor_units >= 0
      AND net_salary_payable_minor_units IS NOT NULL
      AND net_salary_payable_minor_units >= 0
      AND closing_driver_balance_minor_units IS NOT NULL
    )
  );

ALTER TABLE public.driver_settlement_items
  DROP CONSTRAINT IF EXISTS driver_settlement_items_exact_money_check,
  ADD CONSTRAINT driver_settlement_items_exact_money_check
  CHECK (
    (
      amount_minor_units IS NULL
      AND currency_code IS NULL
      AND currency_fraction_digits IS NULL
    )
    OR (
      amount_minor_units IS NOT NULL
      AND amount_minor_units >= 0
      AND currency_code IS NOT NULL
      AND currency_code ~ '^[A-Z]{3}$'
      AND currency_fraction_digits IS NOT NULL
      AND currency_fraction_digits BETWEEN 0 AND 4
    )
  );

ALTER TABLE public.driver_settlements
  DROP CONSTRAINT IF EXISTS driver_settlements_compensation_revision_company_fk,
  ADD CONSTRAINT driver_settlements_compensation_revision_company_fk
  FOREIGN KEY (company_id, compensation_revision_id)
  REFERENCES public.driver_compensation_revisions(company_id, id)
  ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS driver_settlements_compensation_revision_idx
  ON public.driver_settlements(company_id, compensation_revision_id)
  WHERE compensation_revision_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.get_driver_balance_checkpoint_v2(
  p_company_id uuid,
  p_driver_id uuid,
  p_before_exclusive date
)
RETURNS TABLE (
  settlement_id uuid,
  period_end date,
  snapshot_created_at timestamptz,
  closing_driver_balance_minor_units bigint,
  currency_code text,
  currency_fraction_digits smallint
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.'
      USING ERRCODE = '42501';
  END IF;

  IF p_company_id IS NULL THEN
    RAISE EXCEPTION 'Company id is required.'
      USING ERRCODE = '22004';
  END IF;

  IF p_driver_id IS NULL THEN
    RAISE EXCEPTION 'Driver id is required.'
      USING ERRCODE = '22004';
  END IF;

  IF NOT private.has_company_role(
    p_company_id,
    ARRAY[
      'owner'::public.company_role,
      'admin'::public.company_role,
      'operations'::public.company_role,
      'accountant'::public.company_role,
      'viewer'::public.company_role
    ]
  ) THEN
    RAISE EXCEPTION 'Driver balance access is not allowed.'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    settlement.id,
    settlement.period_end,
    settlement.created_at,
    settlement.closing_driver_balance_minor_units,
    settlement.currency_code,
    settlement.currency_fraction_digits
  FROM public.driver_settlements AS settlement
  WHERE settlement.company_id = p_company_id
    AND settlement.driver_id = p_driver_id
    AND settlement.status = 'finalized'::public.driver_settlement_status
    AND settlement.closing_driver_balance_minor_units IS NOT NULL
    AND settlement.currency_code IS NOT NULL
    AND settlement.currency_fraction_digits IS NOT NULL
    AND (
      p_before_exclusive IS NULL
      OR settlement.period_end < p_before_exclusive
    )
  ORDER BY
    settlement.period_end DESC,
    settlement.finalized_at DESC NULLS LAST,
    settlement.created_at DESC,
    settlement.id DESC
  LIMIT 1;
END;
$function$;

REVOKE ALL
ON FUNCTION public.get_driver_balance_checkpoint_v2(uuid, uuid, date)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.get_driver_balance_checkpoint_v2(uuid, uuid, date)
TO authenticated;

COMMENT ON FUNCTION public.get_driver_balance_checkpoint_v2(uuid, uuid, date) IS
  'Returns the latest finalized Driver settlement checkpoint using exact minor-unit and currency snapshot semantics for PC-09.';

COMMENT ON COLUMN public.driver_settlements.compensation_revision_id IS
  'Resolved PC-08 compensation revision snapshotted by future PC-09 settlement drafts. Historical legacy settlements remain null.';

COMMENT ON COLUMN public.driver_settlements.currency_code IS
  'Settlement money currency snapshot. Legacy numeric columns remain for compatibility during PC-09 migration.';

COMMENT ON COLUMN public.driver_settlements.currency_fraction_digits IS
  'Currency fraction-digit snapshot used by all settlement minor-unit columns.';

COMMIT;
