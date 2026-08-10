-- Issue #26: human-readable invoice trip snapshots and least-privilege
-- accountant access to invoice audit activity.

BEGIN;

ALTER TABLE public.invoice_lines
  ADD COLUMN IF NOT EXISTS trip_number text,
  ADD COLUMN IF NOT EXISTS loading_location text,
  ADD COLUMN IF NOT EXISTS unloading_location text;

UPDATE public.invoice_lines AS invoice_line
SET
  trip_number = NULLIF(pg_catalog.btrim(trip_row.trip_number), ''),
  loading_location = COALESCE(
    NULLIF(pg_catalog.btrim(trip_row.loading_location), ''),
    NULLIF(pg_catalog.btrim(route_row.loading_location), '')
  ),
  unloading_location = COALESCE(
    NULLIF(pg_catalog.btrim(trip_row.unloading_location), ''),
    NULLIF(pg_catalog.btrim(route_row.unloading_location), '')
  ),
  service_date = COALESCE(invoice_line.service_date, trip_row.trip_date)
FROM public.trips AS trip_row
JOIN public.routes AS route_row
  ON route_row.company_id = trip_row.company_id
 AND route_row.id = trip_row.route_id
WHERE trip_row.company_id = invoice_line.company_id
  AND trip_row.id = invoice_line.trip_id;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.invoice_lines AS invoice_line
    WHERE invoice_line.service_date IS NULL
       OR NULLIF(pg_catalog.btrim(invoice_line.loading_location), '') IS NULL
       OR NULLIF(pg_catalog.btrim(invoice_line.unloading_location), '') IS NULL
  ) THEN
    RAISE EXCEPTION
      'Invoice trip display snapshot backfill stopped: incomplete source data.';
  END IF;
END
$$;

ALTER TABLE public.invoice_lines
  ALTER COLUMN service_date SET NOT NULL,
  ALTER COLUMN loading_location SET NOT NULL,
  ALTER COLUMN unloading_location SET NOT NULL;

ALTER TABLE public.invoice_lines
  DROP CONSTRAINT IF EXISTS invoice_lines_loading_location_nonblank,
  DROP CONSTRAINT IF EXISTS invoice_lines_unloading_location_nonblank;

ALTER TABLE public.invoice_lines
  ADD CONSTRAINT invoice_lines_loading_location_nonblank
    CHECK (pg_catalog.btrim(loading_location) <> ''),
  ADD CONSTRAINT invoice_lines_unloading_location_nonblank
    CHECK (pg_catalog.btrim(unloading_location) <> '');

CREATE OR REPLACE FUNCTION private.populate_invoice_line_trip_display_snapshot()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
DECLARE
  v_trip_number text;
  v_trip_date date;
  v_loading_location text;
  v_unloading_location text;
BEGIN
  SELECT
    NULLIF(pg_catalog.btrim(trip_row.trip_number), ''),
    trip_row.trip_date,
    COALESCE(
      NULLIF(pg_catalog.btrim(trip_row.loading_location), ''),
      NULLIF(pg_catalog.btrim(route_row.loading_location), '')
    ),
    COALESCE(
      NULLIF(pg_catalog.btrim(trip_row.unloading_location), ''),
      NULLIF(pg_catalog.btrim(route_row.unloading_location), '')
    )
  INTO
    v_trip_number,
    v_trip_date,
    v_loading_location,
    v_unloading_location
  FROM public.trips AS trip_row
  JOIN public.routes AS route_row
    ON route_row.company_id = trip_row.company_id
   AND route_row.id = trip_row.route_id
  WHERE trip_row.company_id = NEW.company_id
    AND trip_row.id = NEW.trip_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2615',
      MESSAGE = 'invoice_trip_not_found';
  END IF;

  NEW.trip_number := v_trip_number;
  NEW.loading_location := v_loading_location;
  NEW.unloading_location := v_unloading_location;
  NEW.service_date := COALESCE(NEW.service_date, v_trip_date);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS populate_invoice_line_trip_display_snapshot
ON public.invoice_lines;

