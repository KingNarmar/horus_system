-- Issue #15 - Fleet schema/RLS guard.
-- This migration is intentionally idempotent. It makes the repository self-contained
-- for the Fleet module instead of relying on manually prepared Supabase objects.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Vehicle operational status enum.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'vehicle_status') THEN
    CREATE TYPE public.vehicle_status AS ENUM (
      'available',
      'on_trip',
      'loading',
      'unloading',
      'maintenance',
      'stopped',
      'inactive'
    );
  END IF;
END $$;

ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'available';
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'on_trip';
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'loading';
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'unloading';
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'maintenance';
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'stopped';
ALTER TYPE public.vehicle_status ADD VALUE IF NOT EXISTS 'inactive';

-- Tractor heads.
CREATE TABLE IF NOT EXISTS public.tractor_heads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  plate_number text NOT NULL,
  license_expiry_date date,
  expected_fuel_consumption numeric,
  status public.vehicle_status NOT NULL DEFAULT 'available',
  notes text,
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.tractor_heads
  ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS company_id uuid,
  ADD COLUMN IF NOT EXISTS plate_number text,
  ADD COLUMN IF NOT EXISTS license_expiry_date date,
  ADD COLUMN IF NOT EXISTS expected_fuel_consumption numeric,
  ADD COLUMN IF NOT EXISTS status public.vehicle_status DEFAULT 'available',
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS created_by uuid DEFAULT auth.uid(),
  ADD COLUMN IF NOT EXISTS updated_by uuid,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE public.tractor_heads ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.tractor_heads ALTER COLUMN id SET NOT NULL;
ALTER TABLE public.tractor_heads ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.tractor_heads ALTER COLUMN plate_number SET NOT NULL;
ALTER TABLE public.tractor_heads ALTER COLUMN status SET NOT NULL;
ALTER TABLE public.tractor_heads ALTER COLUMN status SET DEFAULT 'available';
ALTER TABLE public.tractor_heads ALTER COLUMN is_active SET NOT NULL;
ALTER TABLE public.tractor_heads ALTER COLUMN is_active SET DEFAULT true;
ALTER TABLE public.tractor_heads ALTER COLUMN created_by SET DEFAULT auth.uid();
ALTER TABLE public.tractor_heads ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE public.tractor_heads ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.tractor_heads ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE public.tractor_heads ALTER COLUMN updated_at SET DEFAULT now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'tractor_heads'
      AND constraint_type = 'PRIMARY KEY'
  ) THEN
    ALTER TABLE public.tractor_heads
      ADD CONSTRAINT tractor_heads_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'tractor_heads'
      AND constraint_name = 'tractor_heads_company_id_fkey'
  ) THEN
    ALTER TABLE public.tractor_heads
      ADD CONSTRAINT tractor_heads_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS tractor_heads_unique_plate_per_company
  ON public.tractor_heads (company_id, plate_number);

-- Trailers.
CREATE TABLE IF NOT EXISTS public.trailers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  plate_number text NOT NULL,
  license_expiry_date date,
  status public.vehicle_status NOT NULL DEFAULT 'available',
  technical_notes text,
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL DEFAULT auth.uid(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.trailers
  ADD COLUMN IF NOT EXISTS id uuid DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS company_id uuid,
  ADD COLUMN IF NOT EXISTS plate_number text,
  ADD COLUMN IF NOT EXISTS license_expiry_date date,
  ADD COLUMN IF NOT EXISTS status public.vehicle_status DEFAULT 'available',
  ADD COLUMN IF NOT EXISTS technical_notes text,
  ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS created_by uuid DEFAULT auth.uid(),
  ADD COLUMN IF NOT EXISTS updated_by uuid,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

ALTER TABLE public.trailers ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE public.trailers ALTER COLUMN id SET NOT NULL;
ALTER TABLE public.trailers ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE public.trailers ALTER COLUMN plate_number SET NOT NULL;
ALTER TABLE public.trailers ALTER COLUMN status SET NOT NULL;
ALTER TABLE public.trailers ALTER COLUMN status SET DEFAULT 'available';
ALTER TABLE public.trailers ALTER COLUMN is_active SET NOT NULL;
ALTER TABLE public.trailers ALTER COLUMN is_active SET DEFAULT true;
ALTER TABLE public.trailers ALTER COLUMN created_by SET DEFAULT auth.uid();
ALTER TABLE public.trailers ALTER COLUMN created_at SET NOT NULL;
ALTER TABLE public.trailers ALTER COLUMN created_at SET DEFAULT now();
ALTER TABLE public.trailers ALTER COLUMN updated_at SET NOT NULL;
ALTER TABLE public.trailers ALTER COLUMN updated_at SET DEFAULT now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trailers'
      AND constraint_type = 'PRIMARY KEY'
  ) THEN
    ALTER TABLE public.trailers
      ADD CONSTRAINT trailers_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'trailers'
      AND constraint_name = 'trailers_company_id_fkey'
  ) THEN
    ALTER TABLE public.trailers
      ADD CONSTRAINT trailers_company_id_fkey
      FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS trailers_unique_plate_per_company
  ON public.trailers (company_id, plate_number);

-- RLS and grants.
ALTER TABLE public.tractor_heads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trailers ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE ON public.tractor_heads TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.trailers TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'tractor_heads'
      AND policyname = 'tractor_heads_select_members'
  ) THEN
    CREATE POLICY tractor_heads_select_members
      ON public.tractor_heads
      FOR SELECT
      TO authenticated
      USING (private.is_company_member(company_id));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'tractor_heads'
      AND policyname = 'tractor_heads_insert_operations'
  ) THEN
    CREATE POLICY tractor_heads_insert_operations
      ON public.tractor_heads
      FOR INSERT
      TO authenticated
      WITH CHECK (private.has_company_role(company_id, ARRAY['owner', 'admin', 'operations']));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'tractor_heads'
      AND policyname = 'tractor_heads_update_operations'
  ) THEN
    CREATE POLICY tractor_heads_update_operations
      ON public.tractor_heads
      FOR UPDATE
      TO authenticated
      USING (private.has_company_role(company_id, ARRAY['owner', 'admin', 'operations']))
      WITH CHECK (private.has_company_role(company_id, ARRAY['owner', 'admin', 'operations']));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'trailers'
      AND policyname = 'trailers_select_members'
  ) THEN
    CREATE POLICY trailers_select_members
      ON public.trailers
      FOR SELECT
      TO authenticated
      USING (private.is_company_member(company_id));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'trailers'
      AND policyname = 'trailers_insert_operations'
  ) THEN
    CREATE POLICY trailers_insert_operations
      ON public.trailers
      FOR INSERT
      TO authenticated
      WITH CHECK (private.has_company_role(company_id, ARRAY['owner', 'admin', 'operations']));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'trailers'
      AND policyname = 'trailers_update_operations'
  ) THEN
    CREATE POLICY trailers_update_operations
      ON public.trailers
      FOR UPDATE
      TO authenticated
      USING (private.has_company_role(company_id, ARRAY['owner', 'admin', 'operations']))
      WITH CHECK (private.has_company_role(company_id, ARRAY['owner', 'admin', 'operations']));
  END IF;
END $$;
