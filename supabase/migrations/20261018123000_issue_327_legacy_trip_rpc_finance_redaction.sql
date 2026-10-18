-- Issue #327: sanitize legacy Trip RPC JSON responses at the server boundary.
-- Audit always gets the full snapshot via a private non-exposed function;
-- Operations and Viewer cannot receive monetary fields from create/save/status.
BEGIN;

CREATE OR REPLACE FUNCTION private.trip_full_snapshot_json(p_company_id uuid, p_trip_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
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
$function$
;

REVOKE ALL ON FUNCTION private.trip_full_snapshot_json(uuid,uuid)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.trip_snapshot_json(
  p_company_id uuid,
  p_trip_id uuid
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog
AS $body$
  WITH full_snapshot AS (
    SELECT private.trip_full_snapshot_json(p_company_id, p_trip_id) AS value
  )
  SELECT CASE
    WHEN value IS NULL THEN NULL
    WHEN private.has_company_role(
      p_company_id,
      ARRAY['owner','admin','accountant']::public.company_role[]
    ) THEN value
    ELSE value || pg_catalog.jsonb_build_object(
      'freight_price', NULL::numeric,
      'agreed_freight_rate_per_ton', NULL::numeric,
      'total_expenses', NULL::numeric
    )
  END
  FROM full_snapshot;
$body$;

REVOKE ALL ON FUNCTION private.trip_snapshot_json(uuid,uuid)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.trip_audit_values(p_company_id uuid, p_trip_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
  WITH snapshot AS (
    SELECT private.trip_full_snapshot_json(p_company_id, p_trip_id) AS value
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
$function$
;

REVOKE ALL ON FUNCTION private.trip_audit_values(uuid,uuid)
FROM PUBLIC, anon, authenticated;

COMMIT;