CREATE TRIGGER populate_invoice_line_trip_display_snapshot
BEFORE INSERT ON public.invoice_lines
FOR EACH ROW
EXECUTE FUNCTION private.populate_invoice_line_trip_display_snapshot();

REVOKE ALL ON FUNCTION private.populate_invoice_line_trip_display_snapshot()
  FROM PUBLIC;

DROP FUNCTION IF EXISTS public.get_billable_trips(uuid, uuid);

CREATE FUNCTION public.get_billable_trips(
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
  trip_number text,
  customer_name text,
  loading_location text,
  unloading_location text,
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
  FROM public.companies AS company_row
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
    NULLIF(pg_catalog.btrim(trip_row.trip_number), ''),
    customer_row.name,
    COALESCE(
      NULLIF(pg_catalog.btrim(trip_row.loading_location), ''),
      NULLIF(pg_catalog.btrim(route_row.loading_location), '')
    ),
    COALESCE(
      NULLIF(pg_catalog.btrim(trip_row.unloading_location), ''),
      NULLIF(pg_catalog.btrim(route_row.unloading_location), '')
    ),
    trip_row.loading_order_number,
    trip_row.waybill_number,
    COALESCE(
      (
        COALESCE(
          trip_row.actual_delivery_at,
          trip_row.scheduled_delivery_at
        ) AT TIME ZONE v_business_timezone
      )::date,
      trip_row.trip_date
    ),
    trip_row.quantity_tons
  FROM public.trips AS trip_row
  JOIN public.customers AS customer_row
    ON customer_row.company_id = trip_row.company_id
   AND customer_row.id = trip_row.customer_id
  JOIN public.routes AS route_row
    ON route_row.company_id = trip_row.company_id
   AND route_row.id = trip_row.route_id
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
  FROM public.companies AS company_row
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
  FROM public.trips AS trip_row
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
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = ANY(p_trip_ids)
  ORDER BY trip_row.id
  LIMIT 1;

  SELECT customer_row.*
  INTO v_customer
  FROM public.customers AS customer_row
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
        'trip_number', NULLIF(pg_catalog.btrim(trip_row.trip_number), ''),
        'customer_name', v_customer.name,
        'loading_location', COALESCE(
          NULLIF(pg_catalog.btrim(trip_row.loading_location), ''),
          NULLIF(pg_catalog.btrim(route_row.loading_location), '')
        ),
        'unloading_location', COALESCE(
          NULLIF(pg_catalog.btrim(trip_row.unloading_location), ''),
          NULLIF(pg_catalog.btrim(route_row.unloading_location), '')
        ),
        'loading_order_number', trip_row.loading_order_number,
        'waybill_number', trip_row.waybill_number,
        'service_date', COALESCE(
          (
            COALESCE(
              trip_row.actual_delivery_at,
              trip_row.scheduled_delivery_at
            ) AT TIME ZONE v_business_timezone
          )::date,
          trip_row.trip_date
        ),
        'quantity_tons', trip_row.quantity_tons
      )
      ORDER BY trip_row.created_at, trip_row.id
    ),
    '[]'::jsonb
  )
  INTO v_trips
  FROM public.trips AS trip_row
  JOIN public.routes AS route_row
    ON route_row.company_id = trip_row.company_id
   AND route_row.id = trip_row.route_id
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

DROP POLICY IF EXISTS audit_logs_select_accountant_invoices
ON public.audit_logs;

CREATE POLICY audit_logs_select_accountant_invoices
ON public.audit_logs
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY['accountant'::public.company_role]
  )
  AND module = 'invoices'
  AND entity_type = 'invoice'
  AND metadata IS NOT NULL
  AND NULLIF(pg_catalog.btrim(entity_id), '') IS NOT NULL
  AND description = metadata ->> 'audit_event'
  AND (
    (action = 'created' AND metadata ->> 'audit_event' = 'invoice_created')
    OR (action = 'updated' AND metadata ->> 'audit_event' = 'invoice_updated')
    OR (action = 'issued' AND metadata ->> 'audit_event' = 'invoice_issued')
    OR (
      action = 'cancelled'
      AND metadata ->> 'audit_event' = 'invoice_cancelled'
    )
  )
);

COMMIT;
