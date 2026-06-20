-- Issues #18, #19, #21 - Trips schema/RLS guard.
-- This migration is intentionally idempotent where practical.
-- Trips are company-scoped and must be protected by RLS.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Trip operational status enum.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'trip_status') THEN
    CREATE TYPE public.trip_status AS ENUM (
      'created',
      'assigned',
      'loaded',
      'on_road',
      'arrived',
      'delivered',
      'documents_received',
      'invoiced',
      'paid',
      'cancelled'
    );
  END IF;
END $$;

ALTER TYPE public.trip_status ADD VALUE IF NOT EXISTS 'created';
ALTER TYPE public.trip_status ADD VALUE IF NOT EXISTS 'assigned';
ALTER TYPE public.trip_status ADD VALUE IF NOT EXISTS 'loaded';
ALTER TYPE public.trip_status ADD VALUE IF NOT EXISTS 'on_road';
ALTER TYPE public.trip_status ADD VALUE IF NOT EXISTS 'arrived';
ALTER TYPE public.trip_status ADD VALUE IF NOT EXISTS 'delivered';
ALTER TYPE public.trip_status ADD VALUE IF NOT EXISTS 'documents_received';
ALTER TYPE public.trip_status ADD VALUE IF NOT EXISTS 'invoiced';
ALTER TYPE public.trip_status ADD VALUE IF NOT EXISTS 'paid';
ALTER TYPE public.trip_status ADD VALUE IF NOT EXISTS 'cancelled';

-- Trips.
CREATE TABLE IF NOT EXISTS public.trips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  route_id uuid NOT NULL REFERENCES public.routes(id) ON DELETE RESTRICT,
  driver_id uuid REFERENCES public.drivers(id) ON DELETE SET NULL,
  tractor_head_id uuid REFERENCES public.tractor_heads(id) ON DELETE SET NULL,
  trailer_id uuid REFERENCES public.trailers(id) ON DELETE SET NULL,
  status public.trip_status NOT NULL DEFAULT 'created',
  loading_order_number text,
  waybill_number text,
  quantity_tons numeric,
  freight_price numeric,
  total_expenses numeric NOT NULL DEFAULT 0,
  scheduled_loading_at timestamptz,
  scheduled_delivery_at timestamptz,
  actual_loading_at timestamptz,
  actual_delivery_at timestamptz,
  notes text,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.trips
  ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS company_id uuid,
  ADD COLUMN IF NOT EXISTS customer_id uuid,
  ADD COLUMN IF NOT EXISTS route_id uuid,
  ADD COLUMN IF NOT EXISTS driver_id uuid,
  ADD COLUMN IF NOT EXISTS tractor_head_id uuid,
  ADD COLUMN IF NOT EXISTS trailer_id uuid,
  ADD COLUMN IF NOT EXISTS status public.trip_status DEFAULT 'created',
  ADD COLUMN IF NOT EXISTS loading_order_number text,
  ADD COLUMN IF NOT EXISTS waybill_number text,
  ADD COLUMN IF NOT EXISTS quantity_tons numeric,
  ADD COLUMN IF NOT EXISTS freight_price numeric,
  ADD COLUMN IF NOT EXISTS total_expenses numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS scheduled_loading_at timestamptz,
  ADD COLUMN IF NOT EXISTS scheduled_delivery_at timestamptz,
  ADD COLUMN IF NOT EXISTS actual_loading_at timestamptz,
  ADD COLUMN IF NOT EXISTS actual_delivery_at timestamptz,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS created_by uuid DEFAULT auth.uid(),
  ADD COLUMN IF NOT EXISTS updated_by uuid,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE public.trips ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.trips ALTER COLUMN id SET NOT NULL;
