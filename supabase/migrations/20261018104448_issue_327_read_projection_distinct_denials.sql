-- #327: separate role-projected read denial codes from Trip status denials.
-- Preserve projection, data-scoping and finance masking.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_authorized_route_records(p_company_id uuid, p_route_id uuid DEFAULT NULL::uuid, p_active_only boolean DEFAULT false)
 RETURNS SETOF jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_finance boolean;
BEGIN
  IF auth.uid() IS NULL OR NOT private.has_company_role(
    p_company_id,
    ARRAY['owner','admin','operations','accountant','viewer']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3434', MESSAGE = 'route_read_permission_denied';
  END IF;

  v_finance := private.has_company_role(
    p_company_id,
    ARRAY['owner','admin','accountant']::public.company_role[]
  );

  RETURN QUERY
  SELECT pg_catalog.jsonb_build_object(
    'id', r.id, 'company_id', r.company_id,
    'loading_location', r.loading_location,
    'unloading_location', r.unloading_location,
    'governorate_from', r.governorate_from,
    'governorate_to', r.governorate_to,
    'default_freight_price',
       CASE WHEN v_finance THEN r.default_freight_price ELSE NULL::numeric END,
    'notes', r.notes, 'is_active', r.is_active,
    'created_at', r.created_at, 'updated_at', r.updated_at
  )
  FROM public.routes r
  WHERE r.company_id = p_company_id
    AND (p_route_id IS NULL OR r.id = p_route_id)
    AND (NOT p_active_only OR r.is_active)
  ORDER BY r.loading_location, r.id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_authorized_trip_records(p_company_id uuid, p_trip_id uuid DEFAULT NULL::uuid)
 RETURNS SETOF jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_finance boolean;
BEGIN
  IF auth.uid() IS NULL OR NOT private.has_company_role(
    p_company_id,
    ARRAY['owner','admin','operations','accountant','viewer']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3433', MESSAGE = 'trip_read_permission_denied';
  END IF;

  v_finance := private.has_company_role(
    p_company_id,
    ARRAY['owner','admin','accountant']::public.company_role[]
  );

  RETURN QUERY
  SELECT pg_catalog.jsonb_build_object(
    'id', t.id, 'company_id', t.company_id, 'trip_number', t.trip_number,
    'customer_id', t.customer_id, 'route_id', t.route_id,
    'driver_id', t.driver_id, 'tractor_head_id', t.tractor_head_id,
    'trailer_id', t.trailer_id, 'status', t.status::text,
    'loading_order_number', t.loading_order_number,
    'waybill_number', t.waybill_number,
    'quantity_tons', t.quantity_tons,
    'agreed_freight_rate_per_ton',
      CASE WHEN v_finance THEN t.agreed_freight_rate_per_ton ELSE NULL::numeric END,
    'freight_price', CASE WHEN v_finance THEN t.freight_price ELSE NULL::numeric END,
    'total_expenses', CASE WHEN v_finance THEN t.total_expenses ELSE NULL::numeric END,
    'scheduled_loading_at', t.scheduled_loading_at,
    'scheduled_delivery_at', t.scheduled_delivery_at,
    'actual_loading_at', t.actual_loading_at,
    'actual_delivery_at', t.actual_delivery_at,
    'notes', t.notes,
    'customer_name', c.name,
    'route_name', CASE
      WHEN NULLIF(pg_catalog.btrim(r.loading_location), '') IS NOT NULL
        AND NULLIF(pg_catalog.btrim(r.unloading_location), '') IS NOT NULL
      THEN pg_catalog.btrim(r.loading_location) || ' -> ' ||
           pg_catalog.btrim(r.unloading_location)
      ELSE NULL END,
    'driver_name', COALESCE(NULLIF(pg_catalog.btrim(d.full_name), ''),
                            NULLIF(pg_catalog.btrim(d.name), '')),
    'tractor_head_plate_number', th.plate_number,
    'trailer_plate_number', tr.plate_number,
    'created_at', t.created_at, 'updated_at', t.updated_at
  )
  FROM public.trips t
  JOIN public.customers c ON c.company_id = t.company_id AND c.id = t.customer_id
  JOIN public.routes r ON r.company_id = t.company_id AND r.id = t.route_id
  LEFT JOIN public.drivers d ON d.company_id = t.company_id AND d.id = t.driver_id
  LEFT JOIN public.tractor_heads th
    ON th.company_id = t.company_id AND th.id = t.tractor_head_id
  LEFT JOIN public.trailers tr ON tr.company_id = t.company_id AND tr.id = t.trailer_id
  WHERE t.company_id = p_company_id
    AND (p_trip_id IS NULL OR t.id = p_trip_id)
  ORDER BY t.created_at DESC, t.id;
END;
$function$
;

COMMIT;
