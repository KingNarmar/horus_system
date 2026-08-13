
-- H.O.R.U.S System — Issue #30 Basic reports read foundation
--
-- Adds four focused, company-scoped read RPCs for the initial reports module.
-- Report grouping, totals, invoice balance interpretation, and trip net profit
-- remain in Domain. These functions return source facts and validation metadata.
--
-- Security model:
-- - SECURITY INVOKER so underlying RLS remains active.
-- - Explicit company/role guard in every RPC.
-- - authenticated EXECUTE only; PUBLIC/anon denied.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_operational_trip_reports_source(
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

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL
     OR v_business_timezone IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3013',
      MESSAGE = 'reports_regional_settings_not_configured';
  END IF;

  v_business_date := (
    CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone
  )::date;

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
        'route_id', report_row.route_id,
        'loading_location', report_row.loading_location,
        'unloading_location', report_row.unloading_location,
        'loading_order_number', report_row.loading_order_number,
        'waybill_number', report_row.waybill_number,
        'cargo_type', report_row.cargo_type,
        'quantity_tons', report_row.quantity_tons
      )
      ORDER BY
        report_row.operational_date DESC,
        report_row.created_at DESC,
        report_row.trip_id
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM (
    SELECT
      trip_row.id AS trip_id,
      trip_row.trip_number,
      coalesce(
        (
          trip_row.actual_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        (
          trip_row.scheduled_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
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
      route_row.id AS route_id,
      route_row.loading_location,
      route_row.unloading_location,
      trip_row.loading_order_number,
      trip_row.waybill_number,
      trip_row.cargo_type,
      trip_row.quantity_tons,
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
          (
            trip_row.actual_loading_at
            AT TIME ZONE v_business_timezone
          )::date,
          (
            trip_row.scheduled_loading_at
            AT TIME ZONE v_business_timezone
          )::date,
          trip_row.trip_date
        ) >= p_from_date
      )
      AND (
        p_to_date IS NULL
        OR coalesce(
          (
            trip_row.actual_loading_at
            AT TIME ZONE v_business_timezone
          )::date,
          (
            trip_row.scheduled_loading_at
            AT TIME ZONE v_business_timezone
          )::date,
          trip_row.trip_date
        ) <= p_to_date
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
    'rows', v_rows
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
  v_minor_factor numeric;
  v_rows jsonb;
  v_precision_loss_count bigint;
  v_negative_amount_count bigint;
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

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL
     OR v_business_timezone IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3013',
      MESSAGE = 'reports_regional_settings_not_configured';
  END IF;

  v_business_date := (
    CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone
  )::date;
  v_minor_factor := pg_catalog.power(10::numeric, v_fraction_digits);

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE pg_catalog.round(expense_row.amount * v_minor_factor)
        IS DISTINCT FROM expense_row.amount * v_minor_factor
    ),
    pg_catalog.count(*) FILTER (
      WHERE expense_row.amount < 0
    )
  INTO
    v_precision_loss_count,
    v_negative_amount_count
  FROM public.trip_expenses AS expense_row
  WHERE expense_row.company_id = p_company_id
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
      expense_row.id AS expense_id,
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
      expense_row.expense_name,
      expense_row.paid_by::text AS paid_by,
      pg_catalog.round(
        expense_row.amount * v_minor_factor
      )::bigint AS amount_minor_units,
      expense_row.created_at
    FROM public.trip_expenses AS expense_row
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
      'negative_amount_count', v_negative_amount_count
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
  v_expense_precision_loss_count bigint;
  v_negative_expense_count bigint;
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

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL
     OR v_business_timezone IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3013',
      MESSAGE = 'reports_regional_settings_not_configured';
  END IF;

  v_business_date := (
    CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone
  )::date;
  v_minor_factor := pg_catalog.power(10::numeric, v_fraction_digits);

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE pg_catalog.round(
        coalesce(trip_row.freight_price, 0::numeric) * v_minor_factor
      ) IS DISTINCT FROM (
        coalesce(trip_row.freight_price, 0::numeric) * v_minor_factor
      )
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
        (
          trip_row.actual_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        (
          trip_row.scheduled_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        trip_row.trip_date
      ) >= p_from_date
    )
    AND (
      p_to_date IS NULL
      OR coalesce(
        (
          trip_row.actual_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        (
          trip_row.scheduled_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
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
        (
          trip_row.actual_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        (
          trip_row.scheduled_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
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
          (
            trip_row.actual_loading_at
            AT TIME ZONE v_business_timezone
          )::date,
          (
            trip_row.scheduled_loading_at
            AT TIME ZONE v_business_timezone
          )::date,
          trip_row.trip_date
        ) >= p_from_date
      )
      AND (
        p_to_date IS NULL
        OR coalesce(
          (
            trip_row.actual_loading_at
            AT TIME ZONE v_business_timezone
          )::date,
          (
            trip_row.scheduled_loading_at
            AT TIME ZONE v_business_timezone
          )::date,
          trip_row.trip_date
        ) <= p_to_date
      )
  ) AS report_row;

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE pg_catalog.round(expense_row.amount * v_minor_factor)
        IS DISTINCT FROM expense_row.amount * v_minor_factor
    ),
    pg_catalog.count(*) FILTER (
      WHERE expense_row.amount < 0
    )
  INTO
    v_expense_precision_loss_count,
    v_negative_expense_count
  FROM public.trip_expenses AS expense_row
  INNER JOIN public.trips AS trip_row
    ON trip_row.company_id = expense_row.company_id
   AND trip_row.id = expense_row.trip_id
  WHERE trip_row.company_id = p_company_id
    AND (
      p_from_date IS NULL
      OR coalesce(
        (
          trip_row.actual_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        (
          trip_row.scheduled_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        trip_row.trip_date
      ) >= p_from_date
    )
    AND (
      p_to_date IS NULL
      OR coalesce(
        (
          trip_row.actual_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        (
          trip_row.scheduled_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        trip_row.trip_date
      ) <= p_to_date
    );

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'expense_id', expense_row.id,
        'trip_id', expense_row.trip_id,
        'amount_minor_units',
          pg_catalog.round(
            expense_row.amount * v_minor_factor
          )::bigint
      )
      ORDER BY
        expense_row.trip_id,
        expense_row.created_at,
        expense_row.id
    ),
    '[]'::jsonb
  )
  INTO v_expenses
  FROM public.trip_expenses AS expense_row
  INNER JOIN public.trips AS trip_row
    ON trip_row.company_id = expense_row.company_id
   AND trip_row.id = expense_row.trip_id
  WHERE trip_row.company_id = p_company_id
    AND (
      p_from_date IS NULL
      OR coalesce(
        (
          trip_row.actual_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        (
          trip_row.scheduled_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        trip_row.trip_date
      ) >= p_from_date
    )
    AND (
      p_to_date IS NULL
      OR coalesce(
        (
          trip_row.actual_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
        (
          trip_row.scheduled_loading_at
          AT TIME ZONE v_business_timezone
        )::date,
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
      'negative_expense_count', v_negative_expense_count
    ),
    'trips', v_trips,
    'expenses', v_expenses
  );
END;
$function$;


CREATE OR REPLACE FUNCTION public.get_open_invoices_report_source(
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
  v_invoices jsonb;
  v_payments jsonb;
  v_invoice_currency_mismatch_count bigint;
  v_payment_currency_mismatch_count bigint;
  v_invalid_invoice_amount_count bigint;
  v_invalid_payment_amount_count bigint;
  v_missing_issue_date_count bigint;
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

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL
     OR v_business_timezone IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3013',
      MESSAGE = 'reports_regional_settings_not_configured';
  END IF;

  v_business_date := (
    CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone
  )::date;

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE invoice_row.currency_code <> v_currency_code
    ),
    pg_catalog.count(*) FILTER (
      WHERE invoice_row.total_minor_units < 0
    ),
    pg_catalog.count(*) FILTER (
      WHERE invoice_row.issue_date IS NULL
    )
  INTO
    v_invoice_currency_mismatch_count,
    v_invalid_invoice_amount_count,
    v_missing_issue_date_count
  FROM public.invoices AS invoice_row
  WHERE invoice_row.company_id = p_company_id
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
    );

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'invoice_id', invoice_row.id,
        'invoice_number', invoice_row.invoice_number,
        'customer_id', invoice_row.customer_id,
        'customer_name', invoice_row.customer_name,
        'status', invoice_row.status::text,
        'currency_code', invoice_row.currency_code,
        'total_minor_units', invoice_row.total_minor_units,
        'issue_date', invoice_row.issue_date,
        'due_date', invoice_row.due_date,
        'issued_at', invoice_row.issued_at
      )
      ORDER BY
        invoice_row.issue_date DESC NULLS LAST,
        invoice_row.issued_at DESC NULLS LAST,
        invoice_row.id
    ),
    '[]'::jsonb
  )
  INTO v_invoices
  FROM public.invoices AS invoice_row
  WHERE invoice_row.company_id = p_company_id
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
    );

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE payment_row.currency_code <> v_currency_code
    ),
    pg_catalog.count(*) FILTER (
      WHERE payment_row.amount_minor_units <= 0
    )
  INTO
    v_payment_currency_mismatch_count,
    v_invalid_payment_amount_count
  FROM public.payments AS payment_row
  INNER JOIN public.invoices AS invoice_row
    ON invoice_row.company_id = payment_row.company_id
   AND invoice_row.id = payment_row.invoice_id
  WHERE invoice_row.company_id = p_company_id
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
    );

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'payment_id', payment_row.id,
        'invoice_id', payment_row.invoice_id,
        'currency_code', payment_row.currency_code,
        'amount_minor_units', payment_row.amount_minor_units,
        'payment_date', payment_row.payment_date,
        'created_at', payment_row.created_at
      )
      ORDER BY
        payment_row.invoice_id,
        payment_row.payment_date,
        payment_row.created_at,
        payment_row.id
    ),
    '[]'::jsonb
  )
  INTO v_payments
  FROM public.payments AS payment_row
  INNER JOIN public.invoices AS invoice_row
    ON invoice_row.company_id = payment_row.company_id
   AND invoice_row.id = payment_row.invoice_id
  WHERE invoice_row.company_id = p_company_id
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
      'invoice_currency_mismatch_count', v_invoice_currency_mismatch_count,
      'payment_currency_mismatch_count', v_payment_currency_mismatch_count,
      'invalid_invoice_amount_count', v_invalid_invoice_amount_count,
      'invalid_payment_amount_count', v_invalid_payment_amount_count,
      'missing_issue_date_count', v_missing_issue_date_count
    ),
    'invoices', v_invoices,
    'payments', v_payments
  );