ALTER TABLE public.trips ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.trips ALTER COLUMN customer_id SET NOT NULL;
ALTER TABLE public.trips ALTER COLUMN route_id SET NOT NULL;
ALTER TABLE public.trips ALTER COLUMN status SET NOT NULL;
ALTER TABLE public.trips ALTER COLUMN status SET DEFAULT 'created';
ALTER TABLE public.trips ALTER COLUMN total_expenses SET NOT NULL;
ALTER TABLE public.trips ALTER COLUMN total_expenses SET DEFAULT 0;
ALTER TABLE public.trips ALTER COLUMN created_by SET DEFAULT auth.uid();
ALTER TABLE public.trips ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE public.trips ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.trips ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE public.trips ALTER COLUMN updated_at SET DEFAULT now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_type = 'PRIMARY KEY'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_company_id_fkey'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_customer_id_fkey'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_customer_id_fkey
      FOREIGN KEY (customer_id) REFERENCES public.customers(id) ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_route_id_fkey'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_route_id_fkey
      FOREIGN KEY (route_id) REFERENCES public.routes(id) ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_driver_id_fkey'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_driver_id_fkey
      FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_tractor_head_id_fkey'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_tractor_head_id_fkey
      FOREIGN KEY (tractor_head_id) REFERENCES public.tractor_heads(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_trailer_id_fkey'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_trailer_id_fkey
      FOREIGN KEY (trailer_id) REFERENCES public.trailers(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS trips_company_status_idx
  ON public.trips (company_id, status);

CREATE INDEX IF NOT EXISTS trips_company_customer_idx
  ON public.trips (company_id, customer_id);

CREATE INDEX IF NOT EXISTS trips_company_driver_idx
  ON public.trips (company_id, driver_id);

CREATE INDEX IF NOT EXISTS trips_company_tractor_head_idx
  ON public.trips (company_id, tractor_head_id);

CREATE INDEX IF NOT EXISTS trips_company_trailer_idx
  ON public.trips (company_id, trailer_id);

-- Prevent duplicate open trips for the same tractor head/trailer.
CREATE UNIQUE INDEX IF NOT EXISTS trips_one_open_trip_per_tractor_head
  ON public.trips (company_id, tractor_head_id)
  WHERE tractor_head_id IS NOT NULL
    AND status IN ('created', 'assigned', 'loaded', 'on_road', 'arrived');

CREATE UNIQUE INDEX IF NOT EXISTS trips_one_open_trip_per_trailer
  ON public.trips (company_id, trailer_id)
  WHERE trailer_id IS NOT NULL
    AND status IN ('created', 'assigned', 'loaded', 'on_road', 'arrived');

-- Trip status history.
CREATE TABLE IF NOT EXISTS public.trip_status_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  trip_id uuid NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  old_status public.trip_status,
  new_status public.trip_status NOT NULL,
  changed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
  changed_by_name text,
  changed_by_role text,
  notes text,
  changed_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.trip_status_history
  ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS company_id uuid,
  ADD COLUMN IF NOT EXISTS trip_id uuid,
  ADD COLUMN IF NOT EXISTS old_status public.trip_status,
  ADD COLUMN IF NOT EXISTS new_status public.trip_status,
  ADD COLUMN IF NOT EXISTS changed_by uuid DEFAULT auth.uid(),
  ADD COLUMN IF NOT EXISTS changed_by_name text,
  ADD COLUMN IF NOT EXISTS changed_by_role text,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS changed_at timestamptz DEFAULT now();

ALTER TABLE public.trip_status_history ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.trip_status_history ALTER COLUMN id SET NOT NULL;
ALTER TABLE public.trip_status_history ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.trip_status_history ALTER COLUMN trip_id SET NOT NULL;
ALTER TABLE public.trip_status_history ALTER COLUMN new_status SET NOT NULL;
ALTER TABLE public.trip_status_history ALTER COLUMN changed_by SET DEFAULT auth.uid();
ALTER TABLE public.trip_status_history ALTER COLUMN changed_at SET NOT NULL;
ALTER TABLE public.trip_status_history ALTER COLUMN changed_at SET DEFAULT now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trip_status_history'
      AND constraint_type = 'PRIMARY KEY'
  ) THEN
    ALTER TABLE public.trip_status_history
      ADD CONSTRAINT trip_status_history_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trip_status_history'
      AND constraint_name = 'trip_status_history_company_id_fkey'
  ) THEN
    ALTER TABLE public.trip_status_history
      ADD CONSTRAINT trip_status_history_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trip_status_history'
      AND constraint_name = 'trip_status_history_trip_id_fkey'
  ) THEN
    ALTER TABLE public.trip_status_history
      ADD CONSTRAINT trip_status_history_trip_id_fkey
      FOREIGN KEY (trip_id) REFERENCES public.trips(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS trip_status_history_company_trip_idx
  ON public.trip_status_history (company_id, trip_id, changed_at DESC);

-- RLS and grants.
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_status_history ENABLE ROW LEVEL SECURITY;

REVOKE DELETE, TRUNCATE, REFERENCES, TRIGGER
ON public.trips
FROM authenticated;

REVOKE UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
ON public.trip_status_history
FROM authenticated;

GRANT SELECT, INSERT, UPDATE
ON public.trips
TO authenticated;

GRANT SELECT, INSERT
ON public.trip_status_history
TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'trips'
      AND policyname = 'trips_select_members'
  ) THEN
    CREATE POLICY trips_select_members
      ON public.trips
      FOR SELECT
      TO authenticated
      USING (private.is_company_member(company_id));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'trips'
      AND policyname = 'trips_insert_operations'
  ) THEN
    CREATE POLICY trips_insert_operations
      ON public.trips
      FOR INSERT
      TO authenticated
      WITH CHECK (private.has_company_role(company_id, ARRAY['owner', 'admin', 'operations']));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'trips'
      AND policyname = 'trips_update_operations'
  ) THEN
    CREATE POLICY trips_update_operations
      ON public.trips
      FOR UPDATE
      TO authenticated
      USING (private.has_company_role(company_id, ARRAY['owner', 'admin', 'operations']))
      WITH CHECK (private.has_company_role(company_id, ARRAY['owner', 'admin', 'operations']));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'trip_status_history'
      AND policyname = 'trip_status_history_select_members'
  ) THEN
    CREATE POLICY trip_status_history_select_members
      ON public.trip_status_history
      FOR SELECT
      TO authenticated
      USING (private.is_company_member(company_id));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'trip_status_history'
      AND policyname = 'trip_status_history_insert_operations'
  ) THEN
    CREATE POLICY trip_status_history_insert_operations
      ON public.trip_status_history
      FOR INSERT
      TO authenticated
      WITH CHECK (private.has_company_role(company_id, ARRAY['owner', 'admin', 'operations']));
  END IF;
END $$;