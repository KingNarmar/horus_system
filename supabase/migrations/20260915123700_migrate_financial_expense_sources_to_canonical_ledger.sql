-- H.O.R.U.S System — Issue #229 / PC-05
-- Migrate legacy financial expense sources to the canonical ledger.
--
-- Transition contract:
-- - expense_ledger_entries is the authoritative financial expense source.
-- - legacy Trip/Company Expense surfaces remain temporarily for compatibility.
-- - supported legacy writes are projected one-way into the canonical ledger.
-- - no consumer may aggregate legacy + canonical expense rows together.
-- - Driver Finance movements and Salaries remain separate financial concepts.

BEGIN;

-- Keep the backfill and trigger cutover atomic with respect to expense writes.
LOCK TABLE
  public.trip_expenses,
  public.company_expenses,
  public.expense_ledger_entries,
  public.trips,
  public.expense_types,
  public.company_expense_categories,
  public.companies
IN SHARE ROW EXCLUSIVE MODE;

-- ---------------------------------------------------------------------------
-- Exact money helpers used only by trusted migration/sync code.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.legacy_expense_amount_to_minor_units(
  p_amount numeric,
  p_fraction_digits smallint
)
RETURNS bigint
LANGUAGE plpgsql
IMMUTABLE
SET search_path = pg_catalog
AS $function$
DECLARE
  v_factor numeric;
  v_scaled numeric;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_expense_amount_invalid';
  END IF;

  IF p_fraction_digits IS NULL OR p_fraction_digits < 0 OR p_fraction_digits > 4 THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_expense_currency_precision_invalid';
  END IF;

  v_factor := pg_catalog.power(10::numeric, p_fraction_digits::numeric);
  v_scaled := p_amount * v_factor;

  IF v_scaled IS DISTINCT FROM pg_catalog.trunc(v_scaled) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_expense_amount_precision_mismatch';
  END IF;

  IF v_scaled > 9223372036854775807::numeric THEN
    RAISE EXCEPTION USING
      ERRCODE = '22003',
      MESSAGE = 'legacy_expense_amount_overflow';
  END IF;

  RETURN v_scaled::bigint;
END;
$function$;

