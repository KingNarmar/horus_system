-- Issue #317 R3: tenant-private, server-owned Trips invalidation.
-- A single Trip insert or meaningful operational update invalidates the
-- Trips list, open Trip status history, and server audit read projections.
-- The notification deliberately contains no Trip fields, status or audit data.
BEGIN;

CREATE POLICY horus_trips_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:trips$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']::public.company_role[]
  )
);

-- No INSERT policy: clients cannot author trusted Trip notifications.
CREATE FUNCTION private.broadcast_trips_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF TG_OP = 'UPDATE' AND
     ROW(
       OLD.customer_id, OLD.route_id, OLD.driver_id,
       OLD.tractor_head_id, OLD.trailer_id,
       OLD.status, OLD.loading_order_number, OLD.waybill_number,
       OLD.quantity_tons, OLD.agreed_freight_rate_per_ton,
       OLD.freight_price, OLD.scheduled_loading_at,
       OLD.scheduled_delivery_at, OLD.actual_loading_at,
       OLD.actual_delivery_at, OLD.notes
     ) IS NOT DISTINCT FROM
     ROW(
       NEW.customer_id, NEW.route_id, NEW.driver_id,
       NEW.tractor_head_id, NEW.trailer_id,
       NEW.status, NEW.loading_order_number, NEW.waybill_number,
       NEW.quantity_tons, NEW.agreed_freight_rate_per_ton,
       NEW.freight_price, NEW.scheduled_loading_at,
       NEW.scheduled_delivery_at, NEW.actual_loading_at,
       NEW.actual_delivery_at, NEW.notes
     ) THEN
    RETURN NEW;
  END IF;

  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'trips'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':trips',
    true
  );
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.broadcast_trips_invalidation()
FROM PUBLIC, anon, authenticated;

CREATE TRIGGER trips_write_realtime_invalidation
AFTER INSERT OR UPDATE ON public.trips
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_trips_invalidation();

-- The legacy atomic RPC remains callable by existing clients. New clients
-- use this opt-in optimistic-concurrency wrapper to prevent silent overwrites.
-- Lock the Trip row first and check its server timestamp in the same txn.
-- The canonical save RPC still owns its validation and single audit event.
CREATE FUNCTION public.save_trip_checked_atomic(
  p_company_id uuid,
  p_trip_id uuid,
  p_customer_id uuid,
  p_route_id uuid,
  p_driver_id uuid,
  p_tractor_head_id uuid,
  p_trailer_id uuid,
  p_loading_order_number text,
  p_waybill_number text,
  p_quantity_tons text,
  p_agreed_freight_rate_per_ton text,
  p_commercial_amount text,
  p_scheduled_loading_at timestamptz,
  p_scheduled_delivery_at timestamptz,
  p_actual_loading_at timestamptz,
  p_actual_delivery_at timestamptz,
  p_notes text,
  p_expected_updated_at timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_updated_at timestamptz;
BEGIN
  IF auth.uid() IS NULL OR NOT private.has_company_role(
    p_company_id,
    ARRAY['owner', 'admin', 'operations']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3410',
      MESSAGE = 'trip_management_permission_denied';
  END IF;

  IF p_expected_updated_at IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3414',
      MESSAGE = 'trip_version_conflict';
  END IF;

  SELECT trip_row.updated_at
  INTO v_updated_at
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3412',
      MESSAGE = 'trip_not_found';
  END IF;

  IF v_updated_at IS DISTINCT FROM p_expected_updated_at THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3414',
      MESSAGE = 'trip_version_conflict';
  END IF;

  RETURN public.save_trip_atomic(
    p_company_id, p_trip_id, p_customer_id, p_route_id,
    p_driver_id, p_tractor_head_id, p_trailer_id,
    p_loading_order_number, p_waybill_number, p_quantity_tons,
    p_agreed_freight_rate_per_ton, p_commercial_amount,
    p_scheduled_loading_at, p_scheduled_delivery_at,
    p_actual_loading_at, p_actual_delivery_at, p_notes
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.save_trip_checked_atomic(
  uuid, uuid, uuid, uuid, uuid, uuid, uuid, text, text, text,
  text, text, timestamptz, timestamptz, timestamptz,
  timestamptz, text, timestamptz
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.save_trip_checked_atomic(
  uuid, uuid, uuid, uuid, uuid, uuid, uuid, text, text, text,
  text, text, timestamptz, timestamptz, timestamptz,
  timestamptz, text, timestamptz
) TO authenticated;

COMMIT;
