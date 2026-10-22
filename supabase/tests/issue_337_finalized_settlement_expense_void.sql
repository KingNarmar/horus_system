-- H.O.R.U.S System — Issue #337: transaction-scoped financial integrity.
-- DEVELOPMENT ONLY, after staging the Issue #337 migration.
-- Never execute against Production. No fixture or audit mutation persists.
-- JWT claims set here are test impersonation, NOT signed-JWT verification.
BEGIN;

DO $issue337$
DECLARE
  v_company uuid;
  v_owner uuid;
  v_driver uuid;
  v_trip uuid;
  v_type uuid;
  v_currency text;
  v_fraction smallint;
  v_period date;
  v_locked uuid;
  v_free uuid;
  v_legacy uuid;
  v_origin uuid := gen_random_uuid();
  v_prevoid uuid;
  v_settlement uuid;
  v_legacy_settlement uuid;
  v_prevoid_settlement uuid;
  v_denied boolean;
  v_is_voided boolean;
  v_audit_count bigint;
BEGIN
  SELECT t.company_id, owner.user_id, t.driver_id, t.id,
         et.id, company.base_currency_code,
         company.base_currency_fraction_digits
    INTO v_company, v_owner, v_driver, v_trip, v_type, v_currency,
         v_fraction
  FROM public.trips t
  JOIN public.companies company
    ON company.id = t.company_id AND company.is_active
  JOIN public.company_users owner
    ON owner.company_id = t.company_id
   AND owner.role = 'owner'::public.company_role
   AND owner.is_active
  JOIN public.expense_types et
    ON et.company_id = t.company_id
   AND et.is_active AND et.ledger_eligible
  WHERE t.driver_id IS NOT NULL
    AND company.base_currency_code IS NOT NULL
    AND company.base_currency_fraction_digits IS NOT NULL
  ORDER BY t.company_id, t.id, et.id
  LIMIT 1;

  IF v_company IS NULL THEN
    RAISE EXCEPTION 'Issue 337 needs a Development trip, driver, finance type and owner fixture';
  END IF;

  SELECT greatest(
    (CURRENT_DATE + INTERVAL '5 years')::date,
    coalesce(max(period_end) + 1, (CURRENT_DATE + INTERVAL '5 years')::date)
  )
  INTO v_period
  FROM public.driver_settlements
  WHERE company_id = v_company AND driver_id = v_driver;

  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_owner::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claim.role', 'authenticated', true);

  -- Source A will be captured by settlement A.
  INSERT INTO public.expense_ledger_entries(
    company_id, expense_type_id, amount_minor_units, currency_code,
    currency_fraction_digits, expense_date, funding_source,
    trip_id, description, origin_kind
  ) VALUES (
    v_company, v_type, 100, v_currency, v_fraction, v_period,
    'driver_cash', v_trip, 'issue337_locked_test', 'manual'
  ) RETURNING id INTO v_locked;

  INSERT INTO public.driver_settlements(
    company_id, driver_id, period_start, period_end,
    driver_paid_trip_expenses_total
  ) VALUES (
    v_company, v_driver, v_period, v_period, 1
  ) RETURNING id INTO v_settlement;

  INSERT INTO public.driver_settlement_items(
    company_id, settlement_id, source_type, source_id, source_date,
    direction, amount, label_key
  ) VALUES (
    v_company, v_settlement, 'trip_expense', v_locked, v_period,
    'company_to_driver', 1, 'driver_settlement_item_trip_expense'
  );

  UPDATE public.driver_settlements
  SET status = 'finalized'::public.driver_settlement_status
  WHERE company_id = v_company AND id = v_settlement;

  SELECT count(*) INTO v_audit_count
  FROM public.audit_logs
  WHERE company_id = v_company
    AND entity_id = v_locked::text
    AND action = 'voided';

  v_denied := false;
  BEGIN
    PERFORM public.void_expense_ledger_entry(v_company, v_locked, 'issue337');
  EXCEPTION WHEN SQLSTATE 'P2811' THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'Issue 337: finalized ledger source was not protected';
  END IF;

  SELECT is_voided INTO v_is_voided FROM public.expense_ledger_entries
  WHERE company_id = v_company AND id = v_locked;
  IF v_is_voided OR (SELECT count(*) FROM public.audit_logs
      WHERE company_id = v_company AND entity_id = v_locked::text
        AND action = 'voided') <> v_audit_count THEN
    RAISE EXCEPTION 'Issue 337: rejected void changed expense or wrote an audit event';
  END IF;

  -- An eligible unlinked source in the SAME period stays voidable.
  INSERT INTO public.expense_ledger_entries(
    company_id, expense_type_id, amount_minor_units, currency_code,
    currency_fraction_digits, expense_date, funding_source, trip_id,
    description, origin_kind
  ) VALUES (
    v_company, v_type, 100, v_currency, v_fraction, v_period,
    'driver_cash', v_trip, 'issue337_free_test', 'manual'
  ) RETURNING id INTO v_free;

  PERFORM public.void_expense_ledger_entry(v_company, v_free, 'issue337_free');
  SELECT is_voided INTO v_is_voided
  FROM public.expense_ledger_entries
  WHERE company_id = v_company AND id = v_free;
  IF NOT v_is_voided THEN
    RAISE EXCEPTION 'Issue 337: eligible unlinked void did not persist in transaction';
  END IF;

  SELECT count(*) INTO v_audit_count
  FROM public.audit_logs
  WHERE company_id = v_company
    AND entity_id = v_free::text
    AND action = 'voided';
  IF v_audit_count <> 1 THEN
    RAISE EXCEPTION 'Issue 337: successful void must emit one audit event';
  END IF;
  v_denied := false;
  BEGIN
    PERFORM public.void_expense_ledger_entry(v_company, v_free, 'repeat_issue337');
  EXCEPTION WHEN SQLSTATE 'P2807' THEN
    v_denied := true;
  END;
  IF NOT v_denied OR (SELECT count(*) FROM public.audit_logs
    WHERE company_id = v_company AND entity_id = v_free::text
      AND action = 'voided') <> v_audit_count THEN
    RAISE EXCEPTION 'Issue 337: repeat void changed an already-voided row or audit';
  END IF;

  -- A legacy settlement item references origin_id, NOT the canonical ledger id.
  INSERT INTO public.expense_ledger_entries(
    company_id, expense_type_id, amount_minor_units, currency_code,
    currency_fraction_digits, expense_date, funding_source, trip_id,
    description, origin_kind, origin_id
  ) VALUES (
    v_company, v_type, 100, v_currency, v_fraction, v_period + 1,
    'driver_cash', v_trip, 'issue337_legacy_test', 'legacy_trip_expense',
    v_origin
  ) RETURNING id INTO v_legacy;

  INSERT INTO public.driver_settlements(
    company_id, driver_id, period_start, period_end,
    driver_paid_trip_expenses_total
  ) VALUES (
    v_company, v_driver, v_period + 1, v_period + 1, 1
  ) RETURNING id INTO v_legacy_settlement;

  INSERT INTO public.driver_settlement_items(
    company_id, settlement_id, source_type, source_id, source_date,
    direction, amount, label_key
  ) VALUES (
    v_company, v_legacy_settlement, 'trip_expense', v_origin, v_period + 1,
    'company_to_driver', 1, 'driver_settlement_item_trip_expense'
  );

  UPDATE public.driver_settlements
  SET status = 'finalized'::public.driver_settlement_status
  WHERE company_id = v_company AND id = v_legacy_settlement;

  v_denied := false;
  BEGIN
    PERFORM public.void_expense_ledger_entry(v_company, v_legacy, 'issue337');
  EXCEPTION WHEN SQLSTATE 'P2811' THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'Issue 337: legacy origin_id captured source was not protected';
  END IF;

  -- Void first: stale draft must not subsequently become finalized.
  INSERT INTO public.expense_ledger_entries(
    company_id, expense_type_id, amount_minor_units, currency_code,
    currency_fraction_digits, expense_date, funding_source, trip_id,
    description, origin_kind
  ) VALUES (
    v_company, v_type, 100, v_currency, v_fraction, v_period + 2,
    'driver_cash', v_trip, 'issue337_prevoid_test', 'manual'
  ) RETURNING id INTO v_prevoid;

  INSERT INTO public.driver_settlements(
    company_id, driver_id, period_start, period_end,
    driver_paid_trip_expenses_total
  ) VALUES (
    v_company, v_driver, v_period + 2, v_period + 2, 1
  ) RETURNING id INTO v_prevoid_settlement;

  INSERT INTO public.driver_settlement_items(
    company_id, settlement_id, source_type, source_id, source_date,
    direction, amount, label_key
  ) VALUES (
    v_company, v_prevoid_settlement, 'trip_expense', v_prevoid,
    v_period + 2, 'company_to_driver', 1,
    'driver_settlement_item_trip_expense'
  );
  PERFORM public.void_expense_ledger_entry(v_company, v_prevoid, 'issue337_prevoid');

  v_denied := false;
  BEGIN
    UPDATE public.driver_settlements
    SET status = 'finalized'::public.driver_settlement_status
    WHERE company_id = v_company AND id = v_prevoid_settlement;
  EXCEPTION WHEN SQLSTATE 'P2812' THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'Issue 337: finalization accepted an already-voided source';
  END IF;

  IF (SELECT status FROM public.driver_settlements
      WHERE company_id = v_company AND id = v_prevoid_settlement)
       <> 'draft'::public.driver_settlement_status THEN
    RAISE EXCEPTION 'Issue 337: failed finalization mutated draft';
  END IF;

  -- New finalized snapshots must never have an expense total without any
  -- captured Trip Expense provenance, even if older legacy data may have it.
  INSERT INTO public.driver_settlements(
    company_id, driver_id, period_start, period_end,
    driver_paid_trip_expenses_total
  ) VALUES (
    v_company, v_driver, v_period + 3, v_period + 3, 1
  ) RETURNING id INTO v_prevoid_settlement;

  v_denied := false;
  BEGIN
    UPDATE public.driver_settlements
    SET status = 'finalized'::public.driver_settlement_status
    WHERE company_id = v_company AND id = v_prevoid_settlement;
  EXCEPTION WHEN SQLSTATE 'P2812' THEN
    v_denied := true;
  END;
  IF NOT v_denied THEN
    RAISE EXCEPTION 'Issue 337: missing source provenance finalized';
  END IF;

  RAISE NOTICE 'PASS Issue 337: captured, unlinked, legacy, void-first, missing-provenance, idempotency and audit assertions';
END;
$issue337$;

ROLLBACK;
