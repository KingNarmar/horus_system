-- H.O.R.U.S System — Issue #240 / PC-16
-- Rebuild Dashboard and financial Reports over canonical financial semantics.
--
-- Contract:
-- - expense_ledger_entries is the canonical expense source.
-- - salary Company Expenses remain outside the canonical ledger by design.
-- - Driver Finance / settlement balance movements are not operating expenses.
-- - Trip profitability uses the persisted Trip commercial amount snapshot.
-- - RPC signatures and role boundaries remain backward compatible.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_dashboard_source(p_company_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
  v_business_timezone text;
  v_business_date date;
  v_minor_factor numeric;

  v_today_trips bigint;
  v_running_trips bigint;
  v_delivered_trips bigint;
  v_available_vehicles bigint;
  v_vehicles_on_trip bigint;
  v_unpaid_invoices bigint;

  v_revenue_minor_units bigint;
  v_trip_expenses_minor_units bigint;
  v_non_trip_expenses_minor_units bigint;
  v_salary_expenses_amount numeric;
  v_salary_expenses_minor_units bigint;
  v_company_expenses_minor_units bigint;

  v_invoice_currency_mismatch_count bigint;
  v_payment_currency_mismatch_count bigint;
  v_expense_currency_mismatch_count bigint;
  v_expense_precision_loss_count bigint;
  v_negative_expense_count bigint;
  v_salary_negative_expense_count bigint;
  v_invalid_invoice_balance_count bigint;
BEGIN
  IF auth.uid() IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM public.company_users AS membership_row
       WHERE membership_row.company_id = p_company_id
         AND membership_row.user_id = auth.uid()
         AND membership_row.is_active = true
         AND membership_row.role IN (
           'owner'::public.company_role,
           'admin'::public.company_role,
           'operations'::public.company_role,
           'accountant'::public.company_role,
           'viewer'::public.company_role
         )
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2910',
      MESSAGE = 'dashboard_permission_denied';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    company_row.business_timezone
  INTO
    v_currency_code,
    v_fraction_digits,
    v_business_timezone
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2911',
      MESSAGE = 'dashboard_company_not_found';
  END IF;

  IF v_currency_code IS NULL OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2913',
      MESSAGE = 'dashboard_financial_settings_not_configured';
  END IF;

  IF v_business_timezone IS NULL
     OR pg_catalog.btrim(v_business_timezone) = '' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2912',
      MESSAGE = 'dashboard_business_timezone_not_configured';
  END IF;

  v_business_date := (
    CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone
  )::date;
  v_minor_factor := pg_catalog.power(10::numeric, v_fraction_digits);

  SELECT pg_catalog.count(*)
  INTO v_today_trips
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND coalesce(
      (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
      (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
      trip_row.trip_date
    ) = v_business_date;

  SELECT pg_catalog.count(*)
  INTO v_running_trips
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.status = 'on_road'::public.trip_status;

  SELECT pg_catalog.count(*)
  INTO v_delivered_trips
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.status IN (
      'delivered'::public.trip_status,
      'documents_received'::public.trip_status,
      'invoiced'::public.trip_status,
      'paid'::public.trip_status
    );

  SELECT pg_catalog.count(*)
  INTO v_available_vehicles
  FROM public.tractor_heads AS tractor_row
  WHERE tractor_row.company_id = p_company_id
    AND tractor_row.is_active = true
    AND tractor_row.status = 'available'::public.vehicle_status
    AND NOT EXISTS (
      SELECT 1
      FROM public.trips AS blocking_trip
      WHERE blocking_trip.company_id = p_company_id
        AND blocking_trip.tractor_head_id = tractor_row.id
        AND blocking_trip.status IN (
          'created'::public.trip_status,
          'assigned'::public.trip_status,
          'loaded'::public.trip_status,
          'on_road'::public.trip_status,
          'arrived'::public.trip_status
        )
    );

  SELECT pg_catalog.count(DISTINCT trip_row.tractor_head_id)
  INTO v_vehicles_on_trip
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.tractor_head_id IS NOT NULL
    AND trip_row.status IN (
      'created'::public.trip_status,
      'assigned'::public.trip_status,
      'loaded'::public.trip_status,
      'on_road'::public.trip_status,
      'arrived'::public.trip_status
    );

  SELECT
    coalesce(pg_catalog.sum(invoice_row.taxable_minor_units), 0)::bigint,
    pg_catalog.count(*) FILTER (
      WHERE invoice_row.currency_code <> v_currency_code
    )
  INTO
    v_revenue_minor_units,
    v_invoice_currency_mismatch_count
  FROM public.invoices AS invoice_row
  WHERE invoice_row.company_id = p_company_id
    AND invoice_row.status IN (
      'issued'::public.invoice_status,
      'partially_paid'::public.invoice_status,
      'paid'::public.invoice_status
    );

  SELECT pg_catalog.count(*)
  INTO v_payment_currency_mismatch_count
  FROM public.payments AS payment_row
  WHERE payment_row.company_id = p_company_id
    AND payment_row.currency_code <> v_currency_code;

  SELECT
    coalesce(
      pg_catalog.sum(expense_row.amount_minor_units)
        FILTER (WHERE expense_row.trip_id IS NOT NULL),
      0
    )::bigint,
    coalesce(
      pg_catalog.sum(expense_row.amount_minor_units)
        FILTER (WHERE expense_row.trip_id IS NULL),
      0
    )::bigint,
    pg_catalog.count(*) FILTER (
      WHERE expense_row.currency_code <> v_currency_code
         OR expense_row.currency_fraction_digits <> v_fraction_digits
    ),
    pg_catalog.count(*) FILTER (
      WHERE expense_row.amount_minor_units < 0
    )
  INTO
    v_trip_expenses_minor_units,
    v_non_trip_expenses_minor_units,
    v_expense_currency_mismatch_count,
    v_negative_expense_count
  FROM public.expense_ledger_entries AS expense_row
  WHERE expense_row.company_id = p_company_id
    AND expense_row.is_voided = false;

  SELECT
    coalesce(pg_catalog.sum(expense_row.amount), 0),
    pg_catalog.count(*) FILTER (
      WHERE pg_catalog.round(expense_row.amount * v_minor_factor)
        IS DISTINCT FROM expense_row.amount * v_minor_factor
    ),
    pg_catalog.count(*) FILTER (
      WHERE expense_row.amount < 0
    )
  INTO
    v_salary_expenses_amount,
    v_expense_precision_loss_count,
    v_salary_negative_expense_count
  FROM public.company_expenses AS expense_row
  INNER JOIN public.company_expense_categories AS category_row
    ON category_row.company_id = expense_row.company_id
   AND category_row.id = expense_row.category_id
  WHERE expense_row.company_id = p_company_id
    AND expense_row.is_voided = false
    AND category_row.code = 'salaries';

  v_salary_expenses_minor_units := pg_catalog.round(
    v_salary_expenses_amount * v_minor_factor
  )::bigint;

  v_company_expenses_minor_units :=
    v_non_trip_expenses_minor_units + v_salary_expenses_minor_units;
  v_negative_expense_count :=
    v_negative_expense_count + v_salary_negative_expense_count;

  WITH payment_totals AS (
    SELECT
      payment_row.invoice_id,
      pg_catalog.sum(payment_row.amount_minor_units)::bigint AS paid_minor_units
    FROM public.payments AS payment_row
    WHERE payment_row.company_id = p_company_id
    GROUP BY payment_row.invoice_id
  ),
  invoice_balances AS (
    SELECT
      invoice_row.status,
      invoice_row.total_minor_units,
      coalesce(payment_totals.paid_minor_units, 0)::bigint AS paid_minor_units,
      (
        invoice_row.total_minor_units
        - coalesce(payment_totals.paid_minor_units, 0)
      )::bigint AS remaining_minor_units
    FROM public.invoices AS invoice_row
    LEFT JOIN payment_totals
      ON payment_totals.invoice_id = invoice_row.id
    WHERE invoice_row.company_id = p_company_id
      AND invoice_row.status IN (
        'issued'::public.invoice_status,
        'partially_paid'::public.invoice_status,
        'paid'::public.invoice_status
      )
  )
  SELECT
    pg_catalog.count(*) FILTER (
      WHERE balance_row.status IN (
        'issued'::public.invoice_status,
        'partially_paid'::public.invoice_status
      )
      AND balance_row.remaining_minor_units > 0
    ),
    pg_catalog.count(*) FILTER (
      WHERE balance_row.paid_minor_units < 0
         OR balance_row.remaining_minor_units < 0
         OR (
           balance_row.status = 'paid'::public.invoice_status
           AND balance_row.remaining_minor_units <> 0
         )
         OR (
           balance_row.status IN (
             'issued'::public.invoice_status,
             'partially_paid'::public.invoice_status
           )
           AND balance_row.remaining_minor_units <= 0
         )
    )
  INTO
    v_unpaid_invoices,
    v_invalid_invoice_balance_count
  FROM invoice_balances AS balance_row;

  RETURN pg_catalog.jsonb_build_object(
    'company',
    pg_catalog.jsonb_build_object(
      'company_id', p_company_id,
      'base_currency_code', v_currency_code,
      'base_currency_fraction_digits', v_fraction_digits,
      'business_timezone', v_business_timezone,
      'business_date', v_business_date
    ),
    'metrics',
    pg_catalog.jsonb_build_object(
      'today_trips', v_today_trips,
      'running_trips', v_running_trips,
      'delivered_trips', v_delivered_trips,
      'available_vehicles', v_available_vehicles,
      'vehicles_on_trip', v_vehicles_on_trip,
      'unpaid_invoices', v_unpaid_invoices
    ),
    'financial',
    pg_catalog.jsonb_build_object(
      'revenue_minor_units', v_revenue_minor_units,
      'trip_expenses_minor_units', v_trip_expenses_minor_units,
      'company_expenses_minor_units', v_company_expenses_minor_units
    ),
    'validation',
    pg_catalog.jsonb_build_object(
      'financial_currency_mismatch_count',
        v_invoice_currency_mismatch_count
        + v_payment_currency_mismatch_count
        + v_expense_currency_mismatch_count,
      'expense_precision_loss_count', v_expense_precision_loss_count,
      'negative_expense_count', v_negative_expense_count,
      'invalid_invoice_balance_count', v_invalid_invoice_balance_count
    )
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_trip_expenses_report_source(
  p_company_id uuid,
  p_from_date date,
  p_to_date date
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
  v_business_timezone text;
  v_business_date date;
  v_rows jsonb;
  v_precision_loss_count bigint := 0;
  v_negative_amount_count bigint;
  v_currency_mismatch_count bigint;
BEGIN
  IF auth.uid() IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM public.company_users AS membership_row
       WHERE membership_row.company_id = p_company_id
         AND membership_row.user_id = auth.uid()
         AND membership_row.is_active = true
         AND membership_row.role IN (
           'owner'::public.company_role,
           'admin'::public.company_role,
           'accountant'::public.company_role
         )
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3010',
      MESSAGE = 'reports_permission_denied';
  END IF;

  IF p_from_date IS NOT NULL
     AND p_to_date IS NOT NULL
     AND p_from_date > p_to_date THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3011',
      MESSAGE = 'reports_invalid_date_range';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    company_row.business_timezone
  INTO
    v_currency_code,
    v_fraction_digits,
    v_business_timezone
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3012',
      MESSAGE = 'reports_company_not_found';
  END IF;

  IF v_currency_code IS NULL OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3014',
      MESSAGE = 'reports_financial_settings_not_configured';
  END IF;

  IF v_business_timezone IS NULL
     OR pg_catalog.btrim(v_business_timezone) = '' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3013',
      MESSAGE = 'reports_business_timezone_not_configured';
  END IF;

  v_business_date := (
    CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone
  )::date;

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE expense_row.amount_minor_units < 0
    ),
    pg_catalog.count(*) FILTER (
      WHERE expense_row.currency_code <> v_currency_code
         OR expense_row.currency_fraction_digits <> v_fraction_digits
    )
  INTO
    v_negative_amount_count,
    v_currency_mismatch_count
  FROM public.expense_ledger_entries AS expense_row
  WHERE expense_row.company_id = p_company_id
    AND expense_row.trip_id IS NOT NULL
    AND expense_row.is_voided = false
    AND (
      p_from_date IS NULL
      OR expense_row.expense_date >= p_from_date
    )
    AND (
      p_to_date IS NULL
      OR expense_row.expense_date <= p_to_date
    );

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'expense_id', report_row.expense_id,
        'expense_date', report_row.expense_date,
        'trip_id', report_row.trip_id,
        'trip_number', report_row.trip_number,
        'trip_date', report_row.trip_date,
        'customer_id', report_row.customer_id,
        'customer_name', report_row.customer_name,
        'loading_location', report_row.loading_location,
        'unloading_location', report_row.unloading_location,
        'loading_order_number', report_row.loading_order_number,
        'waybill_number', report_row.waybill_number,
        'expense_type_id', report_row.expense_type_id,
        'expense_name', report_row.expense_name,
        'paid_by', report_row.paid_by,
        'amount_minor_units', report_row.amount_minor_units
      )
      ORDER BY
        report_row.expense_date DESC,
        report_row.created_at DESC,
        report_row.expense_id
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM (
    SELECT
      CASE
        WHEN expense_row.origin_kind = 'legacy_trip_expense'
          THEN expense_row.origin_id
        ELSE expense_row.id
      END AS expense_id,
      expense_row.expense_date,
      trip_row.id AS trip_id,
      trip_row.trip_number,
      trip_row.trip_date,
      customer_row.id AS customer_id,
      customer_row.name AS customer_name,
      route_row.loading_location,
      route_row.unloading_location,
      trip_row.loading_order_number,
      trip_row.waybill_number,
      expense_row.expense_type_id,
      coalesce(expense_row.description, type_row.name) AS expense_name,
      expense_row.funding_source AS paid_by,
      expense_row.amount_minor_units,
      expense_row.created_at
    FROM public.expense_ledger_entries AS expense_row
    INNER JOIN public.expense_types AS type_row
      ON type_row.company_id = expense_row.company_id
     AND type_row.id = expense_row.expense_type_id
    INNER JOIN public.trips AS trip_row
      ON trip_row.company_id = expense_row.company_id
     AND trip_row.id = expense_row.trip_id
    INNER JOIN public.customers AS customer_row
      ON customer_row.company_id = trip_row.company_id
     AND customer_row.id = trip_row.customer_id
    INNER JOIN public.routes AS route_row
      ON route_row.company_id = trip_row.company_id
     AND route_row.id = trip_row.route_id
    WHERE expense_row.company_id = p_company_id
      AND expense_row.trip_id IS NOT NULL
      AND expense_row.is_voided = false
      AND (
        p_from_date IS NULL
        OR expense_row.expense_date >= p_from_date
      )
      AND (
        p_to_date IS NULL
        OR expense_row.expense_date <= p_to_date
      )
  ) AS report_row;

  RETURN pg_catalog.jsonb_build_object(
    'company',
    pg_catalog.jsonb_build_object(
      'company_id', p_company_id,
      'base_currency_code', v_currency_code,
      'base_currency_fraction_digits', v_fraction_digits,
      'business_timezone', v_business_timezone,
      'business_date', v_business_date
    ),
    'period',
    pg_catalog.jsonb_build_object(
      'from_date', p_from_date,
      'to_date', p_to_date
    ),
    'validation',
    pg_catalog.jsonb_build_object(
      'precision_loss_count', v_precision_loss_count,
      'negative_amount_count', v_negative_amount_count,
      'currency_mismatch_count', v_currency_mismatch_count
    ),
    'rows', v_rows
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_trip_net_profit_report_source(
  p_company_id uuid,
  p_from_date date,
  p_to_date date
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
  v_business_timezone text;
  v_business_date date;
  v_minor_factor numeric;
  v_trips jsonb;
  v_expenses jsonb;
  v_freight_precision_loss_count bigint;
  v_negative_freight_count bigint;
  v_expense_precision_loss_count bigint := 0;
  v_negative_expense_count bigint;
  v_expense_currency_mismatch_count bigint;
BEGIN
  IF auth.uid() IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM public.company_users AS membership_row
       WHERE membership_row.company_id = p_company_id
         AND membership_row.user_id = auth.uid()
         AND membership_row.is_active = true
         AND membership_row.role IN (
           'owner'::public.company_role,
           'admin'::public.company_role,
           'accountant'::public.company_role
         )
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3010',
      MESSAGE = 'reports_permission_denied';
  END IF;

  IF p_from_date IS NOT NULL
     AND p_to_date IS NOT NULL
     AND p_from_date > p_to_date THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3011',
      MESSAGE = 'reports_invalid_date_range';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    company_row.business_timezone
  INTO
    v_currency_code,
    v_fraction_digits,
    v_business_timezone
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3012',
      MESSAGE = 'reports_company_not_found';
  END IF;

  IF v_currency_code IS NULL OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3014',
      MESSAGE = 'reports_financial_settings_not_configured';
  END IF;

  IF v_business_timezone IS NULL
     OR pg_catalog.btrim(v_business_timezone) = '' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3013',
      MESSAGE = 'reports_business_timezone_not_configured';
  END IF;

  v_business_date := (
    CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone
  )::date;
  v_minor_factor := pg_catalog.power(10::numeric, v_fraction_digits);

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE pg_catalog.round(
        coalesce(trip_row.freight_price, 0::numeric) * v_minor_factor
      ) IS DISTINCT FROM
        coalesce(trip_row.freight_price, 0::numeric) * v_minor_factor
    ),
    pg_catalog.count(*) FILTER (
      WHERE coalesce(trip_row.freight_price, 0::numeric) < 0
    )
  INTO
    v_freight_precision_loss_count,
    v_negative_freight_count
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND (
      p_from_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) >= p_from_date
    )
    AND (
      p_to_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) <= p_to_date
    );

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'trip_id', report_row.trip_id,
        'trip_number', report_row.trip_number,
        'operational_date', report_row.operational_date,
        'status', report_row.status,
        'customer_id', report_row.customer_id,
        'customer_name', report_row.customer_name,
        'driver_id', report_row.driver_id,
        'driver_name', report_row.driver_name,
        'tractor_head_id', report_row.tractor_head_id,
        'tractor_head_plate_number', report_row.tractor_head_plate_number,
        'trailer_id', report_row.trailer_id,
        'trailer_plate_number', report_row.trailer_plate_number,
        'loading_location', report_row.loading_location,
        'unloading_location', report_row.unloading_location,
        'loading_order_number', report_row.loading_order_number,
        'waybill_number', report_row.waybill_number,
        'freight_minor_units', report_row.freight_minor_units
      )
      ORDER BY
        report_row.operational_date DESC,
        report_row.created_at DESC,
        report_row.trip_id
    ),
    '[]'::jsonb
  )
  INTO v_trips
  FROM (
    SELECT
      trip_row.id AS trip_id,
      trip_row.trip_number,
      coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) AS operational_date,
      trip_row.status::text AS status,
      customer_row.id AS customer_id,
      customer_row.name AS customer_name,
      driver_row.id AS driver_id,
      driver_row.name AS driver_name,
      tractor_row.id AS tractor_head_id,
      tractor_row.plate_number AS tractor_head_plate_number,
      trailer_row.id AS trailer_id,
      trailer_row.plate_number AS trailer_plate_number,
      route_row.loading_location,
      route_row.unloading_location,
      trip_row.loading_order_number,
      trip_row.waybill_number,
      pg_catalog.round(
        coalesce(trip_row.freight_price, 0::numeric) * v_minor_factor
      )::bigint AS freight_minor_units,
      trip_row.created_at
    FROM public.trips AS trip_row
    INNER JOIN public.customers AS customer_row
      ON customer_row.company_id = trip_row.company_id
     AND customer_row.id = trip_row.customer_id
    INNER JOIN public.routes AS route_row
      ON route_row.company_id = trip_row.company_id
     AND route_row.id = trip_row.route_id
    LEFT JOIN public.drivers AS driver_row
      ON driver_row.company_id = trip_row.company_id
     AND driver_row.id = trip_row.driver_id
    LEFT JOIN public.tractor_heads AS tractor_row
      ON tractor_row.company_id = trip_row.company_id
     AND tractor_row.id = trip_row.tractor_head_id
    LEFT JOIN public.trailers AS trailer_row
      ON trailer_row.company_id = trip_row.company_id
     AND trailer_row.id = trip_row.trailer_id
    WHERE trip_row.company_id = p_company_id
      AND (
        p_from_date IS NULL
        OR coalesce(
          (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
          (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
          trip_row.trip_date
        ) >= p_from_date
      )
      AND (
        p_to_date IS NULL
        OR coalesce(
          (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
          (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
          trip_row.trip_date
        ) <= p_to_date
      )
  ) AS report_row;

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE expense_row.amount_minor_units < 0
    ),
    pg_catalog.count(*) FILTER (
      WHERE expense_row.currency_code <> v_currency_code
         OR expense_row.currency_fraction_digits <> v_fraction_digits
    )
  INTO
    v_negative_expense_count,
    v_expense_currency_mismatch_count
  FROM public.expense_ledger_entries AS expense_row
  INNER JOIN public.trips AS trip_row
    ON trip_row.company_id = expense_row.company_id
   AND trip_row.id = expense_row.trip_id
  WHERE expense_row.company_id = p_company_id
    AND expense_row.trip_id IS NOT NULL
    AND expense_row.is_voided = false
    AND (
      p_from_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) >= p_from_date
    )
    AND (
      p_to_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) <= p_to_date
    );

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'expense_id',
        CASE
          WHEN expense_row.origin_kind = 'legacy_trip_expense'
            THEN expense_row.origin_id
          ELSE expense_row.id
        END,
        'trip_id', expense_row.trip_id,
        'amount_minor_units', expense_row.amount_minor_units
      )
      ORDER BY
        expense_row.trip_id,
        expense_row.created_at,
        expense_row.id
    ),
    '[]'::jsonb
  )
  INTO v_expenses
  FROM public.expense_ledger_entries AS expense_row
  INNER JOIN public.trips AS trip_row
    ON trip_row.company_id = expense_row.company_id
   AND trip_row.id = expense_row.trip_id
  WHERE expense_row.company_id = p_company_id
    AND expense_row.trip_id IS NOT NULL
    AND expense_row.is_voided = false
    AND (
      p_from_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) >= p_from_date
    )
    AND (
      p_to_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) <= p_to_date
    );

  RETURN pg_catalog.jsonb_build_object(
    'company',
    pg_catalog.jsonb_build_object(
      'company_id', p_company_id,
      'base_currency_code', v_currency_code,
      'base_currency_fraction_digits', v_fraction_digits,
      'business_timezone', v_business_timezone,
      'business_date', v_business_date
    ),
    'period',
    pg_catalog.jsonb_build_object(
      'from_date', p_from_date,
      'to_date', p_to_date
    ),
    'validation',
    pg_catalog.jsonb_build_object(
      'freight_precision_loss_count', v_freight_precision_loss_count,
      'negative_freight_count', v_negative_freight_count,
      'expense_precision_loss_count', v_expense_precision_loss_count,
      'negative_expense_count', v_negative_expense_count,
      'expense_currency_mismatch_count', v_expense_currency_mismatch_count
    ),
    'trips', v_trips,
    'expenses', v_expenses
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_dashboard_source(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_dashboard_source(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_dashboard_source(uuid)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_trip_expenses_report_source(uuid, date, date)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_trip_expenses_report_source(uuid, date, date)
  FROM anon;
GRANT EXECUTE
  ON FUNCTION public.get_trip_expenses_report_source(uuid, date, date)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_trip_net_profit_report_source(uuid, date, date)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_trip_net_profit_report_source(uuid, date, date)
  FROM anon;
GRANT EXECUTE
  ON FUNCTION public.get_trip_net_profit_report_source(uuid, date, date)
  TO authenticated, service_role;

COMMIT;
