-- H.O.R.U.S System — Issue #229 / PC-05 hardening
-- Assert that the only legacy Trip Expense allowed to remain historically
-- untyped is the explicitly reviewed source row migrated as canonical `other`.
--
-- This migration is intentionally append-only because DEV already applied the
-- original PC-05 migration before the row-specific hardening was introduced.

BEGIN;

DO $hardening$
DECLARE
  v_untyped_trip_expense_count bigint;
BEGIN
  SELECT pg_catalog.count(*)
  INTO v_untyped_trip_expense_count
  FROM public.trip_expenses AS expense_row
  WHERE expense_row.expense_type_id IS NULL;

  IF v_untyped_trip_expense_count > 0
     AND (
       v_untyped_trip_expense_count <> 1
       OR NOT EXISTS (
         SELECT 1
         FROM public.trip_expenses AS expense_row
         WHERE expense_row.id = 'b573d3cc-79a9-4fed-8c3d-7f34be873336'::uuid
           AND expense_row.company_id = '041a7fc8-3593-41f2-b00f-99643277b18f'::uuid
           AND expense_row.trip_id = '6103c7ec-fd43-4aad-8bd1-c070b71c9d46'::uuid
           AND expense_row.expense_type_id IS NULL
           AND pg_catalog.lower(pg_catalog.btrim(expense_row.expense_name)) = 'driver food'
           AND expense_row.amount = 1500.00::numeric
           AND expense_row.paid_by::text = 'company'
           AND expense_row.expense_date = DATE '2026-06-26'
           AND expense_row.notes IS NULL
       )
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_trip_expense_type_unmapped';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.trip_expenses AS expense_row
    JOIN public.expense_ledger_entries AS ledger_row
      ON ledger_row.company_id = expense_row.company_id
     AND ledger_row.origin_kind = 'legacy_trip_expense'
     AND ledger_row.origin_id = expense_row.id
    WHERE expense_row.expense_type_id IS NULL
      AND expense_row.id <> 'b573d3cc-79a9-4fed-8c3d-7f34be873336'::uuid
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'unexpected_untyped_trip_expense_projection';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.trip_expenses AS expense_row
    WHERE expense_row.id = 'b573d3cc-79a9-4fed-8c3d-7f34be873336'::uuid
      AND expense_row.company_id = '041a7fc8-3593-41f2-b00f-99643277b18f'::uuid
      AND expense_row.trip_id = '6103c7ec-fd43-4aad-8bd1-c070b71c9d46'::uuid
      AND expense_row.expense_type_id IS NULL
      AND pg_catalog.lower(pg_catalog.btrim(expense_row.expense_name)) = 'driver food'
      AND expense_row.amount = 1500.00::numeric
      AND expense_row.paid_by::text = 'company'
      AND expense_row.expense_date = DATE '2026-06-26'
      AND expense_row.notes IS NULL
      AND NOT EXISTS (
        SELECT 1
        FROM public.expense_ledger_entries AS ledger_row
        JOIN public.expense_types AS type_row
          ON type_row.company_id = ledger_row.company_id
         AND type_row.id = ledger_row.expense_type_id
        WHERE ledger_row.company_id = expense_row.company_id
          AND ledger_row.origin_kind = 'legacy_trip_expense'
          AND ledger_row.origin_id = expense_row.id
          AND ledger_row.trip_id = expense_row.trip_id
          AND ledger_row.amount_minor_units = 150000
          AND ledger_row.currency_code = 'AED'
          AND ledger_row.currency_fraction_digits = 2
          AND ledger_row.expense_date = DATE '2026-06-26'
          AND ledger_row.funding_source = 'company'
          AND ledger_row.is_voided = false
          AND type_row.code = 'other'
          AND type_row.ledger_eligible = true
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'reviewed_untyped_trip_expense_projection_mismatch';
  END IF;
END;
$hardening$;

COMMIT;