END;
$function$;


REVOKE ALL PRIVILEGES
ON FUNCTION public.get_operational_trip_reports_source(uuid, date, date)
FROM PUBLIC;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_operational_trip_reports_source(uuid, date, date)
FROM anon;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_operational_trip_reports_source(uuid, date, date)
FROM authenticated;

GRANT EXECUTE
ON FUNCTION public.get_operational_trip_reports_source(uuid, date, date)
TO authenticated;


REVOKE ALL PRIVILEGES
ON FUNCTION public.get_trip_expenses_report_source(uuid, date, date)
FROM PUBLIC;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_trip_expenses_report_source(uuid, date, date)
FROM anon;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_trip_expenses_report_source(uuid, date, date)
FROM authenticated;

GRANT EXECUTE
ON FUNCTION public.get_trip_expenses_report_source(uuid, date, date)
TO authenticated;


REVOKE ALL PRIVILEGES
ON FUNCTION public.get_trip_net_profit_report_source(uuid, date, date)
FROM PUBLIC;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_trip_net_profit_report_source(uuid, date, date)
FROM anon;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_trip_net_profit_report_source(uuid, date, date)
FROM authenticated;

GRANT EXECUTE
ON FUNCTION public.get_trip_net_profit_report_source(uuid, date, date)
TO authenticated;


REVOKE ALL PRIVILEGES
ON FUNCTION public.get_open_invoices_report_source(uuid, date, date)
FROM PUBLIC;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_open_invoices_report_source(uuid, date, date)
FROM anon;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_open_invoices_report_source(uuid, date, date)
FROM authenticated;

GRANT EXECUTE
ON FUNCTION public.get_open_invoices_report_source(uuid, date, date)
TO authenticated;

COMMIT;
