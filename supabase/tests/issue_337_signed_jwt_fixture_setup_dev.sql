-- H.O.R.U.S System — Issue #337 signed-JWT and concurrency fixtures.
-- DEVELOPMENT ONLY. Do NOT include in supabase/migrations or run in Production.
-- This SETUP COMMITS real, uniquely-marked test data. Use only when ready to
-- perform the signed-JWT matrix and two-session race verification.
-- Capture the returned IDs securely; never commit them or user credentials.
BEGIN;

CREATE TEMP TABLE issue337_fixture_ids (
  fixture_marker text,
  company_a_id uuid,
  company_b_id uuid,
  locked_expense_id uuid,
  legacy_expense_id uuid,
  available_expense_id uuid,
  foreign_expense_id uuid,
  race_a_expense_id uuid,
  race_a_settlement_id uuid,
  race_b_expense_id uuid,
  race_b_settlement_id uuid
) ON COMMIT DROP;

DO $issue337_fixture$
DECLARE
  v_a record;
  v_b record;
  v_period date;
  v_marker text := 'issue337-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 14);
  v_minor_units bigint;
  v_locked uuid;
  v_legacy uuid;
  v_available uuid;
  v_foreign uuid;
  v_race_a uuid;
  v_race_b uuid;
  v_settlement uuid;
  v_race_a_settlement uuid;
  v_race_b_settlement uuid;
