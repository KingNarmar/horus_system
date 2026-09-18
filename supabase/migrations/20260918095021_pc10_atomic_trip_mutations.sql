-- H.O.R.U.S System — PC-10 Trips operational hardening
-- Atomic trip mutations, temporal invariants, structured history, and audit.

ALTER TABLE public.trips
  ADD CONSTRAINT trips_scheduled_delivery_not_before_loading
  CHECK (
    scheduled_loading_at IS NULL
    OR scheduled_delivery_at IS NULL
    OR scheduled_delivery_at >= scheduled_loading_at
  ),
  ADD CONSTRAINT trips_actual_delivery_not_before_loading
  CHECK (
    actual_loading_at IS NULL
    OR actual_delivery_at IS NULL
    OR actual_delivery_at >= actual_loading_at
  );

CREATE OR REPLACE FUNCTION private.trip_current_actor_json(
  p_company_id uuid
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'user_id', company_user.user_id,
    'role', company_user.role::text,
    'display_name', COALESCE(
      NULLIF(pg_catalog.btrim(user_profile.full_name), ''),
      auth_user.email,
      company_user.user_id::text
    )
  )
  FROM public.company_users company_user
  LEFT JOIN public.user_profiles user_profile
    ON user_profile.id = company_user.user_id
  LEFT JOIN auth.users auth_user
    ON auth_user.id = company_user.user_id
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = auth.uid()
    AND company_user.is_active = true
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION private.trip_current_actor_json(uuid)
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
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'id', trip_row.id,
    'company_id', trip_row.company_id,
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
SECURITY INVOKER
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
SECURITY INVOKER
SET search_path = pg_catalog
AS $$
  SELECT COALESCE(
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

CREATE OR REPLACE FUNCTION public.create_trip_atomic(
  p_company_id uuid,
  p_customer_id uuid,
  p_route_id uuid,
  p_driver_id uuid DEFAULT NULL,
  p_tractor_head_id uuid DEFAULT NULL,
  p_trailer_id uuid DEFAULT NULL,
  p_loading_order_number text DEFAULT NULL,
  p_waybill_number text DEFAULT NULL,
  p_quantity_tons text DEFAULT NULL,
  p_agreed_freight_rate_per_ton text DEFAULT NULL,
  p_commercial_amount text DEFAULT NULL,
  p_scheduled_loading_at timestamptz DEFAULT NULL,
  p_scheduled_delivery_at timestamptz DEFAULT NULL,
  p_actual_loading_at timestamptz DEFAULT NULL,
  p_actual_delivery_at timestamptz DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor jsonb;
  v_trip_id uuid;
  v_snapshot jsonb;
  v_new_audit jsonb;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3410',
      MESSAGE = 'trip_management_permission_denied';
  END IF;

  IF (
    p_scheduled_loading_at IS NOT NULL
    AND p_scheduled_delivery_at IS NOT NULL
    AND p_scheduled_delivery_at < p_scheduled_loading_at
  ) OR (
    p_actual_loading_at IS NOT NULL
    AND p_actual_delivery_at IS NOT NULL
    AND p_actual_delivery_at < p_actual_loading_at
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3413',
      MESSAGE = 'trip_delivery_before_loading';
  END IF;

  v_actor := private.trip_current_actor_json(p_company_id);
  IF v_actor IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3410',
      MESSAGE = 'trip_management_permission_denied';
  END IF;

  INSERT INTO public.trips (
    company_id,
    customer_id,
    route_id,
    driver_id,
    tractor_head_id,
    trailer_id,
    loading_order_number,
    waybill_number,
    quantity_tons,
    agreed_freight_rate_per_ton,
    freight_price,
    scheduled_loading_at,
    scheduled_delivery_at,
    actual_loading_at,
    actual_delivery_at,
    notes,
    created_by
  )
  VALUES (
    p_company_id,
    p_customer_id,
    p_route_id,
    p_driver_id,
    p_tractor_head_id,
    p_trailer_id,
    NULLIF(pg_catalog.btrim(p_loading_order_number), ''),
    NULLIF(pg_catalog.btrim(p_waybill_number), ''),
    CASE WHEN p_quantity_tons IS NULL THEN NULL ELSE p_quantity_tons::numeric END,
    CASE
      WHEN p_agreed_freight_rate_per_ton IS NULL THEN NULL
      ELSE p_agreed_freight_rate_per_ton::numeric
    END,
    CASE
      WHEN p_commercial_amount IS NULL THEN NULL
      ELSE p_commercial_amount::numeric
    END,
    p_scheduled_loading_at,
    p_scheduled_delivery_at,
    p_actual_loading_at,
    p_actual_delivery_at,
    NULLIF(pg_catalog.btrim(p_notes), ''),
    v_actor_user_id
  )
  RETURNING id INTO v_trip_id;

  INSERT INTO public.trip_status_history (
    company_id,
    trip_id,
    old_status,
    new_status,
    changed_by,
    changed_by_name,
    changed_by_role,
    notes
  )
  VALUES (
    p_company_id,
    v_trip_id,
    NULL,
    'created'::public.trip_status,
    v_actor_user_id,
    v_actor ->> 'display_name',
    v_actor ->> 'role',
    NULL
  );

  v_snapshot := private.trip_snapshot_json(p_company_id, v_trip_id);
  v_new_audit := private.trip_audit_values(p_company_id, v_trip_id);

  PERFORM private.write_audit_event(
    p_company_id,
    'trips',
    'trip',
    v_trip_id::text,
    private.trip_entity_display_name(v_snapshot),
    'created',
    'trip_created',
    NULL,
    v_new_audit,
    NULL
  );

  RETURN v_snapshot;
END;
$$;

REVOKE ALL ON FUNCTION public.create_trip_atomic(
  uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz, text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_trip_atomic(
  uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz, text
) FROM anon;
REVOKE ALL ON FUNCTION public.create_trip_atomic(
  uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz, text
) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.create_trip_atomic(
  uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz, text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.save_trip_atomic(
  p_company_id uuid,
  p_trip_id uuid,
  p_customer_id uuid,
  p_route_id uuid,
  p_driver_id uuid DEFAULT NULL,
  p_tractor_head_id uuid DEFAULT NULL,
  p_trailer_id uuid DEFAULT NULL,
  p_loading_order_number text DEFAULT NULL,
  p_waybill_number text DEFAULT NULL,
  p_quantity_tons text DEFAULT NULL,
  p_agreed_freight_rate_per_ton text DEFAULT NULL,
  p_commercial_amount text DEFAULT NULL,
  p_scheduled_loading_at timestamptz DEFAULT NULL,
  p_scheduled_delivery_at timestamptz DEFAULT NULL,
  p_actual_loading_at timestamptz DEFAULT NULL,
  p_actual_delivery_at timestamptz DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_locked_trip_id uuid;
  v_old_audit jsonb;
  v_snapshot jsonb;
  v_new_audit jsonb;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3410',
      MESSAGE = 'trip_management_permission_denied';
  END IF;

  IF (
    p_scheduled_loading_at IS NOT NULL
    AND p_scheduled_delivery_at IS NOT NULL
    AND p_scheduled_delivery_at < p_scheduled_loading_at
  ) OR (
    p_actual_loading_at IS NOT NULL
    AND p_actual_delivery_at IS NOT NULL
    AND p_actual_delivery_at < p_actual_loading_at
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3413',
      MESSAGE = 'trip_delivery_before_loading';
  END IF;

  SELECT trip_row.id
  INTO v_locked_trip_id
  FROM public.trips trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3412',
      MESSAGE = 'trip_not_found';
  END IF;

  v_old_audit := private.trip_audit_values(p_company_id, p_trip_id);

  UPDATE public.trips
  SET
    customer_id = p_customer_id,
    route_id = p_route_id,
    driver_id = p_driver_id,
    tractor_head_id = p_tractor_head_id,
    trailer_id = p_trailer_id,
    loading_order_number = NULLIF(pg_catalog.btrim(p_loading_order_number), ''),
    waybill_number = NULLIF(pg_catalog.btrim(p_waybill_number), ''),
    quantity_tons = CASE WHEN p_quantity_tons IS NULL THEN NULL ELSE p_quantity_tons::numeric END,
    agreed_freight_rate_per_ton = CASE
      WHEN p_agreed_freight_rate_per_ton IS NULL THEN NULL
      ELSE p_agreed_freight_rate_per_ton::numeric
    END,
    freight_price = CASE
      WHEN p_commercial_amount IS NULL THEN NULL
      ELSE p_commercial_amount::numeric
    END,
    scheduled_loading_at = p_scheduled_loading_at,
    scheduled_delivery_at = p_scheduled_delivery_at,
    actual_loading_at = p_actual_loading_at,
    actual_delivery_at = p_actual_delivery_at,
    notes = NULLIF(pg_catalog.btrim(p_notes), ''),
    updated_by = v_actor_user_id
  WHERE company_id = p_company_id
    AND id = p_trip_id;

  v_snapshot := private.trip_snapshot_json(p_company_id, p_trip_id);
  v_new_audit := private.trip_audit_values(p_company_id, p_trip_id);

  PERFORM private.write_audit_event(
    p_company_id,
    'trips',
    'trip',
    p_trip_id::text,
    private.trip_entity_display_name(v_snapshot),
    'updated',
    'trip_updated',
    v_old_audit,
    v_new_audit,
    NULL
  );

  RETURN v_snapshot;
END;
$$;

REVOKE ALL ON FUNCTION public.save_trip_atomic(
  uuid, uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz, text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.save_trip_atomic(
  uuid, uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz, text
) FROM anon;
REVOKE ALL ON FUNCTION public.save_trip_atomic(
  uuid, uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz, text
) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.save_trip_atomic(
  uuid, uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz, text
) TO authenticated;

CREATE OR REPLACE FUNCTION public.update_trip_status_atomic(
  p_company_id uuid,
  p_trip_id uuid,
  p_new_status public.trip_status,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor jsonb;
  v_old_status public.trip_status;
  v_old_audit jsonb;
  v_snapshot jsonb;
  v_new_audit jsonb;
  v_notes text := NULLIF(pg_catalog.btrim(p_notes), '');
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3411',
      MESSAGE = 'trip_status_permission_denied';
  END IF;

  v_actor := private.trip_current_actor_json(p_company_id);
  IF v_actor IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3411',
      MESSAGE = 'trip_status_permission_denied';
  END IF;

  SELECT trip_row.status
  INTO v_old_status
  FROM public.trips trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3412',
      MESSAGE = 'trip_not_found';
  END IF;

  v_old_audit := private.trip_audit_values(p_company_id, p_trip_id);

  UPDATE public.trips
  SET
    status = p_new_status,
    updated_by = v_actor_user_id
  WHERE company_id = p_company_id
    AND id = p_trip_id;

  INSERT INTO public.trip_status_history (
    company_id,
    trip_id,
    old_status,
    new_status,
    changed_by,
    changed_by_name,
    changed_by_role,
    notes
  )
  VALUES (
    p_company_id,
    p_trip_id,
    v_old_status,
    p_new_status,
    v_actor_user_id,
    v_actor ->> 'display_name',
    v_actor ->> 'role',
    v_notes
  );

  v_snapshot := private.trip_snapshot_json(p_company_id, p_trip_id);
  v_new_audit := private.trip_audit_values(p_company_id, p_trip_id);

  PERFORM private.write_audit_event(
    p_company_id,
    'trips',
    'trip',
    p_trip_id::text,
    private.trip_entity_display_name(v_snapshot),
    'status_changed',
    'trip_status_changed',
    v_old_audit,
    v_new_audit,
    pg_catalog.jsonb_build_object(
      'old_status', v_old_status::text,
      'new_status', p_new_status::text,
      'notes', v_notes
    )
  );

  RETURN v_snapshot;
END;
$$;

REVOKE ALL ON FUNCTION public.update_trip_status_atomic(
  uuid, uuid, public.trip_status, text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_trip_status_atomic(
  uuid, uuid, public.trip_status, text
) FROM anon;
REVOKE ALL ON FUNCTION public.update_trip_status_atomic(
  uuid, uuid, public.trip_status, text
) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.update_trip_status_atomic(
  uuid, uuid, public.trip_status, text
) TO authenticated;