CREATE OR REPLACE FUNCTION private.expense_ledger_major_amount(
  p_amount_minor_units bigint,
  p_fraction_digits smallint
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = pg_catalog
AS $function$
  SELECT p_amount_minor_units::numeric
    / pg_catalog.power(10::numeric, p_fraction_digits::numeric);
$function$;

ALTER FUNCTION private.legacy_expense_amount_to_minor_units(numeric, smallint)
  OWNER TO postgres;
ALTER FUNCTION private.expense_ledger_major_amount(bigint, smallint)
  OWNER TO postgres;

REVOKE ALL ON FUNCTION private.legacy_expense_amount_to_minor_units(numeric, smallint)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.expense_ledger_major_amount(bigint, smallint)
  FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Fail closed before migrating any history.
-- ---------------------------------------------------------------------------

DO $preflight$
DECLARE
  v_untyped_trip_expense_count bigint;
BEGIN
  IF EXISTS (
    SELECT 1
    FROM (
      SELECT company_id FROM public.trip_expenses
      UNION
      SELECT company_id FROM public.company_expenses
    ) AS source_company
    JOIN public.companies AS company_row
      ON company_row.id = source_company.company_id
    WHERE company_row.base_currency_code IS NULL
       OR company_row.base_currency_fraction_digits IS NULL
       OR company_row.base_currency_fraction_digits < 0
       OR company_row.base_currency_fraction_digits > 4
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_expense_financial_configuration_required';
  END IF;

  -- Existing historical NULL Trip Expense types are allowed only for the one
  -- explicitly reviewed source row. This is intentionally row-specific and
  -- must never become a generic name-based NULL => Other fallback.
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
    LEFT JOIN public.expense_types AS type_row
      ON type_row.company_id = expense_row.company_id
     AND type_row.id = expense_row.expense_type_id
    WHERE expense_row.expense_type_id IS NOT NULL
      AND (
        type_row.id IS NULL
        OR type_row.ledger_eligible = false
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_trip_expense_type_not_ledger_eligible';
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
        FROM public.expense_types AS type_row
        WHERE type_row.company_id = expense_row.company_id
          AND type_row.code = 'other'
          AND type_row.ledger_eligible = true
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_trip_expense_other_type_unavailable';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.company_expenses AS expense_row
    JOIN public.company_expense_categories AS category_row
      ON category_row.company_id = expense_row.company_id
     AND category_row.id = expense_row.category_id
    LEFT JOIN public.expense_types AS type_row
      ON type_row.company_id = expense_row.company_id
     AND type_row.code = category_row.code
    WHERE category_row.code IS NULL
       OR (
         category_row.code <> 'salaries'
         AND (
           type_row.id IS NULL
           OR type_row.ledger_eligible = false
         )
       )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_company_expense_category_unmapped';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.company_expenses AS expense_row
    WHERE expense_row.trip_id IS NOT NULL
      AND (
        expense_row.driver_id IS NOT NULL
        OR expense_row.tractor_head_id IS NOT NULL
        OR expense_row.trailer_id IS NOT NULL
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_company_expense_attribution_conflict';
  END IF;

  -- Evaluate every amount through the exact conversion helper. Any precision
  -- loss or overflow aborts the migration before the cutover.
  PERFORM private.legacy_expense_amount_to_minor_units(
    expense_row.amount,
    company_row.base_currency_fraction_digits
  )
  FROM public.trip_expenses AS expense_row
  JOIN public.companies AS company_row
    ON company_row.id = expense_row.company_id;

  PERFORM private.legacy_expense_amount_to_minor_units(
    expense_row.amount,
    company_row.base_currency_fraction_digits
  )
  FROM public.company_expenses AS expense_row
  JOIN public.companies AS company_row
    ON company_row.id = expense_row.company_id;

  IF EXISTS (
    SELECT 1
    FROM public.expense_ledger_entries AS ledger_row
    WHERE ledger_row.origin_kind IN (
      'legacy_trip_expense',
      'legacy_company_expense'
    )
      AND ledger_row.origin_id IS NULL
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_expense_origin_id_required';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.expense_ledger_entries AS ledger_row
    WHERE ledger_row.origin_kind = 'legacy_trip_expense'
      AND NOT EXISTS (
        SELECT 1
        FROM public.trip_expenses AS expense_row
        WHERE expense_row.company_id = ledger_row.company_id
          AND expense_row.id = ledger_row.origin_id
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_trip_expense_origin_orphaned';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.expense_ledger_entries AS ledger_row
    WHERE ledger_row.origin_kind = 'legacy_company_expense'
      AND NOT EXISTS (
        SELECT 1
        FROM public.company_expenses AS expense_row
        WHERE expense_row.company_id = ledger_row.company_id
          AND expense_row.id = ledger_row.origin_id
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_company_expense_origin_orphaned';
  END IF;
END;
$preflight$;

-- ---------------------------------------------------------------------------
-- One-way compatibility projection: legacy Trip Expense -> canonical ledger.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.sync_legacy_trip_expense_to_ledger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
  v_expense_type_id uuid;
  v_amount_minor_units bigint;
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.company_id IS DISTINCT FROM NEW.company_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_trip_expense_company_immutable';
  END IF;

  IF NEW.expense_type_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_trip_expense_type_required';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits
  INTO
    v_currency_code,
    v_fraction_digits
  FROM public.companies AS company_row
  WHERE company_row.id = NEW.company_id;

  IF NOT FOUND
     OR v_currency_code IS NULL
     OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_expense_financial_configuration_required';
  END IF;

  SELECT type_row.id
  INTO v_expense_type_id
  FROM public.expense_types AS type_row
  WHERE type_row.company_id = NEW.company_id
    AND type_row.id = NEW.expense_type_id
    AND type_row.ledger_eligible = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_trip_expense_type_not_ledger_eligible';
  END IF;

  v_amount_minor_units := private.legacy_expense_amount_to_minor_units(
    NEW.amount,
    v_fraction_digits
  );

  INSERT INTO public.expense_ledger_entries (
    company_id,
    expense_type_id,
    amount_minor_units,
    currency_code,
    currency_fraction_digits,
    expense_date,
    funding_source,
    trip_id,
    driver_id,
    tractor_head_id,
    trailer_id,
    reference_number,
    notes,
    origin_kind,
    origin_id,
    is_voided,
    voided_at,
    voided_by,
    void_reason,
    created_by,
    updated_by,
    created_at,
    updated_at
  )
  VALUES (
    NEW.company_id,
    v_expense_type_id,
    v_amount_minor_units,
    pg_catalog.upper(pg_catalog.btrim(v_currency_code)),
    v_fraction_digits,
    NEW.expense_date,
    NEW.paid_by::text,
    NEW.trip_id,
    NULL,
    NULL,
    NULL,
    NULL,
    NEW.notes,
    'legacy_trip_expense',
    NEW.id,
    false,
    NULL,
    NULL,
    NULL,
    NEW.created_by,
    NEW.updated_by,
    NEW.created_at,
    NEW.updated_at
  )
  ON CONFLICT (company_id, origin_kind, origin_id)
    WHERE origin_id IS NOT NULL
  DO UPDATE SET
    expense_type_id = EXCLUDED.expense_type_id,
    amount_minor_units = EXCLUDED.amount_minor_units,
    currency_code = EXCLUDED.currency_code,
    currency_fraction_digits = EXCLUDED.currency_fraction_digits,
    expense_date = EXCLUDED.expense_date,
    funding_source = EXCLUDED.funding_source,
    trip_id = EXCLUDED.trip_id,
    driver_id = NULL,
    tractor_head_id = NULL,
    trailer_id = NULL,
    reference_number = NULL,
    notes = EXCLUDED.notes,
    is_voided = false,
    voided_at = NULL,
    voided_by = NULL,
    void_reason = NULL,
    updated_by = EXCLUDED.updated_by;

  RETURN NEW;
END;
$function$;

ALTER FUNCTION private.sync_legacy_trip_expense_to_ledger()
  OWNER TO postgres;
REVOKE ALL ON FUNCTION private.sync_legacy_trip_expense_to_ledger()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trip_expenses_sync_canonical_ledger
  ON public.trip_expenses;
CREATE TRIGGER trip_expenses_sync_canonical_ledger
AFTER INSERT OR UPDATE ON public.trip_expenses
FOR EACH ROW
EXECUTE FUNCTION private.sync_legacy_trip_expense_to_ledger();

-- ---------------------------------------------------------------------------
-- One-way compatibility projection: legacy Company Expense -> canonical ledger.
-- Salaries are intentionally excluded because payroll/compensation is not an
-- Expense Ledger concept.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.sync_legacy_company_expense_to_ledger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_category_code text;
  v_currency_code text;
  v_fraction_digits smallint;
  v_expense_type_id uuid;
  v_amount_minor_units bigint;
BEGIN
  IF TG_OP = 'UPDATE'
     AND OLD.company_id IS DISTINCT FROM NEW.company_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_company_expense_company_immutable';
  END IF;

  SELECT category_row.code
  INTO v_category_code
  FROM public.company_expense_categories AS category_row
  WHERE category_row.company_id = NEW.company_id
    AND category_row.id = NEW.category_id;

  IF NOT FOUND OR v_category_code IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_company_expense_category_unmapped';
  END IF;

  IF v_category_code = 'salaries' THEN
    DELETE FROM public.expense_ledger_entries AS ledger_row
    WHERE ledger_row.company_id = NEW.company_id
      AND ledger_row.origin_kind = 'legacy_company_expense'
      AND ledger_row.origin_id = NEW.id;

    RETURN NEW;
  END IF;

  IF NEW.trip_id IS NOT NULL
     AND (
       NEW.driver_id IS NOT NULL
       OR NEW.tractor_head_id IS NOT NULL
       OR NEW.trailer_id IS NOT NULL
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_company_expense_attribution_conflict';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits
  INTO
    v_currency_code,
    v_fraction_digits
  FROM public.companies AS company_row
  WHERE company_row.id = NEW.company_id;

  IF NOT FOUND
     OR v_currency_code IS NULL
     OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_expense_financial_configuration_required';
  END IF;

  SELECT type_row.id
  INTO v_expense_type_id
  FROM public.expense_types AS type_row
  WHERE type_row.company_id = NEW.company_id
    AND type_row.code = v_category_code
    AND type_row.ledger_eligible = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'legacy_company_expense_category_unmapped';
  END IF;

  v_amount_minor_units := private.legacy_expense_amount_to_minor_units(
    NEW.amount,
    v_fraction_digits
  );

  INSERT INTO public.expense_ledger_entries (
    company_id,
    expense_type_id,
    amount_minor_units,
    currency_code,
    currency_fraction_digits,
    expense_date,
    funding_source,
    trip_id,
    driver_id,
    tractor_head_id,
    trailer_id,
    reference_number,
    notes,
    origin_kind,
    origin_id,
    is_voided,
    voided_at,
    voided_by,
    void_reason,
    created_by,
    updated_by,
    created_at,
    updated_at
  )
  VALUES (
    NEW.company_id,
    v_expense_type_id,
    v_amount_minor_units,
    pg_catalog.upper(pg_catalog.btrim(v_currency_code)),
    v_fraction_digits,
    NEW.expense_date,
    'company',
    NEW.trip_id,
    CASE WHEN NEW.trip_id IS NULL THEN NEW.driver_id ELSE NULL END,
    CASE WHEN NEW.trip_id IS NULL THEN NEW.tractor_head_id ELSE NULL END,
    CASE WHEN NEW.trip_id IS NULL THEN NEW.trailer_id ELSE NULL END,
    NEW.reference_number,
    NEW.notes,
    'legacy_company_expense',
    NEW.id,
    NEW.is_voided,
    NEW.voided_at,
    NEW.voided_by,
    NEW.void_reason,
    NEW.created_by,
    NEW.updated_by,
    NEW.created_at,
    NEW.updated_at
  )
  ON CONFLICT (company_id, origin_kind, origin_id)
    WHERE origin_id IS NOT NULL
  DO UPDATE SET
    expense_type_id = EXCLUDED.expense_type_id,
    amount_minor_units = EXCLUDED.amount_minor_units,
    currency_code = EXCLUDED.currency_code,
    currency_fraction_digits = EXCLUDED.currency_fraction_digits,
    expense_date = EXCLUDED.expense_date,
    funding_source = 'company',
    trip_id = EXCLUDED.trip_id,
    driver_id = EXCLUDED.driver_id,
    tractor_head_id = EXCLUDED.tractor_head_id,
    trailer_id = EXCLUDED.trailer_id,
    reference_number = EXCLUDED.reference_number,
    notes = EXCLUDED.notes,
    is_voided = EXCLUDED.is_voided,
    voided_at = EXCLUDED.voided_at,
    voided_by = EXCLUDED.voided_by,
    void_reason = EXCLUDED.void_reason,
    updated_by = EXCLUDED.updated_by;

  RETURN NEW;
END;
$function$;

ALTER FUNCTION private.sync_legacy_company_expense_to_ledger()
  OWNER TO postgres;
REVOKE ALL ON FUNCTION private.sync_legacy_company_expense_to_ledger()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS company_expenses_sync_canonical_ledger
  ON public.company_expenses;
CREATE TRIGGER company_expenses_sync_canonical_ledger
AFTER INSERT OR UPDATE ON public.company_expenses
FOR EACH ROW
EXECUTE FUNCTION private.sync_legacy_company_expense_to_ledger();

-- ---------------------------------------------------------------------------
-- Historical backfill. The unique origin contract makes this deterministic
-- and idempotent. No historical audit event is fabricated for derived rows.
-- ---------------------------------------------------------------------------

WITH resolved_trip_expenses AS (
  SELECT
    expense_row.*,
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    COALESCE(expense_row.expense_type_id, other_type.id) AS canonical_type_id
  FROM public.trip_expenses AS expense_row
  JOIN public.companies AS company_row
    ON company_row.id = expense_row.company_id
  LEFT JOIN public.expense_types AS other_type
    ON expense_row.id = 'b573d3cc-79a9-4fed-8c3d-7f34be873336'::uuid
   AND expense_row.company_id = '041a7fc8-3593-41f2-b00f-99643277b18f'::uuid
   AND expense_row.trip_id = '6103c7ec-fd43-4aad-8bd1-c070b71c9d46'::uuid
   AND expense_row.expense_type_id IS NULL
   AND pg_catalog.lower(pg_catalog.btrim(expense_row.expense_name)) = 'driver food'
   AND expense_row.amount = 1500.00::numeric
   AND expense_row.paid_by::text = 'company'
   AND expense_row.expense_date = DATE '2026-06-26'
   AND expense_row.notes IS NULL
   AND other_type.company_id = expense_row.company_id
   AND other_type.code = 'other'
   AND other_type.ledger_eligible = true
)
INSERT INTO public.expense_ledger_entries (
  company_id,
  expense_type_id,
  amount_minor_units,
  currency_code,
  currency_fraction_digits,
  expense_date,
  funding_source,
  trip_id,
  driver_id,
  tractor_head_id,
  trailer_id,
  reference_number,
  notes,
  origin_kind,
  origin_id,
  is_voided,
  voided_at,
  voided_by,
  void_reason,
  created_by,
  updated_by,
  created_at,
  updated_at
)
SELECT
  source_row.company_id,
  source_row.canonical_type_id,
  private.legacy_expense_amount_to_minor_units(
    source_row.amount,
    source_row.base_currency_fraction_digits
  ),
  pg_catalog.upper(pg_catalog.btrim(source_row.base_currency_code)),
  source_row.base_currency_fraction_digits,
  source_row.expense_date,
  source_row.paid_by::text,
  source_row.trip_id,
  NULL,
  NULL,
  NULL,
  NULL,
  source_row.notes,
  'legacy_trip_expense',
  source_row.id,
  false,
  NULL,
  NULL,
  NULL,
  source_row.created_by,
  source_row.updated_by,
  source_row.created_at,
  source_row.updated_at
FROM resolved_trip_expenses AS source_row
ON CONFLICT (company_id, origin_kind, origin_id)
  WHERE origin_id IS NOT NULL
DO UPDATE SET
  expense_type_id = EXCLUDED.expense_type_id,
  amount_minor_units = EXCLUDED.amount_minor_units,
  currency_code = EXCLUDED.currency_code,
  currency_fraction_digits = EXCLUDED.currency_fraction_digits,
  expense_date = EXCLUDED.expense_date,
  funding_source = EXCLUDED.funding_source,
  trip_id = EXCLUDED.trip_id,
  driver_id = NULL,
  tractor_head_id = NULL,
  trailer_id = NULL,
  reference_number = NULL,
  notes = EXCLUDED.notes,
  is_voided = false,
  voided_at = NULL,
  voided_by = NULL,
  void_reason = NULL,
  updated_by = EXCLUDED.updated_by;

-- If a prior partial migration projected a Company Expense that is now known
-- to be Salary, remove only that derived projection. The legacy Salary source
-- remains intact and outside the canonical Expense Ledger scope.
DELETE FROM public.expense_ledger_entries AS ledger_row
USING public.company_expenses AS expense_row,
      public.company_expense_categories AS category_row
WHERE ledger_row.company_id = expense_row.company_id
  AND ledger_row.origin_kind = 'legacy_company_expense'
  AND ledger_row.origin_id = expense_row.id
  AND category_row.company_id = expense_row.company_id
  AND category_row.id = expense_row.category_id
  AND category_row.code = 'salaries';

INSERT INTO public.expense_ledger_entries (
  company_id,
  expense_type_id,
  amount_minor_units,
  currency_code,
  currency_fraction_digits,
  expense_date,
  funding_source,
  trip_id,
  driver_id,
  tractor_head_id,
  trailer_id,
  reference_number,
  notes,
  origin_kind,
  origin_id,
  is_voided,
  voided_at,
  voided_by,
  void_reason,
  created_by,
  updated_by,
  created_at,
  updated_at
)
SELECT
  expense_row.company_id,
  type_row.id,
  private.legacy_expense_amount_to_minor_units(
    expense_row.amount,
    company_row.base_currency_fraction_digits
  ),
  pg_catalog.upper(pg_catalog.btrim(company_row.base_currency_code)),
  company_row.base_currency_fraction_digits,
  expense_row.expense_date,
  'company',
  expense_row.trip_id,
  CASE WHEN expense_row.trip_id IS NULL THEN expense_row.driver_id ELSE NULL END,
  CASE WHEN expense_row.trip_id IS NULL THEN expense_row.tractor_head_id ELSE NULL END,
  CASE WHEN expense_row.trip_id IS NULL THEN expense_row.trailer_id ELSE NULL END,
  expense_row.reference_number,
  expense_row.notes,
  'legacy_company_expense',
  expense_row.id,
  expense_row.is_voided,
  expense_row.voided_at,
  expense_row.voided_by,
  expense_row.void_reason,
  expense_row.created_by,
  expense_row.updated_by,
  expense_row.created_at,
  expense_row.updated_at
FROM public.company_expenses AS expense_row
JOIN public.company_expense_categories AS category_row
  ON category_row.company_id = expense_row.company_id
 AND category_row.id = expense_row.category_id
JOIN public.expense_types AS type_row
  ON type_row.company_id = expense_row.company_id
 AND type_row.code = category_row.code
 AND type_row.ledger_eligible = true
JOIN public.companies AS company_row
  ON company_row.id = expense_row.company_id
WHERE category_row.code <> 'salaries'
ON CONFLICT (company_id, origin_kind, origin_id)
  WHERE origin_id IS NOT NULL
DO UPDATE SET
  expense_type_id = EXCLUDED.expense_type_id,
  amount_minor_units = EXCLUDED.amount_minor_units,
  currency_code = EXCLUDED.currency_code,
  currency_fraction_digits = EXCLUDED.currency_fraction_digits,
  expense_date = EXCLUDED.expense_date,
  funding_source = 'company',
  trip_id = EXCLUDED.trip_id,
  driver_id = EXCLUDED.driver_id,
  tractor_head_id = EXCLUDED.tractor_head_id,
  trailer_id = EXCLUDED.trailer_id,
  reference_number = EXCLUDED.reference_number,
  notes = EXCLUDED.notes,
  is_voided = EXCLUDED.is_voided,
  voided_at = EXCLUDED.voided_at,
  voided_by = EXCLUDED.voided_by,
  void_reason = EXCLUDED.void_reason,
  updated_by = EXCLUDED.updated_by;

-- ---------------------------------------------------------------------------
-- Trip total cutover: canonical ledger becomes the only source of truth for
-- trips.total_expenses. The legacy trip_expenses total trigger is retired, not
-- run in parallel, which prevents double counting during coexistence.
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trip_expenses_maintain_total_expenses
  ON public.trip_expenses;
DROP FUNCTION IF EXISTS private.maintain_trip_expense_total();

CREATE OR REPLACE FUNCTION private.maintain_trip_expense_total_from_ledger()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_old_company_id uuid;
  v_old_trip_id uuid;
  v_old_amount numeric := 0::numeric;
  v_new_company_id uuid;
  v_new_trip_id uuid;
  v_new_amount numeric := 0::numeric;
  v_delta numeric;
BEGIN
  IF TG_OP <> 'INSERT'
     AND OLD.trip_id IS NOT NULL
     AND OLD.is_voided = false THEN
    v_old_company_id := OLD.company_id;
    v_old_trip_id := OLD.trip_id;
    v_old_amount := private.expense_ledger_major_amount(
      OLD.amount_minor_units,
      OLD.currency_fraction_digits
    );
  END IF;

  IF TG_OP <> 'DELETE'
     AND NEW.trip_id IS NOT NULL
     AND NEW.is_voided = false THEN
    v_new_company_id := NEW.company_id;
    v_new_trip_id := NEW.trip_id;
    v_new_amount := private.expense_ledger_major_amount(
      NEW.amount_minor_units,
      NEW.currency_fraction_digits
    );
  END IF;

  IF v_old_trip_id IS NOT NULL
     AND v_new_trip_id IS NOT NULL
     AND v_old_company_id = v_new_company_id
     AND v_old_trip_id = v_new_trip_id THEN
    v_delta := v_new_amount - v_old_amount;

    IF v_delta <> 0::numeric THEN
      UPDATE public.trips AS trip_row
      SET total_expenses = trip_row.total_expenses + v_delta
      WHERE trip_row.company_id = v_new_company_id
        AND trip_row.id = v_new_trip_id;
    END IF;
  ELSIF v_old_trip_id IS NOT NULL AND v_new_trip_id IS NOT NULL THEN
    -- A moved ledger row touches two Trip parents. Lock/update in stable tenant
    -- and Trip order to avoid opposite-direction moves deadlocking each other.
    IF (v_old_company_id, v_old_trip_id) < (v_new_company_id, v_new_trip_id) THEN
      UPDATE public.trips AS trip_row
      SET total_expenses = trip_row.total_expenses - v_old_amount
      WHERE trip_row.company_id = v_old_company_id
        AND trip_row.id = v_old_trip_id;

      UPDATE public.trips AS trip_row
      SET total_expenses = trip_row.total_expenses + v_new_amount
      WHERE trip_row.company_id = v_new_company_id
        AND trip_row.id = v_new_trip_id;
    ELSE
      UPDATE public.trips AS trip_row
      SET total_expenses = trip_row.total_expenses + v_new_amount
      WHERE trip_row.company_id = v_new_company_id
        AND trip_row.id = v_new_trip_id;

      UPDATE public.trips AS trip_row
      SET total_expenses = trip_row.total_expenses - v_old_amount
      WHERE trip_row.company_id = v_old_company_id
        AND trip_row.id = v_old_trip_id;
    END IF;
  ELSIF v_old_trip_id IS NOT NULL THEN
    UPDATE public.trips AS trip_row
    SET total_expenses = trip_row.total_expenses - v_old_amount
    WHERE trip_row.company_id = v_old_company_id
      AND trip_row.id = v_old_trip_id;
  ELSIF v_new_trip_id IS NOT NULL THEN
    UPDATE public.trips AS trip_row
    SET total_expenses = trip_row.total_expenses + v_new_amount
    WHERE trip_row.company_id = v_new_company_id
      AND trip_row.id = v_new_trip_id;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$function$;

ALTER FUNCTION private.maintain_trip_expense_total_from_ledger()
  OWNER TO postgres;
REVOKE ALL ON FUNCTION private.maintain_trip_expense_total_from_ledger()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS expense_ledger_entries_maintain_trip_total
  ON public.expense_ledger_entries;
CREATE TRIGGER expense_ledger_entries_maintain_trip_total
AFTER INSERT OR UPDATE OR DELETE ON public.expense_ledger_entries
FOR EACH ROW
EXECUTE FUNCTION private.maintain_trip_expense_total_from_ledger();

-- Establish the canonical total invariant after the historical backfill.
WITH canonical_trip_totals AS (
  SELECT
    trip_row.company_id,
    trip_row.id AS trip_id,
    COALESCE(
      pg_catalog.sum(
        CASE
          WHEN ledger_row.is_voided = false THEN
            private.expense_ledger_major_amount(
              ledger_row.amount_minor_units,
              ledger_row.currency_fraction_digits
            )
          ELSE 0::numeric
        END
      ),
      0::numeric
    ) AS total_expenses
  FROM public.trips AS trip_row
  LEFT JOIN public.expense_ledger_entries AS ledger_row
    ON ledger_row.company_id = trip_row.company_id
   AND ledger_row.trip_id = trip_row.id
  GROUP BY trip_row.company_id, trip_row.id
)
UPDATE public.trips AS trip_row
SET total_expenses = total_row.total_expenses
FROM canonical_trip_totals AS total_row
WHERE trip_row.company_id = total_row.company_id
  AND trip_row.id = total_row.trip_id
  AND trip_row.total_expenses IS DISTINCT FROM total_row.total_expenses;

-- ---------------------------------------------------------------------------
-- Legacy-origin ledger rows are managed by their compatibility source during
-- coexistence. Prevent the public canonical void RPC from independently
-- changing them and creating source/ledger drift.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.void_expense_ledger_entry(
  p_company_id uuid,
  p_expense_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS public.expense_ledger_entries
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_entry public.expense_ledger_entries%ROWTYPE;
  v_expense_type_name text;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  SELECT entry_row.*
  INTO v_entry
  FROM public.expense_ledger_entries AS entry_row
  WHERE entry_row.company_id = p_company_id
    AND entry_row.id = p_expense_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2806', MESSAGE = 'expense_ledger_not_found';
  END IF;

  IF v_entry.origin_kind <> 'manual' THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  IF v_entry.trip_id IS NULL
     AND NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  IF v_entry.is_voided THEN
    RAISE EXCEPTION USING ERRCODE = 'P2807', MESSAGE = 'expense_ledger_already_voided';
  END IF;

  SELECT type_row.name
  INTO v_expense_type_name
  FROM public.expense_types AS type_row
  WHERE type_row.company_id = p_company_id
    AND type_row.id = v_entry.expense_type_id;

  UPDATE public.expense_ledger_entries
  SET
    is_voided = true,
    voided_at = pg_catalog.now(),
    voided_by = v_actor_user_id,
    void_reason = NULLIF(pg_catalog.btrim(p_reason), ''),
    updated_by = v_actor_user_id
  WHERE company_id = p_company_id
    AND id = p_expense_id
  RETURNING * INTO v_entry;

  PERFORM private.write_audit_event(
    p_company_id,
    'expenses',
    'expense_ledger_entry',
    v_entry.id::text,
    v_expense_type_name,
    'voided',
    'expense_ledger_entry_voided',
    pg_catalog.jsonb_build_object('is_voided', false),
    pg_catalog.jsonb_build_object(
      'is_voided', true,
      'voided_at', v_entry.voided_at,
      'void_reason', v_entry.void_reason
    ),
    pg_catalog.jsonb_build_object('source', 'expense_ledger')
  );

  RETURN v_entry;
END;
$function$;

REVOKE ALL ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text)
  FROM anon;
GRANT EXECUTE ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text)
  TO authenticated;

COMMIT;