BEGIN
  SELECT t.company_id, owner.user_id AS owner_id, t.driver_id, t.id AS trip_id,
         et.id AS expense_type_id,
         c.base_currency_code AS currency_code,
         c.base_currency_fraction_digits AS fraction_digits
  INTO v_a
  FROM public.trips t
  JOIN public.companies c ON c.id = t.company_id AND c.is_active
  JOIN public.company_users owner
    ON owner.company_id = t.company_id
   AND owner.role = 'owner'::public.company_role
   AND owner.is_active
  JOIN public.expense_types et
    ON et.company_id = t.company_id AND et.is_active AND et.ledger_eligible
  WHERE t.driver_id IS NOT NULL
    AND c.base_currency_code IS NOT NULL
    AND c.base_currency_fraction_digits IS NOT NULL
  ORDER BY t.company_id, t.id, et.id
  LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Issue 337 Development company A fixture unavailable';
  END IF;

  SELECT t.company_id, owner.user_id AS owner_id, t.driver_id, t.id AS trip_id,
         et.id AS expense_type_id,
         c.base_currency_code AS currency_code,
         c.base_currency_fraction_digits AS fraction_digits
  INTO v_b
  FROM public.trips t
  JOIN public.companies c ON c.id = t.company_id AND c.is_active
  JOIN public.company_users owner
    ON owner.company_id = t.company_id
   AND owner.role = 'owner'::public.company_role
   AND owner.is_active
  JOIN public.expense_types et
    ON et.company_id = t.company_id AND et.is_active AND et.ledger_eligible
  WHERE t.driver_id IS NOT NULL
    AND t.company_id <> v_a.company_id
    AND c.base_currency_code IS NOT NULL
    AND c.base_currency_fraction_digits IS NOT NULL
  ORDER BY t.company_id, t.id, et.id
  LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Issue 337 Development company B fixture unavailable';
  END IF;

  SELECT greatest(
    (CURRENT_DATE + INTERVAL '5 years')::date,
    coalesce(max(period_end) + 1, (CURRENT_DATE + INTERVAL '5 years')::date)
  )
  INTO v_period
  FROM public.driver_settlements
  WHERE company_id = v_a.company_id AND driver_id = v_a.driver_id;

  v_minor_units := power(10::numeric, v_a.fraction_digits)::bigint;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_a.owner_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claim.role', 'authenticated', true);

  -- Captured canonical Trip Expense.
  INSERT INTO public.expense_ledger_entries (
    company_id, expense_type_id, amount_minor_units, currency_code,
    currency_fraction_digits, expense_date, funding_source,
    trip_id, description, origin_kind
  ) VALUES (
    v_a.company_id, v_a.expense_type_id, v_minor_units,
    v_a.currency_code, v_a.fraction_digits,
    v_period, 'driver_cash', v_a.trip_id,
    v_marker || ':locked', 'manual'
  ) RETURNING id INTO v_locked;

  INSERT INTO public.driver_settlements (
    company_id, driver_id, period_start, period_end,
    driver_paid_trip_expenses_total, notes
  ) VALUES (
    v_a.company_id, v_a.driver_id, v_period, v_period, 1, v_marker
  ) RETURNING id INTO v_settlement;

  INSERT INTO public.driver_settlement_items (
    company_id, settlement_id, source_type, source_id, source_date,
    direction, amount, label_key
  ) VALUES (
    v_a.company_id, v_settlement, 'trip_expense', v_locked, v_period,
    'company_to_driver', 1, 'driver_settlement_item_trip_expense'
  );

  UPDATE public.driver_settlements
  SET status = 'finalized'::public.driver_settlement_status
  WHERE company_id = v_a.company_id AND id = v_settlement;

  -- Legacy projection: settlement source_id contains origin_id.
  INSERT INTO public.expense_ledger_entries (
    company_id, expense_type_id, amount_minor_units, currency_code,
    currency_fraction_digits, expense_date, funding_source,
    trip_id, description, origin_kind, origin_id
  ) VALUES (
    v_a.company_id, v_a.expense_type_id, v_minor_units,
    v_a.currency_code, v_a.fraction_digits,
    v_period + 1, 'driver_cash', v_a.trip_id,
    v_marker || ':legacy', 'legacy_trip_expense', gen_random_uuid()
  ) RETURNING id INTO v_legacy;

  INSERT INTO public.driver_settlements (
    company_id, driver_id, period_start, period_end,
    driver_paid_trip_expenses_total, notes
  ) VALUES (
    v_a.company_id, v_a.driver_id, v_period + 1, v_period + 1, 1, v_marker
  ) RETURNING id INTO v_settlement;

  INSERT INTO public.driver_settlement_items (
    company_id, settlement_id, source_type, source_id, source_date,
    direction, amount, label_key
  ) SELECT
    v_a.company_id, v_settlement, 'trip_expense', origin_id, v_period + 1,
    'company_to_driver', 1, 'driver_settlement_item_trip_expense'
  FROM public.expense_ledger_entries
  WHERE company_id = v_a.company_id AND id = v_legacy;

  UPDATE public.driver_settlements
  SET status = 'finalized'::public.driver_settlement_status
  WHERE company_id = v_a.company_id AND id = v_settlement;

  -- Late-posted/backdated source: same period as captured locked source, but
  -- created_at is later than the finalized settlement's snapshot timestamp.
  INSERT INTO public.expense_ledger_entries (
    company_id, expense_type_id, amount_minor_units, currency_code,
    currency_fraction_digits, expense_date, funding_source,
    trip_id, description, origin_kind, created_at
  ) VALUES (
    v_a.company_id, v_a.expense_type_id, v_minor_units,
    v_a.currency_code, v_a.fraction_digits,
    v_period, 'driver_cash', v_a.trip_id,
    v_marker || ':available', 'manual', pg_catalog.clock_timestamp()
  ) RETURNING id INTO v_available;

  -- Two independent draft fixtures: never reuse a consumed race fixture.
  INSERT INTO public.expense_ledger_entries (
    company_id, expense_type_id, amount_minor_units, currency_code,
    currency_fraction_digits, expense_date, funding_source,
    trip_id, description, origin_kind
  ) VALUES (
    v_a.company_id, v_a.expense_type_id, v_minor_units,
    v_a.currency_code, v_a.fraction_digits,
    v_period + 2, 'driver_cash', v_a.trip_id,
    v_marker || ':race-a', 'manual'
  ) RETURNING id INTO v_race_a;

  INSERT INTO public.driver_settlements (
    company_id, driver_id, period_start, period_end,
    driver_paid_trip_expenses_total, notes
  ) VALUES (
    v_a.company_id, v_a.driver_id, v_period + 2, v_period + 2, 1, v_marker
  ) RETURNING id INTO v_race_a_settlement;

  INSERT INTO public.driver_settlement_items (
    company_id, settlement_id, source_type, source_id, source_date,
    direction, amount, label_key
  ) VALUES (
    v_a.company_id, v_race_a_settlement, 'trip_expense', v_race_a, v_period + 2,
    'company_to_driver', 1, 'driver_settlement_item_trip_expense'
  );

  INSERT INTO public.expense_ledger_entries (
    company_id, expense_type_id, amount_minor_units, currency_code,
    currency_fraction_digits, expense_date, funding_source,
    trip_id, description, origin_kind
  ) VALUES (
    v_a.company_id, v_a.expense_type_id, v_minor_units,
    v_a.currency_code, v_a.fraction_digits,
    v_period + 3, 'driver_cash', v_a.trip_id,
    v_marker || ':race-b', 'manual'
  ) RETURNING id INTO v_race_b;

  INSERT INTO public.driver_settlements (
    company_id, driver_id, period_start, period_end,
    driver_paid_trip_expenses_total, notes
  ) VALUES (
    v_a.company_id, v_a.driver_id, v_period + 3, v_period + 3, 1, v_marker
  ) RETURNING id INTO v_race_b_settlement;

  INSERT INTO public.driver_settlement_items (
    company_id, settlement_id, source_type, source_id, source_date,
    direction, amount, label_key
  ) VALUES (
    v_a.company_id, v_race_b_settlement, 'trip_expense', v_race_b, v_period + 3,
    'company_to_driver', 1, 'driver_settlement_item_trip_expense'
  );

  -- Foreign tenant source, with a different company owner as the test actor.
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', v_b.owner_id::text, true);
  INSERT INTO public.expense_ledger_entries (
    company_id, expense_type_id, amount_minor_units, currency_code,
    currency_fraction_digits, expense_date, funding_source,
    trip_id, description, origin_kind
  ) VALUES (
    v_b.company_id, v_b.expense_type_id,
    power(10::numeric, v_b.fraction_digits)::bigint,
    v_b.currency_code, v_b.fraction_digits,
    v_period, 'driver_cash', v_b.trip_id,
    v_marker || ':foreign', 'manual'
  ) RETURNING id INTO v_foreign;

  INSERT INTO issue337_fixture_ids VALUES (
    v_marker, v_a.company_id, v_b.company_id,
    v_locked, v_legacy, v_available, v_foreign,
    v_race_a, v_race_a_settlement, v_race_b, v_race_b_settlement
  );
END;
$issue337_fixture$;

-- Capture these values after explicit approval and use only for the signed
-- Development test runner. No credentials or JWTs are returned here.
SELECT * FROM issue337_fixture_ids;
COMMIT;
