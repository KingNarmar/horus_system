-- Repair runtime-only PostgreSQL special-form function calls in the
-- R4.4 financial guard; no historical settlement records are modified.
-- Verified with a rollback-only atomic draft, idempotency and finalization test.
BEGIN;

CREATE OR REPLACE FUNCTION private.assert_driver_settlement_financial_integrity(
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
    FROM ROWS FROM (
      pg_catalog.unnest(ARRAY[
        v_header.opening_driver_balance, v_header.advances_total,
        v_header.driver_paid_trip_expenses_total, v_header.returned_cash_total,
        v_header.deductions_total, v_header.settlement_deductions_total,
        v_header.gross_salary, v_header.salary_deductions_total,
        v_header.balance_deduction_applied, v_header.net_salary_payable,
        v_header.closing_driver_balance
      ]::numeric[]),
      pg_catalog.unnest(ARRAY[
        v_header.opening_driver_balance_minor_units, v_header.advances_total_minor_units,
        v_header.driver_paid_trip_expenses_total_minor_units, v_header.returned_cash_total_minor_units,
        v_header.deductions_total_minor_units, v_header.settlement_deductions_total_minor_units,
        v_header.gross_salary_minor_units, v_header.salary_deductions_total_minor_units,
        v_header.balance_deduction_applied_minor_units, v_header.net_salary_payable_minor_units,
        v_header.closing_driver_balance_minor_units
      ]::bigint[])
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
  ) <> (v_header.settlement_deductions_total_minor_units>0)::integer
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
        > GREATEST(0::numeric,-v_before_recovery)
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

COMMIT;
