-- H.O.R.U.S System — Issue #268
-- Canonical human-readable Trip references.
--
-- Goals:
-- - server-generated, tenant-scoped, concurrency-safe Trip references
-- - deterministic historical backfill
-- - immutable Trip identity after creation
-- - canonical Trip references propagated to snapshots/audit/invoice-line snapshots
--
-- Format:
-- TRP-YYYY-000001
--
-- The year is derived from the active company's configured IANA business
-- timezone at server time. The client never generates Trip references.

BEGIN;

ALTER TABLE public.trips
  ADD COLUMN IF NOT EXISTS trip_number text;

CREATE TABLE IF NOT EXISTS public.trip_sequences (
  company_id uuid NOT NULL
    REFERENCES public.companies(id) ON DELETE CASCADE,
  trip_year integer NOT NULL,
  last_value bigint NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  PRIMARY KEY (company_id, trip_year),
  CONSTRAINT trip_sequences_year_check
    CHECK (trip_year BETWEEN 2000 AND 9999),
  CONSTRAINT trip_sequences_value_check
    CHECK (last_value >= 0)
);

ALTER TABLE public.trip_sequences ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.trip_sequences FROM PUBLIC, anon, authenticated;

UPDATE public.trips
SET trip_number = NULL
WHERE trip_number IS NOT NULL
  AND pg_catalog.btrim(trip_number) = '';

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.trips trip_row
    WHERE trip_row.trip_number IS NOT NULL
      AND trip_row.trip_number !~ '^TRP-[0-9]{4}-[0-9]{6}$'
  ) THEN
    RAISE EXCEPTION
      'Trip reference backfill stopped: non-canonical existing trip_number values found.';
  END IF;
END
$$;

WITH existing_max AS (
  SELECT
    trip_row.company_id,
    pg_catalog.substr(trip_row.trip_number, 5, 4)::integer AS trip_year,
    pg_catalog.max(
      pg_catalog.right(trip_row.trip_number, 6)::bigint
    ) AS max_sequence
  FROM public.trips trip_row
  WHERE trip_row.trip_number IS NOT NULL
  GROUP BY
    trip_row.company_id,
    pg_catalog.substr(trip_row.trip_number, 5, 4)::integer
),
ranked_missing AS (
  SELECT
    trip_row.id,
    trip_row.company_id,
    pg_catalog.date_part('year', trip_row.trip_date)::integer AS trip_year,
    row_number() OVER (
      PARTITION BY
        trip_row.company_id,
        pg_catalog.date_part('year', trip_row.trip_date)::integer
      ORDER BY
        trip_row.trip_date,
        trip_row.created_at,
        trip_row.id
    ) AS sequence_offset
  FROM public.trips trip_row
  WHERE trip_row.trip_number IS NULL
),
numbered_missing AS (
  SELECT
    ranked.id,
    ranked.company_id,
    ranked.trip_year,
    (
      COALESCE(existing.max_sequence, 0)
      + ranked.sequence_offset
    )::bigint AS sequence_value
  FROM ranked_missing ranked
  LEFT JOIN existing_max existing
    ON existing.company_id = ranked.company_id
   AND existing.trip_year = ranked.trip_year
)
UPDATE public.trips trip_row
SET trip_number =
  'TRP-'
  || numbered.trip_year::text
  || '-'
  || pg_catalog.lpad(numbered.sequence_value::text, 6, '0')
FROM numbered_missing numbered
WHERE trip_row.id = numbered.id
  AND trip_row.company_id = numbered.company_id;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.trips trip_row
    WHERE trip_row.trip_number IS NULL
       OR trip_row.trip_number !~ '^TRP-[0-9]{4}-[0-9]{6}$'
       OR pg_catalog.right(trip_row.trip_number, 6)::bigint > 999999
  ) THEN
    RAISE EXCEPTION
      'Trip reference backfill stopped: incomplete or invalid canonical references.';
  END IF;
END
$$;

INSERT INTO public.trip_sequences AS sequence_row (
  company_id,
  trip_year,
  last_value,
  updated_at
)
SELECT
  trip_row.company_id,
  pg_catalog.substr(trip_row.trip_number, 5, 4)::integer,
  pg_catalog.max(pg_catalog.right(trip_row.trip_number, 6)::bigint),
  pg_catalog.now()
FROM public.trips trip_row
GROUP BY
  trip_row.company_id,
  pg_catalog.substr(trip_row.trip_number, 5, 4)::integer
ON CONFLICT (company_id, trip_year) DO UPDATE
SET
  last_value = GREATEST(sequence_row.last_value, EXCLUDED.last_value),
  updated_at = pg_catalog.now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint constraint_row
    WHERE constraint_row.conrelid = 'public.trips'::pg_catalog.regclass
      AND constraint_row.conname = 'trips_unique_number_per_company'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_unique_number_per_company
      UNIQUE (company_id, trip_number);
  END IF;
