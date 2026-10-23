
-- Issue #317 R4.4 financial hardening. Code review artifact only:
-- Do not apply to Development or Production without separate approval.
-- Preserve historical snapshots; new draft creation and finalization must
-- derive exact amounts from canonical server-side sources.
BEGIN;

-- Existing minor-unit Money values support up to four fraction digits.
-- Widen legacy numeric projections without changing or rounding stored values.
-- The original numeric(14,2) columns would otherwise round KWD/4dp input.
ALTER TABLE public.driver_financial_movements
  ALTER COLUMN amount TYPE numeric(18,4);
ALTER TABLE public.driver_settlement_items
  ALTER COLUMN amount TYPE numeric(18,4);
ALTER TABLE public.driver_settlements
  ALTER COLUMN opening_driver_balance TYPE numeric(18,4),
  ALTER COLUMN advances_total TYPE numeric(18,4),
  ALTER COLUMN driver_paid_trip_expenses_total TYPE numeric(18,4),
  ALTER COLUMN returned_cash_total TYPE numeric(18,4),
  ALTER COLUMN deductions_total TYPE numeric(18,4),
  ALTER COLUMN settlement_deductions_total TYPE numeric(18,4),
  ALTER COLUMN gross_salary TYPE numeric(18,4),
  ALTER COLUMN salary_deductions_total TYPE numeric(18,4),
  ALTER COLUMN balance_deduction_applied TYPE numeric(18,4),
  ALTER COLUMN net_salary_payable TYPE numeric(18,4),
  ALTER COLUMN closing_driver_balance TYPE numeric(18,4);

