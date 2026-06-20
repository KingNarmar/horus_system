-- Issues #18, #19, #21 - Trips tenant-safe schema alignment.
-- This migration captures manual production fixes in source control.
-- It is intentionally idempotent and safe to run after the initial trips schema migration.

-- Legacy trips columns may exist from older schema iterations.
-- They are not written by the current Trips module and must not block inserts.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND column_name = 'trip_number'
  ) THEN
    ALTER TABLE public.trips ALTER COLUMN trip_number DROP NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND column_name = 'loading_location'
  ) THEN
    ALTER TABLE public.trips ALTER COLUMN loading_location DROP NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND column_name = 'unloading_location'
  ) THEN
    ALTER TABLE public.trips ALTER COLUMN unloading_location DROP NOT NULL;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND column_name = 'freight_price'
  ) THEN
    ALTER TABLE public.trips ALTER COLUMN freight_price DROP NOT NULL;
  END IF;
END $$;

-- Remove duplicate single-column relationship constraints.
-- Tenant-safe composite constraints below are the source of truth.
ALTER TABLE public.trips
  DROP CONSTRAINT IF EXISTS trips_customer_id_fkey,
  DROP CONSTRAINT IF EXISTS trips_route_id_fkey,
  DROP CONSTRAINT IF EXISTS trips_driver_id_fkey,
  DROP CONSTRAINT IF EXISTS trips_tractor_head_id_fkey,
  DROP CONSTRAINT IF EXISTS trips_trailer_id_fkey;

ALTER TABLE public.trip_status_history
  DROP CONSTRAINT IF EXISTS trip_status_history_trip_id_fkey;

-- Ensure composite targets exist for tenant-safe foreign keys.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'customers'
      AND constraint_name = 'customers_company_id_id_unique'
  ) THEN
    ALTER TABLE public.customers
      ADD CONSTRAINT customers_company_id_id_unique UNIQUE (company_id, id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'routes'
      AND constraint_name = 'routes_company_id_id_unique'
  ) THEN
    ALTER TABLE public.routes
      ADD CONSTRAINT routes_company_id_id_unique UNIQUE (company_id, id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'drivers'
      AND constraint_name = 'drivers_company_id_id_unique'
  ) THEN
    ALTER TABLE public.drivers
      ADD CONSTRAINT drivers_company_id_id_unique UNIQUE (company_id, id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'tractor_heads'
      AND constraint_name = 'tractor_heads_company_id_id_unique'
  ) THEN
    ALTER TABLE public.tractor_heads
      ADD CONSTRAINT tractor_heads_company_id_id_unique UNIQUE (company_id, id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trailers'
      AND constraint_name = 'trailers_company_id_id_unique'
  ) THEN
    ALTER TABLE public.trailers
      ADD CONSTRAINT trailers_company_id_id_unique UNIQUE (company_id, id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_company_id_id_unique'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_company_id_id_unique UNIQUE (company_id, id);
  END IF;
END $$;

-- Tenant-safe Trips relationships.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_company_customer_fk'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_company_customer_fk
      FOREIGN KEY (company_id, customer_id)
      REFERENCES public.customers(company_id, id)
      ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_company_route_fk'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_company_route_fk
      FOREIGN KEY (company_id, route_id)
      REFERENCES public.routes(company_id, id)
      ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_company_driver_fk'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_company_driver_fk
      FOREIGN KEY (company_id, driver_id)
      REFERENCES public.drivers(company_id, id)
      ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_company_tractor_fk'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_company_tractor_fk
      FOREIGN KEY (company_id, tractor_head_id)
      REFERENCES public.tractor_heads(company_id, id)
      ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trips'
      AND constraint_name = 'trips_company_trailer_fk'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_company_trailer_fk
      FOREIGN KEY (company_id, trailer_id)
      REFERENCES public.trailers(company_id, id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- Tenant-safe status history relationship.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trip_status_history'
      AND constraint_name = 'trip_status_history_company_trip_fk'
  ) THEN
    ALTER TABLE public.trip_status_history
      ADD CONSTRAINT trip_status_history_company_trip_fk
      FOREIGN KEY (company_id, trip_id)
      REFERENCES public.trips(company_id, id)
      ON DELETE CASCADE;
  END IF;
END $$;