END
$$;

ALTER TABLE public.trips
  DROP CONSTRAINT IF EXISTS trips_trip_number_format_check;

ALTER TABLE public.trips
  ADD CONSTRAINT trips_trip_number_format_check
  CHECK (trip_number ~ '^TRP-[0-9]{4}-[0-9]{6}$');

ALTER TABLE public.trips
  ALTER COLUMN trip_number SET NOT NULL;

CREATE OR REPLACE FUNCTION private.next_trip_number(
  p_company_id uuid
)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_business_timezone text;
  v_trip_year integer;
  v_sequence_value bigint;
BEGIN
  SELECT company_row.business_timezone
  INTO v_business_timezone
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND
     OR v_business_timezone IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM pg_catalog.pg_timezone_names timezone_entry
       WHERE timezone_entry.name = v_business_timezone
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3427',
      MESSAGE = 'trip_reference_generation_failed';
  END IF;

  v_trip_year := pg_catalog.date_part(
    'year',
    pg_catalog.now() AT TIME ZONE v_business_timezone
  )::integer;

  INSERT INTO public.trip_sequences AS sequence_row (
    company_id,
    trip_year,
    last_value,
    updated_at
  )
  VALUES (
    p_company_id,
    v_trip_year,
    1,
    pg_catalog.now()
  )
  ON CONFLICT (company_id, trip_year) DO UPDATE
  SET
    last_value = sequence_row.last_value + 1,
    updated_at = pg_catalog.now()
  RETURNING last_value INTO v_sequence_value;

  IF v_sequence_value > 999999 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3427',
      MESSAGE = 'trip_reference_generation_failed';
  END IF;

  RETURN
    'TRP-'
    || v_trip_year::text
    || '-'
    || pg_catalog.lpad(v_sequence_value::text, 6, '0');
END;
$$;

REVOKE ALL ON FUNCTION private.next_trip_number(uuid)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.assign_trip_number()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
  IF NEW.trip_number IS NOT NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3428',
      MESSAGE = 'trip_reference_server_owned';
  END IF;

  NEW.trip_number := private.next_trip_number(NEW.company_id);
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.assign_trip_number()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trips_assign_trip_number
ON public.trips;

CREATE TRIGGER trips_assign_trip_number
BEFORE INSERT ON public.trips
FOR EACH ROW
EXECUTE FUNCTION private.assign_trip_number();

CREATE OR REPLACE FUNCTION private.guard_trip_number_immutable()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
BEGIN
  IF NEW.trip_number IS DISTINCT FROM OLD.trip_number THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3428',
      MESSAGE = 'trip_reference_server_owned';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.guard_trip_number_immutable()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trips_guard_trip_number_immutable
ON public.trips;

CREATE TRIGGER trips_guard_trip_number_immutable
BEFORE UPDATE OF trip_number ON public.trips
FOR EACH ROW
EXECUTE FUNCTION private.guard_trip_number_immutable();

CREATE OR REPLACE FUNCTION private.trip_snapshot_json(
  p_company_id uuid,
  p_trip_id uuid
)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = pg_catalog
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'id', trip_row.id,
    'company_id', trip_row.company_id,
    'trip_number', trip_row.trip_number,
    'customer_id', trip_row.customer_id,
    'route_id', trip_row.route_id,
    'driver_id', trip_row.driver_id,
    'tractor_head_id', trip_row.tractor_head_id,
    'trailer_id', trip_row.trailer_id,
    'status', trip_row.status::text,
    'loading_order_number', trip_row.loading_order_number,
    'waybill_number', trip_row.waybill_number,
    'quantity_tons', trip_row.quantity_tons,
    'agreed_freight_rate_per_ton', trip_row.agreed_freight_rate_per_ton,
    'freight_price', trip_row.freight_price,
    'total_expenses', trip_row.total_expenses,
    'scheduled_loading_at', trip_row.scheduled_loading_at,
    'scheduled_delivery_at', trip_row.scheduled_delivery_at,
    'actual_loading_at', trip_row.actual_loading_at,
    'actual_delivery_at', trip_row.actual_delivery_at,
    'notes', trip_row.notes,
    'customer_name', customer_row.name,
    'route_name', CASE
      WHEN NULLIF(pg_catalog.btrim(route_row.loading_location), '') IS NOT NULL
        AND NULLIF(pg_catalog.btrim(route_row.unloading_location), '') IS NOT NULL
      THEN
        pg_catalog.btrim(route_row.loading_location)
        || ' -> '
        || pg_catalog.btrim(route_row.unloading_location)
      ELSE NULL
    END,
    'driver_name', COALESCE(
      NULLIF(pg_catalog.btrim(driver_row.full_name), ''),
      NULLIF(pg_catalog.btrim(driver_row.name), '')
    ),
    'tractor_head_plate_number', tractor_row.plate_number,
    'trailer_plate_number', trailer_row.plate_number,
    'created_at', trip_row.created_at,
    'updated_at', trip_row.updated_at
  )
  FROM public.trips trip_row
  JOIN public.customers customer_row
    ON customer_row.company_id = trip_row.company_id
   AND customer_row.id = trip_row.customer_id
  JOIN public.routes route_row
    ON route_row.company_id = trip_row.company_id
   AND route_row.id = trip_row.route_id
  LEFT JOIN public.drivers driver_row
    ON driver_row.company_id = trip_row.company_id
   AND driver_row.id = trip_row.driver_id
  LEFT JOIN public.tractor_heads tractor_row
    ON tractor_row.company_id = trip_row.company_id
   AND tractor_row.id = trip_row.tractor_head_id
  LEFT JOIN public.trailers trailer_row
    ON trailer_row.company_id = trip_row.company_id
   AND trailer_row.id = trip_row.trailer_id
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = p_trip_id;
$$;

