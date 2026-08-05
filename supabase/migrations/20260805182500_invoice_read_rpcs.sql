-- Issue #26: company-scoped read contracts for billable trips and trusted
-- invoice creation context. Financial and date conversion happens in PostgreSQL.

BEGIN;

CREATE OR REPLACE FUNCTION public.get_billable_trips(
  p_company_id uuid,
  p_customer_id uuid DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  company_id uuid,
  customer_id uuid,
  status public.trip_status,
  freight_minor_units bigint,
  currency_code text,
  is_already_invoiced boolean,
  loading_order_number text,
  waybill_number text,
  service_date date,
  quantity_tons numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
  v_business_timezone text;
BEGIN
  IF auth.uid() IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2610',
      MESSAGE = 'invoice_permission_denied';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    company_row.business_timezone
  INTO
    v_currency_code,
    v_fraction_digits,
    v_business_timezone
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2633',
      MESSAGE = 'invoice_company_not_found';
  END IF;

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL
     OR v_business_timezone IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2611',
      MESSAGE = 'company_regional_settings_not_configured';
  END IF;

  RETURN QUERY
  SELECT
    trip_row.id,
    trip_row.company_id,
    trip_row.customer_id,
    trip_row.status,
    private.invoice_freight_to_minor_units(
      trip_row.freight_price,
      v_fraction_digits
    ),
    v_currency_code,
    trip_row.invoice_id IS NOT NULL,
    trip_row.loading_order_number,
    trip_row.waybill_number,
    (
      COALESCE(
        trip_row.actual_delivery_at,
        trip_row.scheduled_delivery_at
      ) AT TIME ZONE v_business_timezone
    )::date,
    trip_row.quantity_tons
  FROM public.trips trip_row
  WHERE trip_row.company_id = p_company_id
    AND (p_customer_id IS NULL OR trip_row.customer_id = p_customer_id)
    AND trip_row.status = 'documents_received'
    AND trip_row.invoice_id IS NULL
    AND trip_row.freight_price > 0
  ORDER BY trip_row.created_at DESC, trip_row.id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_invoice_creation_context(
  p_company_id uuid,
  p_trip_ids uuid[]
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
  v_business_timezone text;
  v_customer_id uuid;
  v_customer public.customers%ROWTYPE;
  v_trip_count bigint;
  v_customer_count bigint;
  v_trips jsonb;
BEGIN
  IF auth.uid() IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2610',
      MESSAGE = 'invoice_permission_denied';
  END IF;

  IF p_trip_ids IS NULL OR pg_catalog.cardinality(p_trip_ids) = 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2624',
      MESSAGE = 'invoice_lines_required';
  END IF;

  IF pg_catalog.cardinality(p_trip_ids) <>
     (
       SELECT pg_catalog.count(DISTINCT input_trip.trip_id)
       FROM pg_catalog.unnest(p_trip_ids) AS input_trip(trip_id)
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2631',
      MESSAGE = 'invoice_duplicate_trips';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    company_row.business_timezone
  INTO
    v_currency_code,
    v_fraction_digits,
    v_business_timezone
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2633',
      MESSAGE = 'invoice_company_not_found';
  END IF;

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL
     OR v_business_timezone IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2611',
      MESSAGE = 'company_regional_settings_not_configured';
  END IF;

  SELECT
    pg_catalog.count(*),
    pg_catalog.count(DISTINCT trip_row.customer_id)
  INTO
    v_trip_count,
    v_customer_count
  FROM public.trips trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = ANY(p_trip_ids);

  IF v_trip_count <> pg_catalog.cardinality(p_trip_ids) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2615',
      MESSAGE = 'invoice_trip_not_found';
  END IF;

  IF v_customer_count <> 1 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2632',
      MESSAGE = 'invoice_customer_mismatch';
  END IF;

  SELECT trip_row.customer_id
  INTO v_customer_id
  FROM public.trips trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = ANY(p_trip_ids)
  ORDER BY trip_row.id
  LIMIT 1;

  SELECT customer_row.*
  INTO v_customer
  FROM public.customers customer_row
  WHERE customer_row.company_id = p_company_id
    AND customer_row.id = v_customer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2613',
      MESSAGE = 'invoice_customer_not_found';
  END IF;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', trip_row.id,
        'company_id', trip_row.company_id,
        'customer_id', trip_row.customer_id,
        'status', trip_row.status,
        'freight_minor_units',
          private.invoice_freight_to_minor_units(
            trip_row.freight_price,
            v_fraction_digits
          ),
        'currency_code', v_currency_code,
        'is_already_invoiced', trip_row.invoice_id IS NOT NULL,
        'loading_order_number', trip_row.loading_order_number,
        'waybill_number', trip_row.waybill_number,
        'service_date', (
          COALESCE(
            trip_row.actual_delivery_at,
            trip_row.scheduled_delivery_at
          ) AT TIME ZONE v_business_timezone
        )::date,
        'quantity_tons', trip_row.quantity_tons
      )
      ORDER BY trip_row.created_at, trip_row.id
    ),
    '[]'::jsonb
  )
  INTO v_trips
  FROM public.trips trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = ANY(p_trip_ids);

  RETURN pg_catalog.jsonb_build_object(
    'customer', pg_catalog.jsonb_build_object(
      'customer_id', v_customer.id,
      'customer_name', v_customer.name,
      'customer_tax_registration_number',
        v_customer.tax_registration_number,
      'customer_address', v_customer.address,
      'customer_city', v_customer.city,
      'customer_country', v_customer.country
    ),
    'is_customer_active', v_customer.is_active,
    'trips', v_trips
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_billable_trips(uuid, uuid)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_billable_trips(uuid, uuid)
  FROM anon;
GRANT EXECUTE ON FUNCTION public.get_billable_trips(uuid, uuid)
  TO authenticated;

REVOKE ALL ON FUNCTION public.get_invoice_creation_context(uuid, uuid[])
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_invoice_creation_context(uuid, uuid[])
  FROM anon;
GRANT EXECUTE ON FUNCTION public.get_invoice_creation_context(uuid, uuid[])
  TO authenticated;

COMMIT;