CREATE FUNCTION private.assert_driver_settlement_financial_integrity(
  p_company_id uuid,
  p_header jsonb,
  p_items jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $body$
DECLARE
  v_header public.driver_settlements%ROWTYPE;
  v_revision public.driver_compensation_revisions%ROWTYPE;
  v_company_code text;
  v_company_digits smallint;
  v_scale numeric;
  v_checkpoint record;
  v_cp_end date;
  v_cp_created timestamptz;
  v_open numeric := 0;
  v_movements_before numeric := 0;
  v_expenses_before numeric := 0;
  v_advances numeric := 0;
  v_charges numeric := 0;
  v_returns numeric := 0;
  v_expenses numeric := 0;
  v_before_recovery numeric;
BEGIN
  IF p_header IS NULL OR p_items IS NULL
     OR jsonb_typeof(p_header) <> 'object'
     OR jsonb_typeof(p_items) <> 'array' THEN
    RAISE EXCEPTION USING ERRCODE='P2814',
      MESSAGE='driver_settlement_draft_payload_invalid';
  END IF;

  SELECT * INTO v_header
  FROM pg_catalog.jsonb_populate_record(NULL::public.driver_settlements, p_header);

  IF v_header.driver_id IS NULL
     OR v_header.period_start IS NULL
     OR v_header.period_end IS NULL
     OR v_header.period_start > v_header.period_end
     OR v_header.compensation_revision_id IS NULL
     OR v_header.currency_code IS NULL
     OR v_header.currency_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2814',
      MESSAGE='driver_settlement_snapshot_required';
  END IF;

  -- FOR UPDATE conflicts with FK key-share locks taken by new movement
  -- inserts. Lock each driver's trips as well, to cover new ledger entries.
  PERFORM 1 FROM public.drivers AS d
  WHERE d.company_id=p_company_id AND d.id=v_header.driver_id
    AND (d.is_active OR v_header.status='finalized'::public.driver_settlement_status)
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2814',
      MESSAGE='driver_settlement_driver_invalid';
  END IF;

  PERFORM t.id FROM public.trips AS t
  WHERE t.company_id=p_company_id AND t.driver_id=v_header.driver_id
  ORDER BY t.id
  FOR UPDATE;

  SELECT c.base_currency_code, c.base_currency_fraction_digits
  INTO v_company_code, v_company_digits
  FROM public.companies AS c WHERE c.id=p_company_id
  FOR SHARE;
  IF v_company_code IS NULL OR v_company_digits IS NULL
     OR v_header.currency_code IS DISTINCT FROM v_company_code
     OR v_header.currency_fraction_digits IS DISTINCT FROM v_company_digits
     OR v_company_digits NOT BETWEEN 0 AND 4 THEN
    RAISE EXCEPTION USING ERRCODE='P2817',
      MESSAGE='driver_settlement_currency_invalid';
  END IF;

  v_scale := pg_catalog.power(10::numeric,v_company_digits);

  SELECT * INTO v_revision
  FROM public.driver_compensation_revisions AS r
  WHERE r.company_id=p_company_id
    AND r.driver_id=v_header.driver_id
    AND r.id=v_header.compensation_revision_id
    AND r.effective_from<=v_header.period_start
    AND (r.effective_to IS NULL OR r.effective_to>=v_header.period_end)
  FOR SHARE;

  IF NOT FOUND
     OR v_revision.currency_code IS DISTINCT FROM v_company_code
     OR v_revision.currency_fraction_digits IS DISTINCT FROM v_company_digits
     OR v_header.gross_salary_minor_units IS DISTINCT FROM v_revision.amount_minor_units
  THEN
    RAISE EXCEPTION USING ERRCODE='P2816',
      MESSAGE='driver_settlement_compensation_invalid';
  END IF;

  -- The existing numeric columns are historical compatibility projections.
  -- Every exact-money field must be present and agree with its minor units.
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.unnest(
      ARRAY[
        v_header.opening_driver_balance, v_header.advances_total,
        v_header.driver_paid_trip_expenses_total, v_header.returned_cash_total,
        v_header.deductions_total, v_header.settlement_deductions_total,
        v_header.gross_salary, v_header.salary_deductions_total,
        v_header.balance_deduction_applied, v_header.net_salary_payable,
        v_header.closing_driver_balance
      ]::numeric[],
      ARRAY[
        v_header.opening_driver_balance_minor_units, v_header.advances_total_minor_units,
        v_header.driver_paid_trip_expenses_total_minor_units, v_header.returned_cash_total_minor_units,
        v_header.deductions_total_minor_units, v_header.settlement_deductions_total_minor_units,
        v_header.gross_salary_minor_units, v_header.salary_deductions_total_minor_units,
        v_header.balance_deduction_applied_minor_units, v_header.net_salary_payable_minor_units,
        v_header.closing_driver_balance_minor_units
      ]::bigint[]
    ) AS money(decimal_amount,minor_units)
    WHERE decimal_amount IS NULL OR minor_units IS NULL
      OR decimal_amount * v_scale <> minor_units::numeric
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2817',
      MESSAGE='driver_settlement_exact_money_mismatch';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_catalog.jsonb_to_recordset(p_items) AS i(
      source_type public.driver_settlement_item_source_type,
      source_id uuid, source_date date,
      direction public.driver_settlement_item_direction,
      amount numeric, amount_minor_units bigint,
      currency_code text, currency_fraction_digits smallint,
      label_key text, metadata jsonb
    )
    WHERE i.amount IS NULL OR i.amount_minor_units IS NULL
      OR i.currency_code IS DISTINCT FROM v_company_code
      OR i.currency_fraction_digits IS DISTINCT FROM v_company_digits
      OR i.amount_minor_units < 0
      OR i.amount * v_scale <> i.amount_minor_units::numeric
      OR i.source_type IS NULL
      OR i.direction IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2817',
      MESSAGE='driver_settlement_item_exact_money_mismatch';
  END IF;

  -- Existing expense void operations lock ledger rows FOR UPDATE.
  -- A captured expense cannot become void during snapshot validation.
  PERFORM e.id
  FROM public.expense_ledger_entries e
  JOIN public.trips t ON t.company_id=e.company_id AND t.id=e.trip_id
  WHERE e.company_id=p_company_id AND t.driver_id=v_header.driver_id
    AND e.funding_source IN ('driver_advance','driver_cash')
    AND e.expense_date<=v_header.period_end
  ORDER BY e.id FOR SHARE OF e;

  SELECT * INTO v_checkpoint
  FROM public.get_driver_balance_checkpoint_v2(
    p_company_id,v_header.driver_id,v_header.period_start
  );
  IF FOUND THEN
    IF v_checkpoint.currency_code IS DISTINCT FROM v_company_code
       OR v_checkpoint.currency_fraction_digits IS DISTINCT FROM v_company_digits THEN
      RAISE EXCEPTION USING ERRCODE='P2815',
      MESSAGE='driver_settlement_checkpoint_currency_invalid';
    END IF;
    v_cp_end := v_checkpoint.period_end;
    v_cp_created := v_checkpoint.snapshot_created_at;
    v_open := v_checkpoint.closing_driver_balance_minor_units::numeric;
  END IF;

  -- Match the canonical loader's fail-closed source-money contract even
  -- for effective late-posted movements before the settlement period.
  IF EXISTS (
    SELECT 1 FROM public.driver_financial_movements m
    WHERE m.company_id=p_company_id AND m.driver_id=v_header.driver_id
      AND m.movement_date<v_header.period_start
      AND (v_cp_end IS NULL OR m.movement_date>v_cp_end OR m.created_at>v_cp_created)
      AND (m.amount_minor_units IS NULL
        OR m.currency_code IS DISTINCT FROM v_company_code
        OR m.currency_fraction_digits IS DISTINCT FROM v_company_digits
        OR m.amount * v_scale <> m.amount_minor_units::numeric)
  ) OR EXISTS (
    SELECT 1 FROM public.expense_ledger_entries e
    JOIN public.trips t ON t.company_id=e.company_id AND t.id=e.trip_id
    WHERE e.company_id=p_company_id AND t.driver_id=v_header.driver_id
      AND e.is_voided=false AND e.funding_source IN ('driver_advance','driver_cash')
      AND e.expense_date<v_header.period_start
      AND (v_cp_end IS NULL OR e.expense_date>v_cp_end OR e.created_at>v_cp_created)
      AND (e.currency_code IS DISTINCT FROM v_company_code
        OR e.currency_fraction_digits IS DISTINCT FROM v_company_digits)
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2817',
      MESSAGE='driver_settlement_source_currency_invalid';
  END IF;

  -- Select effective source rows after the checkpoint OR late-posted
  -- backdated rows after checkpoint creation, exactly as the canonical
  -- Driver Finance source selector does.
  SELECT COALESCE(SUM(CASE m.movement_type
      WHEN 'advance' THEN -m.amount_minor_units::numeric
      WHEN 'driver_charge' THEN -m.amount_minor_units::numeric
      WHEN 'cash_return' THEN m.amount_minor_units::numeric
      ELSE NULL END),0)
  INTO v_movements_before
  FROM public.driver_financial_movements m
  WHERE m.company_id=p_company_id AND m.driver_id=v_header.driver_id
    AND m.movement_date<v_header.period_start
    AND (v_cp_end IS NULL OR m.movement_date>v_cp_end
      OR m.created_at>v_cp_created);

  SELECT COALESCE(SUM(e.amount_minor_units::numeric),0)
  INTO v_expenses_before
  FROM public.expense_ledger_entries e
  JOIN public.trips t ON t.company_id=e.company_id AND t.id=e.trip_id
  WHERE e.company_id=p_company_id AND t.driver_id=v_header.driver_id
    AND e.is_voided=false
    AND e.funding_source IN ('driver_advance','driver_cash')
    AND e.expense_date<v_header.period_start
    AND (v_cp_end IS NULL OR e.expense_date>v_cp_end
      OR e.created_at>v_cp_created);

  v_open := v_open + v_movements_before + v_expenses_before;

  IF v_header.opening_driver_balance_minor_units::numeric IS DISTINCT FROM v_open THEN
    RAISE EXCEPTION USING ERRCODE='P2815',
      MESSAGE='driver_settlement_opening_balance_changed';
  END IF;

  -- Only exact, eligible, non-voided canonical rows belong to the period.
  IF EXISTS (
    SELECT 1 FROM public.driver_financial_movements m
    WHERE m.company_id=p_company_id AND m.driver_id=v_header.driver_id
      AND m.movement_date BETWEEN v_header.period_start AND v_header.period_end
      AND (m.amount_minor_units IS NULL OR m.currency_code IS DISTINCT FROM v_company_code
        OR m.currency_fraction_digits IS DISTINCT FROM v_company_digits
        OR m.amount * v_scale <> m.amount_minor_units::numeric)
  ) OR EXISTS (
    SELECT 1 FROM public.expense_ledger_entries e
    JOIN public.trips t ON t.company_id=e.company_id AND t.id=e.trip_id
    WHERE e.company_id=p_company_id AND t.driver_id=v_header.driver_id
      AND e.expense_date BETWEEN v_header.period_start AND v_header.period_end
      AND e.is_voided=false AND e.funding_source IN ('driver_advance','driver_cash')
      AND (e.currency_code IS DISTINCT FROM v_company_code
        OR e.currency_fraction_digits IS DISTINCT FROM v_company_digits)
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2817',
      MESSAGE='driver_settlement_source_currency_invalid';
  END IF;

  -- EXCEPT ALL validates set completeness, duplicates and every source's
  -- immutable financial semantics. Legacy expenses use origin_id as their
  -- stable visible source identifier, consistent with Flutter's mapper.
  IF EXISTS (
    WITH expected AS (
      SELECT 'driver_financial_movement'::text AS source_type,
             m.id AS source_id, m.movement_date AS source_date,
             CASE WHEN m.movement_type='cash_return'
                  THEN 'company_to_driver' ELSE 'driver_to_company' END::text AS direction,
             m.amount_minor_units AS amount_minor_units,
             m.currency_code, m.currency_fraction_digits,
             CASE m.movement_type
               WHEN 'advance' THEN 'driver_settlement_item_advance'
               WHEN 'driver_charge' THEN 'driver_settlement_item_driver_charge'
               ELSE 'driver_settlement_item_cash_return'
             END::text AS label_key,
             m.notes AS description_key,
             pg_catalog.jsonb_build_object('movement_type',m.movement_type,'trip_id',m.trip_id) AS metadata
      FROM public.driver_financial_movements m
      WHERE m.company_id=p_company_id AND m.driver_id=v_header.driver_id
        AND m.movement_date BETWEEN v_header.period_start AND v_header.period_end
      UNION ALL
      SELECT 'trip_expense'::text,
             CASE WHEN e.origin_kind='legacy_trip_expense' AND e.origin_id IS NOT NULL
                  THEN e.origin_id ELSE e.id END,
             e.expense_date,'company_to_driver'::text,
             e.amount_minor_units,e.currency_code,e.currency_fraction_digits,
             'driver_settlement_item_trip_expense'::text,e.description,
             pg_catalog.jsonb_build_object('paid_by',e.funding_source,'trip_id',e.trip_id)
      FROM public.expense_ledger_entries e
      JOIN public.trips t ON t.company_id=e.company_id AND t.id=e.trip_id
      WHERE e.company_id=p_company_id AND t.driver_id=v_header.driver_id
        AND e.is_voided=false AND e.funding_source IN ('driver_advance','driver_cash')
        AND e.expense_date BETWEEN v_header.period_start AND v_header.period_end
    ), supplied AS (
      SELECT i.source_type,i.source_id,i.source_date,i.direction,
             i.amount_minor_units,i.currency_code,i.currency_fraction_digits,
             i.label_key,i.description_key,i.metadata
      FROM pg_catalog.jsonb_to_recordset(p_items) AS i(
        source_type text,source_id uuid,source_date date,direction text,
        amount_minor_units bigint,currency_code text,currency_fraction_digits smallint,
        label_key text,description_key text,metadata jsonb
      )
      WHERE i.source_type <> 'manual_adjustment'
    ), missing AS (
      SELECT * FROM expected EXCEPT ALL SELECT * FROM supplied
    ), extra AS (
      SELECT * FROM supplied EXCEPT ALL SELECT * FROM expected
    )
    SELECT 1 FROM missing UNION ALL SELECT 1 FROM extra
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2815',
      MESSAGE='driver_settlement_source_snapshot_changed';
  END IF;

  -- The only independent manual item supported by the Domain is the
  -- period-end settlement deduction. It may not create extra credits.
  IF (
    SELECT COUNT(*) FROM pg_catalog.jsonb_to_recordset(p_items) AS i(source_type text)
    WHERE i.source_type='manual_adjustment'
  ) IS DISTINCT FROM CASE WHEN v_header.settlement_deductions_total_minor_units>0
    THEN 1::bigint ELSE 0::bigint END
  OR EXISTS (
    SELECT 1 FROM pg_catalog.jsonb_to_recordset(p_items) AS i(
      source_type text,source_id uuid,source_date date,direction text,
      amount_minor_units bigint,label_key text,metadata jsonb)
    WHERE i.source_type='manual_adjustment'
      AND (i.source_id IS NOT NULL
        OR i.source_date IS DISTINCT FROM v_header.period_end
        OR i.direction IS DISTINCT FROM 'driver_to_company'
        OR i.label_key IS DISTINCT FROM 'driver_settlement_item_deduction'
        OR i.amount_minor_units IS DISTINCT FROM v_header.settlement_deductions_total_minor_units
        OR i.metadata IS DISTINCT FROM '{"adjustment_kind":"settlement_deduction"}'::jsonb)
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2818',
      MESSAGE='driver_settlement_manual_adjustment_invalid';
  END IF;

  SELECT COALESCE(SUM(m.amount_minor_units::numeric) FILTER
          (WHERE m.movement_type='advance'),0),
         COALESCE(SUM(m.amount_minor_units::numeric) FILTER
          (WHERE m.movement_type='driver_charge'),0),
         COALESCE(SUM(m.amount_minor_units::numeric) FILTER
          (WHERE m.movement_type='cash_return'),0)
  INTO v_advances,v_charges,v_returns
  FROM public.driver_financial_movements m
  WHERE m.company_id=p_company_id AND m.driver_id=v_header.driver_id
    AND m.movement_date BETWEEN v_header.period_start AND v_header.period_end;

  SELECT COALESCE(SUM(e.amount_minor_units::numeric),0)
  INTO v_expenses
  FROM public.expense_ledger_entries e
  JOIN public.trips t ON t.company_id=e.company_id AND t.id=e.trip_id
  WHERE e.company_id=p_company_id AND t.driver_id=v_header.driver_id
    AND e.is_voided=false AND e.funding_source IN ('driver_advance','driver_cash')
    AND e.expense_date BETWEEN v_header.period_start AND v_header.period_end;

  v_before_recovery := v_open - v_advances - v_charges
     - v_header.settlement_deductions_total_minor_units::numeric
     + v_expenses + v_returns;

  IF v_header.advances_total_minor_units::numeric IS DISTINCT FROM v_advances
     OR v_header.deductions_total_minor_units::numeric IS DISTINCT FROM v_charges
     OR v_header.returned_cash_total_minor_units::numeric IS DISTINCT FROM v_returns
     OR v_header.driver_paid_trip_expenses_total_minor_units::numeric IS DISTINCT FROM v_expenses
     OR v_header.balance_deduction_applied_minor_units<0
     OR v_header.salary_deductions_total_minor_units<0
     OR v_header.settlement_deductions_total_minor_units<0
     OR v_header.balance_deduction_applied_minor_units::numeric
        > pg_catalog.greatest(0::numeric,-v_before_recovery)
     OR v_header.net_salary_payable_minor_units::numeric
        IS DISTINCT FROM
        (v_header.gross_salary_minor_units::numeric
          - v_header.balance_deduction_applied_minor_units::numeric
          - v_header.salary_deductions_total_minor_units::numeric)
     OR v_header.net_salary_payable_minor_units<0
     OR v_header.closing_driver_balance_minor_units::numeric IS DISTINCT FROM
       (v_before_recovery + v_header.balance_deduction_applied_minor_units::numeric)
  THEN
    RAISE EXCEPTION USING ERRCODE='P2818',
      MESSAGE='driver_settlement_financial_totals_mismatch';
  END IF;
END;
$body$;

REVOKE ALL ON FUNCTION private.assert_driver_settlement_financial_integrity(uuid,jsonb,jsonb)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.create_driver_settlement_draft_atomic(
  p_company_id uuid,
  p_header jsonb,
  p_items jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_id uuid;
  v_item jsonb;
  v_source_type public.driver_settlement_item_source_type;
  v_existing_header jsonb;
  v_submitted_header jsonb;
BEGIN
  IF auth.uid() IS NULL
     OR p_company_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner','admin','accountant']::public.company_role[]
     )
  THEN
    RAISE EXCEPTION USING ERRCODE = 'P2813',
      MESSAGE = 'driver_settlement_create_permission_denied';
  END IF;

  IF p_header IS NULL
     OR pg_catalog.jsonb_typeof(p_header) <> 'object'
     OR p_items IS NULL
     OR pg_catalog.jsonb_typeof(p_items) <> 'array'
     OR p_header ->> 'company_id' IS DISTINCT FROM p_company_id::text
     OR p_header ->> 'status' IS DISTINCT FROM 'draft'
     OR p_header - ARRAY[
       'company_id', 'status', 'driver_id', 'period_start',
       'period_end', 'compensation_revision_id', 'currency_code', 'currency_fraction_digits',
       'opening_driver_balance', 'opening_driver_balance_minor_units', 'advances_total', 'advances_total_minor_units',
       'driver_paid_trip_expenses_total', 'driver_paid_trip_expenses_total_minor_units', 'returned_cash_total', 'returned_cash_total_minor_units',
       'deductions_total', 'deductions_total_minor_units', 'settlement_deductions_total', 'settlement_deductions_total_minor_units',
       'gross_salary', 'gross_salary_minor_units', 'salary_deductions_total', 'salary_deductions_total_minor_units',
       'balance_deduction_applied', 'balance_deduction_applied_minor_units', 'net_salary_payable', 'net_salary_payable_minor_units',
       'closing_driver_balance', 'closing_driver_balance_minor_units', 'notes'
     ] <> '{}'::jsonb
  THEN
    RAISE EXCEPTION USING ERRCODE = 'P2814',
      MESSAGE = 'driver_settlement_draft_payload_invalid';
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_catalog.jsonb_array_elements(p_items) AS element
    WHERE pg_catalog.jsonb_typeof(element.value) <> 'object'
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2814',
      MESSAGE='driver_settlement_item_payload_invalid';
  END IF;

  -- Validate against canonical sources while locks are held, before writing
  -- the header or firing audit/realtime triggers.
  PERFORM private.assert_driver_settlement_financial_integrity(
    p_company_id, p_header, p_items
  );

  -- The active period is already unique. A repeated identical request may
  -- follow a lost network response: return the existing id, without writing
  -- new audit rows or a second realtime invalidation.
  SELECT s.id, pg_catalog.to_jsonb(s)
  INTO v_id, v_existing_header
  FROM public.driver_settlements s
  WHERE s.company_id=p_company_id
    AND s.driver_id=(p_header ->> 'driver_id')::uuid
    AND s.period_start=(p_header ->> 'period_start')::date
    AND s.period_end=(p_header ->> 'period_end')::date
    AND s.status<>'voided'::public.driver_settlement_status
  FOR SHARE;

  IF FOUND THEN
    SELECT pg_catalog.to_jsonb(input) INTO v_submitted_header
    FROM pg_catalog.jsonb_populate_record(
      NULL::public.driver_settlements, p_header
    ) AS input;
    IF v_existing_header - ARRAY[
         'id','status','finalized_at','finalized_by','voided_at','voided_by',
         'void_reason','created_by','updated_by','created_at','updated_at'
       ] = v_submitted_header - ARRAY[
         'id','status','finalized_at','finalized_by','voided_at','voided_by',
         'void_reason','created_by','updated_by','created_at','updated_at'
       ]
       AND NOT EXISTS (
         WITH stored AS (
           SELECT i.source_type::text AS source_type,i.source_id,
                  i.source_date,i.direction::text AS direction,
                  i.amount,i.amount_minor_units,i.currency_code,
                  i.currency_fraction_digits,i.label_key,i.description_key,i.metadata
           FROM public.driver_settlement_items i
           WHERE i.company_id=p_company_id AND i.settlement_id=v_id
         ), sent AS (
           SELECT i.source_type,i.source_id,i.source_date,i.direction,
                  i.amount,i.amount_minor_units,i.currency_code,
                  i.currency_fraction_digits,i.label_key,i.description_key,i.metadata
           FROM pg_catalog.jsonb_to_recordset(p_items) AS i(
             source_type text,source_id uuid,source_date date,direction text,
             amount numeric,amount_minor_units bigint,currency_code text,
             currency_fraction_digits smallint,label_key text,
             description_key text,metadata jsonb
           )
         ), removed AS (
           SELECT * FROM stored EXCEPT ALL SELECT * FROM sent
         ), inserted AS (
           SELECT * FROM sent EXCEPT ALL SELECT * FROM stored
         )
         SELECT 1 FROM removed UNION ALL SELECT 1 FROM inserted
       ) THEN
      RETURN v_id;
    END IF;
    RAISE EXCEPTION USING ERRCODE='P2819',
      MESSAGE='driver_settlement_period_conflict';
  END IF;

  -- Explicitly selected fields; clients cannot supply id, actor or status.
  INSERT INTO public.driver_settlements (
    company_id,
    driver_id,
    period_start,
    period_end,
    compensation_revision_id,
    currency_code,
    currency_fraction_digits,
    opening_driver_balance,
    opening_driver_balance_minor_units,
    advances_total,
    advances_total_minor_units,
    driver_paid_trip_expenses_total,
    driver_paid_trip_expenses_total_minor_units,
    returned_cash_total,
    returned_cash_total_minor_units,
    deductions_total,
    deductions_total_minor_units,
    settlement_deductions_total,
    settlement_deductions_total_minor_units,
    gross_salary,
    gross_salary_minor_units,
    salary_deductions_total,
    salary_deductions_total_minor_units,
    balance_deduction_applied,
    balance_deduction_applied_minor_units,
    net_salary_payable,
    net_salary_payable_minor_units,
    closing_driver_balance,
    closing_driver_balance_minor_units,
    notes
  )
  SELECT p_company_id,
         input.driver_id,
         input.period_start,
         input.period_end,
         input.compensation_revision_id,
         input.currency_code,
         input.currency_fraction_digits,
         input.opening_driver_balance,
         input.opening_driver_balance_minor_units,
         input.advances_total,
         input.advances_total_minor_units,
         input.driver_paid_trip_expenses_total,
         input.driver_paid_trip_expenses_total_minor_units,
         input.returned_cash_total,
         input.returned_cash_total_minor_units,
         input.deductions_total,
         input.deductions_total_minor_units,
         input.settlement_deductions_total,
         input.settlement_deductions_total_minor_units,
         input.gross_salary,
         input.gross_salary_minor_units,
         input.salary_deductions_total,
         input.salary_deductions_total_minor_units,
         input.balance_deduction_applied,
         input.balance_deduction_applied_minor_units,
         input.net_salary_payable,
         input.net_salary_payable_minor_units,
         input.closing_driver_balance,
         input.closing_driver_balance_minor_units,
         input.notes
  FROM pg_catalog.jsonb_populate_record(
    NULL::public.driver_settlements, p_header
  ) AS input
  RETURNING id INTO v_id;

  FOR v_item IN SELECT value FROM pg_catalog.jsonb_array_elements(p_items)
  LOOP
    IF pg_catalog.jsonb_typeof(v_item) <> 'object'
       OR v_item ->> 'company_id' IS DISTINCT FROM p_company_id::text
       OR v_item - ARRAY[
         'company_id', 'source_type', 'source_id', 'source_date',
         'direction', 'amount', 'amount_minor_units', 'currency_code',
         'currency_fraction_digits', 'label_key', 'description_key', 'metadata'
       ] <> '{}'::jsonb
    THEN
      RAISE EXCEPTION USING ERRCODE = 'P2814',
        MESSAGE = 'driver_settlement_item_payload_invalid';
    END IF;

    -- SECURITY DEFINER may bypass table RLS. Source provenance must still
    -- be checked against the same company and the selected driver.
    v_source_type := (v_item ->> 'source_type')
      ::public.driver_settlement_item_source_type;

    IF v_source_type = 'driver_financial_movement'
       AND NOT EXISTS (
         SELECT 1
         FROM public.driver_financial_movements AS movement
         WHERE movement.company_id = p_company_id
           AND movement.driver_id = (p_header ->> 'driver_id')::uuid
           AND movement.id = (v_item ->> 'source_id')::uuid
       )
    THEN
      RAISE EXCEPTION USING ERRCODE = 'P2814',
        MESSAGE = 'driver_settlement_movement_source_invalid';
    END IF;

    IF v_source_type = 'trip_expense'
       AND NOT EXISTS (
         SELECT 1
         FROM public.expense_ledger_entries AS expense
         JOIN public.trips AS trip
           ON trip.company_id = expense.company_id
          AND trip.id = expense.trip_id
         WHERE expense.company_id = p_company_id
           AND trip.driver_id = (p_header ->> 'driver_id')::uuid
           AND expense.is_voided = false
           AND expense.funding_source IN ('driver_advance', 'driver_cash')
           AND (
             expense.id = (v_item ->> 'source_id')::uuid
             OR (
               expense.origin_kind = 'legacy_trip_expense'
               AND expense.origin_id = (v_item ->> 'source_id')::uuid
             )
           )
       )
    THEN
      RAISE EXCEPTION USING ERRCODE = 'P2812',
        MESSAGE = 'driver_settlement_expense_source_invalid';
    END IF;

    -- The relation and company identifier are always server-owned.
    INSERT INTO public.driver_settlement_items (
      company_id, settlement_id, source_type, source_id, source_date,
      direction, amount, amount_minor_units, currency_code,
      currency_fraction_digits, label_key, description_key, metadata
    )
    SELECT
      p_company_id, v_id, input.source_type, input.source_id,
      input.source_date, input.direction, input.amount,
      input.amount_minor_units, input.currency_code,
      input.currency_fraction_digits, input.label_key,
      input.description_key, COALESCE(input.metadata, '{}'::jsonb)
    FROM pg_catalog.jsonb_populate_record(
      NULL::public.driver_settlement_items, v_item
    ) AS input;
  END LOOP;

  -- New snapshots with captured driver-paid expenses require provenance.
  IF EXISTS (
    SELECT 1 FROM public.driver_settlements s
    WHERE s.id = v_id AND s.company_id = p_company_id
      AND s.driver_paid_trip_expenses_total > 0
      AND NOT EXISTS (
        SELECT 1 FROM public.driver_settlement_items i
        WHERE i.company_id = s.company_id AND i.settlement_id = s.id
          AND i.source_type = 'trip_expense'
      )
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2812',
      MESSAGE = 'driver_settlement_expense_source_invalid';
  END IF;

  RETURN v_id;
EXCEPTION
  WHEN invalid_text_representation OR numeric_value_out_of_range THEN
    RAISE EXCEPTION USING ERRCODE='P2814',
      MESSAGE='driver_settlement_draft_payload_invalid';
END;
$function$;


-- Fail closed for stale drafts, including historical drafts that cannot be
-- verified using the exact-money contract. Existing finalized/voided rows
-- remain unchanged.
CREATE FUNCTION private.guard_driver_settlement_finalization_integrity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $body$
DECLARE
  v_items jsonb;
BEGIN
  IF OLD.status='draft'::public.driver_settlement_status
     AND NEW.status='finalized'::public.driver_settlement_status THEN
    SELECT COALESCE(pg_catalog.jsonb_agg(pg_catalog.to_jsonb(i)), '[]'::jsonb)
    INTO v_items FROM public.driver_settlement_items AS i
    WHERE i.company_id=NEW.company_id AND i.settlement_id=NEW.id;

    PERFORM private.assert_driver_settlement_financial_integrity(
      NEW.company_id, pg_catalog.to_jsonb(NEW), v_items
    );
  END IF;
  RETURN NEW;
END;
$body$;

REVOKE ALL ON FUNCTION private.guard_driver_settlement_finalization_integrity()
FROM PUBLIC, anon, authenticated;

CREATE TRIGGER driver_settlements_guard_financial_integrity
BEFORE UPDATE OF status ON public.driver_settlements
FOR EACH ROW
EXECUTE FUNCTION private.guard_driver_settlement_finalization_integrity();

COMMIT;
