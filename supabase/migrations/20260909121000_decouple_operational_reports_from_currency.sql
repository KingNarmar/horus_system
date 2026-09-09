-- H.O.R.U.S System — Issue #226 / PC-02
-- Operational reports require company timezone/date semantics, but not financial
-- currency configuration. Financial report RPCs keep their existing currency
-- readiness checks.

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

  SELECT company_row.business_timezone
  INTO v_business_timezone
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3012',
      MESSAGE = 'reports_company_not_found';
  END IF;

  IF v_business_timezone IS NULL
     OR pg_catalog.btrim(v_business_timezone) = '' THEN
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
      'base_currency_code', NULL,
      'base_currency_fraction_digits', NULL,
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

COMMIT;
