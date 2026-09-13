-- H.O.R.U.S System — Issue #226 / PC-02
-- Split financial-readiness failures from business-timezone failures for
-- Customer Statements and Dashboard without changing their source semantics.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_customer_statement_source(
  p_company_id uuid,
  p_customer_id uuid,
  p_from_date date,
  p_to_date date
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
  v_business_timezone text;

  v_customer_name text;
  v_customer_is_active boolean;

  v_opening_invoices jsonb;
  v_opening_payments jsonb;
  v_movements jsonb;
BEGIN
  IF auth.uid() IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY[
         'owner',
         'admin',
         'operations',
         'accountant',
         'viewer'
       ]::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2810',
      MESSAGE = 'customer_statement_permission_denied';
  END IF;

  IF p_from_date IS NOT NULL
     AND p_to_date IS NOT NULL
     AND p_from_date > p_to_date THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2811',
      MESSAGE = 'customer_statement_invalid_date_range';
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
      ERRCODE = 'P2812',
      MESSAGE = 'customer_statement_company_not_found';
  END IF;

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2815',
      MESSAGE = 'customer_statement_financial_settings_not_configured';
  END IF;

  IF v_business_timezone IS NULL
     OR pg_catalog.btrim(v_business_timezone) = '' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2813',
      MESSAGE = 'customer_statement_business_timezone_not_configured';
  END IF;

  SELECT
    customer_row.name,
    customer_row.is_active
  INTO
    v_customer_name,
    v_customer_is_active
  FROM public.customers AS customer_row
  WHERE customer_row.company_id = p_company_id
    AND customer_row.id = p_customer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2814',
      MESSAGE = 'customer_statement_customer_not_found';
  END IF;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'currency_code', opening_row.currency_code,
        'total_minor_units', opening_row.total_minor_units
      )
      ORDER BY opening_row.currency_code
    ),
    '[]'::jsonb
  )
  INTO v_opening_invoices
  FROM (
    SELECT
      invoice_row.currency_code,
      pg_catalog.sum(invoice_row.total_minor_units) AS total_minor_units
    FROM public.invoices AS invoice_row
    WHERE invoice_row.company_id = p_company_id
      AND invoice_row.customer_id = p_customer_id
      AND invoice_row.status IN (
        'issued'::public.invoice_status,
        'partially_paid'::public.invoice_status,
        'paid'::public.invoice_status
      )
      AND invoice_row.issue_date < p_from_date
    GROUP BY invoice_row.currency_code
  ) AS opening_row;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'currency_code', opening_row.currency_code,
        'total_minor_units', opening_row.total_minor_units
      )
      ORDER BY opening_row.currency_code
    ),
    '[]'::jsonb
  )
  INTO v_opening_payments
  FROM (
    SELECT
      payment_row.currency_code,
      pg_catalog.sum(payment_row.amount_minor_units) AS total_minor_units
    FROM public.payments AS payment_row
    WHERE payment_row.company_id = p_company_id
      AND payment_row.customer_id = p_customer_id
      AND payment_row.payment_date < p_from_date
    GROUP BY payment_row.currency_code
  ) AS opening_row;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'source_type', movement_row.source_type,
        'source_id', movement_row.source_id,
        'business_date', movement_row.business_date,
        'event_timestamp', movement_row.event_timestamp,
        'amount_minor_units', movement_row.amount_minor_units,
        'currency_code', movement_row.currency_code,
        'reference', movement_row.reference,
        'related_invoice_id', movement_row.related_invoice_id
      )
      ORDER BY
        movement_row.business_date,
        movement_row.event_timestamp,
        movement_row.source_type,
        movement_row.source_id
    ),
    '[]'::jsonb
  )
  INTO v_movements
  FROM (
    SELECT
      'invoice'::text AS source_type,
      invoice_row.id AS source_id,
      invoice_row.issue_date AS business_date,
      invoice_row.issued_at AS event_timestamp,
      invoice_row.total_minor_units AS amount_minor_units,
      invoice_row.currency_code,
      invoice_row.invoice_number AS reference,
      invoice_row.id AS related_invoice_id
    FROM public.invoices AS invoice_row
    WHERE invoice_row.company_id = p_company_id
      AND invoice_row.customer_id = p_customer_id
      AND invoice_row.status IN (
        'issued'::public.invoice_status,
        'partially_paid'::public.invoice_status,
        'paid'::public.invoice_status
      )
      AND (
        p_from_date IS NULL
        OR invoice_row.issue_date >= p_from_date
      )
      AND (
        p_to_date IS NULL
        OR invoice_row.issue_date <= p_to_date
      )

    UNION ALL

    SELECT
      'payment'::text AS source_type,
      payment_row.id AS source_id,
      payment_row.payment_date AS business_date,
      payment_row.created_at AS event_timestamp,
      payment_row.amount_minor_units AS amount_minor_units,
      payment_row.currency_code,
      payment_row.reference_number AS reference,
      payment_row.invoice_id AS related_invoice_id
    FROM public.payments AS payment_row
    WHERE payment_row.company_id = p_company_id
      AND payment_row.customer_id = p_customer_id
      AND (
        p_from_date IS NULL
        OR payment_row.payment_date >= p_from_date
      )
      AND (
        p_to_date IS NULL
        OR payment_row.payment_date <= p_to_date
      )
  ) AS movement_row;

  RETURN pg_catalog.jsonb_build_object(
    'company',
    pg_catalog.jsonb_build_object(
      'company_id', p_company_id,
      'base_currency_code', v_currency_code,
      'base_currency_fraction_digits', v_fraction_digits,
      'business_timezone', v_business_timezone
    ),
    'customer',
    pg_catalog.jsonb_build_object(
      'customer_id', p_customer_id,
      'customer_name', v_customer_name,
      'is_active', v_customer_is_active
    ),
    'period',
    pg_catalog.jsonb_build_object(
      'from_date', p_from_date,
      'to_date', p_to_date
    ),
    'opening',
    pg_catalog.jsonb_build_object(
      'invoices', v_opening_invoices,
      'payments', v_opening_payments
    ),
    'movements', v_movements
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dashboard_source(
  p_company_id uuid
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

  v_today_trips bigint;
  v_running_trips bigint;
  v_delivered_trips bigint;
  v_available_vehicles bigint;
  v_vehicles_on_trip bigint;
  v_unpaid_invoices bigint;

  v_revenue_minor_units bigint;
  v_trip_expenses_amount numeric;
  v_company_expenses_amount numeric;
  v_trip_expenses_minor_units bigint;
  v_company_expenses_minor_units bigint;

  v_invoice_currency_mismatch_count bigint;
  v_payment_currency_mismatch_count bigint;
  v_expense_precision_loss_count bigint;
  v_negative_expense_count bigint;
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

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL THEN
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
    AND COALESCE(
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
    COALESCE(
      pg_catalog.sum(invoice_row.taxable_minor_units),
      0
    )::bigint,
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
    COALESCE(pg_catalog.sum(expense_row.amount), 0),
    pg_catalog.count(*) FILTER (
      WHERE pg_catalog.round(expense_row.amount * v_minor_factor)
        IS DISTINCT FROM expense_row.amount * v_minor_factor
    ),
    pg_catalog.count(*) FILTER (
      WHERE expense_row.amount < 0
    )
  INTO
    v_trip_expenses_amount,
    v_expense_precision_loss_count,
    v_negative_expense_count
  FROM public.trip_expenses AS expense_row
  WHERE expense_row.company_id = p_company_id;

  v_trip_expenses_minor_units := pg_catalog.round(
    v_trip_expenses_amount * v_minor_factor
  )::bigint;

  SELECT
    COALESCE(pg_catalog.sum(expense_row.amount), 0),
    v_expense_precision_loss_count + pg_catalog.count(*) FILTER (
      WHERE pg_catalog.round(expense_row.amount * v_minor_factor)
        IS DISTINCT FROM expense_row.amount * v_minor_factor
    ),
    v_negative_expense_count + pg_catalog.count(*) FILTER (
      WHERE expense_row.amount < 0
    )
  INTO
    v_company_expenses_amount,
    v_expense_precision_loss_count,
    v_negative_expense_count
  FROM public.company_expenses AS expense_row
  WHERE expense_row.company_id = p_company_id
    AND expense_row.is_voided = false;

  v_company_expenses_minor_units := pg_catalog.round(
    v_company_expenses_amount * v_minor_factor
  )::bigint;

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
      COALESCE(payment_totals.paid_minor_units, 0)::bigint
        AS paid_minor_units,
      (
        invoice_row.total_minor_units
        - COALESCE(payment_totals.paid_minor_units, 0)
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
        v_invoice_currency_mismatch_count + v_payment_currency_mismatch_count,
      'expense_precision_loss_count', v_expense_precision_loss_count,
      'negative_expense_count', v_negative_expense_count,
      'invalid_invoice_balance_count', v_invalid_invoice_balance_count
    )
  );
END;
$function$;

COMMIT;