REVOKE ALL ON FUNCTION private.trip_snapshot_json(uuid, uuid)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.trip_audit_values(
  p_company_id uuid,
  p_trip_id uuid
)
RETURNS jsonb
LANGUAGE sql
STABLE
SET search_path = pg_catalog
AS $$
  WITH snapshot AS (
    SELECT private.trip_snapshot_json(p_company_id, p_trip_id) AS value
  )
  SELECT CASE
    WHEN value IS NULL THEN NULL
    ELSE pg_catalog.jsonb_build_object(
      'id', value -> 'id',
      'company_id', value -> 'company_id',
      'trip_number', value -> 'trip_number',
      'customer_id', value -> 'customer_id',
      'route_id', value -> 'route_id',
      'driver_id', value -> 'driver_id',
      'tractor_head_id', value -> 'tractor_head_id',
      'trailer_id', value -> 'trailer_id',
      'status', value -> 'status',
      'loading_order_number', value -> 'loading_order_number',
      'waybill_number', value -> 'waybill_number',
      'quantity_tons', value -> 'quantity_tons',
      'agreed_freight_rate_per_ton', value -> 'agreed_freight_rate_per_ton',
      'commercial_amount', value -> 'freight_price',
      'total_expenses', value -> 'total_expenses',
      'scheduled_loading_at', value -> 'scheduled_loading_at',
      'scheduled_delivery_at', value -> 'scheduled_delivery_at',
      'actual_loading_at', value -> 'actual_loading_at',
      'actual_delivery_at', value -> 'actual_delivery_at',
      'notes', value -> 'notes',
      'customer_name', value -> 'customer_name',
      'route_name', value -> 'route_name',
      'driver_name', value -> 'driver_name',
      'tractor_head_plate_number', value -> 'tractor_head_plate_number',
      'trailer_plate_number', value -> 'trailer_plate_number',
      'created_at', value -> 'created_at',
      'updated_at', value -> 'updated_at'
    )
  END
  FROM snapshot;
$$;

REVOKE ALL ON FUNCTION private.trip_audit_values(uuid, uuid)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.trip_entity_display_name(
  p_snapshot jsonb
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog
AS $$
  SELECT COALESCE(
    NULLIF(pg_catalog.btrim(p_snapshot ->> 'trip_number'), ''),
    NULLIF(pg_catalog.btrim(p_snapshot ->> 'loading_order_number'), ''),
    NULLIF(pg_catalog.btrim(p_snapshot ->> 'waybill_number'), ''),
    CASE
      WHEN NULLIF(pg_catalog.btrim(p_snapshot ->> 'customer_name'), '') IS NOT NULL
        AND NULLIF(pg_catalog.btrim(p_snapshot ->> 'route_name'), '') IS NOT NULL
      THEN
        pg_catalog.btrim(p_snapshot ->> 'customer_name')
        || ' - '
        || pg_catalog.btrim(p_snapshot ->> 'route_name')
      ELSE NULL
    END,
    p_snapshot ->> 'id'
  );
$$;

REVOKE ALL ON FUNCTION private.trip_entity_display_name(jsonb)
FROM PUBLIC, anon, authenticated;

UPDATE public.invoice_lines invoice_line
SET trip_number = trip_row.trip_number
FROM public.trips trip_row
WHERE trip_row.company_id = invoice_line.company_id
  AND trip_row.id = invoice_line.trip_id
  AND (
    invoice_line.trip_number IS NULL
    OR pg_catalog.btrim(invoice_line.trip_number) = ''
  );

COMMIT;
