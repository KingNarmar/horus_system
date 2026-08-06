-- Issue #26: tenant-safe invoice schema, security, shared helpers, and
-- invoice-number settings. Read and mutation RPCs are defined separately.
-- Legacy live-only invoice objects are replaced only when they contain no data.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  v_has_rows boolean;
  v_constraint record;
BEGIN
  IF pg_catalog.to_regclass('public.invoices') IS NOT NULL THEN
    EXECUTE 'SELECT EXISTS (SELECT 1 FROM public.invoices)'
      INTO v_has_rows;
    IF v_has_rows THEN
      RAISE EXCEPTION
        'Invoice replacement stopped: public.invoices contains data.';
    END IF;
  END IF;

  IF pg_catalog.to_regclass('public.invoice_trips') IS NOT NULL THEN
    EXECUTE 'SELECT EXISTS (SELECT 1 FROM public.invoice_trips)'
      INTO v_has_rows;
    IF v_has_rows THEN
      RAISE EXCEPTION
        'Invoice replacement stopped: public.invoice_trips contains data.';
    END IF;
  END IF;

  IF pg_catalog.to_regclass('public.payments') IS NOT NULL THEN
    EXECUTE 'SELECT EXISTS (SELECT 1 FROM public.payments)'
      INTO v_has_rows;
    IF v_has_rows THEN
      RAISE EXCEPTION
        'Invoice replacement stopped: public.payments contains data.';
    END IF;

    IF pg_catalog.to_regclass('public.invoices') IS NOT NULL THEN
      FOR v_constraint IN
        SELECT constraint_row.conname
        FROM pg_catalog.pg_constraint constraint_row
        WHERE constraint_row.conrelid =
              'public.payments'::pg_catalog.regclass
          AND constraint_row.confrelid =
              'public.invoices'::pg_catalog.regclass
      LOOP
        EXECUTE pg_catalog.format(
          'ALTER TABLE public.payments DROP CONSTRAINT %I',
          v_constraint.conname
        );
      END LOOP;
    END IF;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.trips trip_row
    WHERE trip_row.status IN ('invoiced', 'paid')
  ) THEN
    RAISE EXCEPTION
      'Invoice replacement stopped: existing invoiced/paid trips require an explicit data migration.';
  END IF;
END
$$;

DROP TABLE IF EXISTS public.invoice_trips;
DROP TABLE IF EXISTS public.invoices;
DROP TYPE IF EXISTS public.invoice_status;

CREATE TYPE public.invoice_status AS ENUM (
  'draft',
  'issued',
  'cancelled'
);

CREATE UNIQUE INDEX IF NOT EXISTS customers_company_id_id_uidx
  ON public.customers (company_id, id);

CREATE UNIQUE INDEX IF NOT EXISTS trips_company_id_id_uidx
  ON public.trips (company_id, id);

CREATE TABLE public.company_invoice_settings (
  company_id uuid PRIMARY KEY
    REFERENCES public.companies(id) ON DELETE CASCADE,
  invoice_prefix text NOT NULL,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
    DEFAULT auth.uid(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT company_invoice_settings_prefix_check
    CHECK (invoice_prefix ~ '^[A-Z][A-Z0-9-]{0,15}$')
);

CREATE TABLE public.invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL
    REFERENCES public.companies(id) ON DELETE CASCADE,
  customer_id uuid NOT NULL,
  status public.invoice_status NOT NULL DEFAULT 'draft',
  invoice_number text,
  currency_code text NOT NULL,
  customer_name text NOT NULL,
  customer_tax_registration_number text,
  customer_address text,
  customer_city text,
  customer_country text,
  subtotal_minor_units bigint NOT NULL,
  discount_minor_units bigint NOT NULL DEFAULT 0,
  taxable_minor_units bigint NOT NULL,
  tax_rate_basis_points integer NOT NULL DEFAULT 0,
  tax_minor_units bigint NOT NULL,
  total_minor_units bigint NOT NULL,
  issue_date date,
  due_date date,
  notes text,
  cancellation_reason text,
  issued_at timestamptz,
  issued_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  cancelled_at timestamptz,
  cancelled_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
    DEFAULT auth.uid(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT invoices_company_id_id_unique UNIQUE (company_id, id),
  CONSTRAINT invoices_company_id_currency_unique
    UNIQUE (company_id, id, currency_code),
  CONSTRAINT invoices_customer_tenant_fk
    FOREIGN KEY (company_id, customer_id)
    REFERENCES public.customers(company_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT invoices_number_format_check
    CHECK (
      invoice_number IS NULL
      OR invoice_number ~
        '^[A-Z][A-Z0-9-]{0,15}-[0-9]{4}-[0-9]{6}$'
    ),
  CONSTRAINT invoices_currency_code_check
    CHECK (currency_code ~ '^[A-Z]{3}$'),
  CONSTRAINT invoices_amounts_check
    CHECK (
      subtotal_minor_units > 0
      AND discount_minor_units >= 0
      AND discount_minor_units <= subtotal_minor_units
      AND taxable_minor_units =
          subtotal_minor_units - discount_minor_units
      AND tax_rate_basis_points BETWEEN 0 AND 10000
      AND tax_minor_units >= 0
      AND total_minor_units = taxable_minor_units + tax_minor_units
      AND total_minor_units > 0
    ),
  CONSTRAINT invoices_due_date_check
    CHECK (
      issue_date IS NULL
      OR due_date IS NULL
      OR due_date >= issue_date
    ),
  CONSTRAINT invoices_status_state_check
    CHECK (
      (
        status = 'draft'
        AND invoice_number IS NULL
        AND issued_at IS NULL
        AND issued_by IS NULL
        AND cancelled_at IS NULL
        AND cancelled_by IS NULL
        AND cancellation_reason IS NULL
      )
      OR
      (
        status = 'issued'
        AND invoice_number IS NOT NULL
        AND issue_date IS NOT NULL
        AND due_date IS NOT NULL
        AND issued_at IS NOT NULL
        AND issued_by IS NOT NULL
        AND cancelled_at IS NULL
        AND cancelled_by IS NULL
        AND cancellation_reason IS NULL
      )
      OR
      (
        status = 'cancelled'
        AND cancelled_at IS NOT NULL
        AND cancelled_by IS NOT NULL
        AND pg_catalog.btrim(cancellation_reason) <> ''
      )
    )
);

CREATE UNIQUE INDEX invoices_company_number_uidx
  ON public.invoices (company_id, invoice_number)
  WHERE invoice_number IS NOT NULL;

CREATE INDEX invoices_company_status_created_idx
  ON public.invoices (company_id, status, created_at DESC);

CREATE INDEX invoices_company_customer_created_idx
  ON public.invoices (company_id, customer_id, created_at DESC);

CREATE TABLE public.invoice_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL,
  invoice_id uuid NOT NULL,
  trip_id uuid NOT NULL,
  line_position integer NOT NULL,
  loading_order_number text,
  waybill_number text,
  service_date date,
  quantity_tons numeric,
  amount_minor_units bigint NOT NULL,
  currency_code text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT invoice_lines_invoice_currency_tenant_fk
    FOREIGN KEY (company_id, invoice_id, currency_code)
    REFERENCES public.invoices(company_id, id, currency_code)
    ON DELETE CASCADE,
  CONSTRAINT invoice_lines_trip_tenant_fk
    FOREIGN KEY (company_id, trip_id)
    REFERENCES public.trips(company_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT invoice_lines_position_check CHECK (line_position > 0),
  CONSTRAINT invoice_lines_amount_check CHECK (amount_minor_units > 0),
  CONSTRAINT invoice_lines_currency_check
    CHECK (currency_code ~ '^[A-Z]{3}$'),
  CONSTRAINT invoice_lines_invoice_position_unique
    UNIQUE (invoice_id, line_position),
  CONSTRAINT invoice_lines_invoice_trip_unique
    UNIQUE (invoice_id, trip_id)
);

CREATE INDEX invoice_lines_company_invoice_idx
  ON public.invoice_lines (company_id, invoice_id, line_position);

CREATE INDEX invoice_lines_company_trip_idx
  ON public.invoice_lines (company_id, trip_id);

CREATE TABLE public.invoice_sequences (
  company_id uuid NOT NULL
    REFERENCES public.companies(id) ON DELETE CASCADE,
  invoice_year integer NOT NULL,
  last_value bigint NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (company_id, invoice_year),
  CONSTRAINT invoice_sequences_year_check
    CHECK (invoice_year BETWEEN 2000 AND 9999),
  CONSTRAINT invoice_sequences_value_check CHECK (last_value >= 0)
);

ALTER TABLE public.trips
  ADD COLUMN IF NOT EXISTS invoice_id uuid;

ALTER TABLE public.trips
  ADD CONSTRAINT trips_invoice_tenant_fk
  FOREIGN KEY (company_id, invoice_id)
  REFERENCES public.invoices(company_id, id)
  ON DELETE RESTRICT;

ALTER TABLE public.trips
  ADD CONSTRAINT trips_invoice_status_link_check
  CHECK (
    (
      status IN ('invoiced', 'paid')
      AND invoice_id IS NOT NULL
    )
    OR
    (
      status NOT IN ('invoiced', 'paid')
      AND invoice_id IS NULL
    )
  );

CREATE INDEX IF NOT EXISTS trips_company_invoice_idx
  ON public.trips (company_id, invoice_id)
  WHERE invoice_id IS NOT NULL;

CREATE OR REPLACE FUNCTION private.guard_trip_invoice_link()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $$
BEGIN
  -- SECURITY DEFINER invoice lifecycle RPCs execute as their PostgreSQL owner.
  -- Direct authenticated writes execute as authenticated and are rejected.
  IF OLD.invoice_id IS DISTINCT FROM NEW.invoice_id
     AND CURRENT_USER NOT IN ('postgres', 'service_role') THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2610',
      MESSAGE = 'invoice_permission_denied';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS guard_trip_invoice_link ON public.trips;
CREATE TRIGGER guard_trip_invoice_link
BEFORE UPDATE OF invoice_id ON public.trips
FOR EACH ROW
EXECUTE FUNCTION private.guard_trip_invoice_link();

ALTER TABLE public.company_invoice_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_sequences ENABLE ROW LEVEL SECURITY;

CREATE POLICY company_invoice_settings_select
ON public.company_invoice_settings
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']
      ::public.company_role[]
  )
);

CREATE POLICY invoices_select
ON public.invoices
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']
      ::public.company_role[]
  )
);

CREATE POLICY invoice_lines_select
ON public.invoice_lines
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']
      ::public.company_role[]
  )
);

REVOKE ALL ON TABLE public.company_invoice_settings
  FROM anon, authenticated;
REVOKE ALL ON TABLE public.invoices FROM anon, authenticated;
REVOKE ALL ON TABLE public.invoice_lines FROM anon, authenticated;
REVOKE ALL ON TABLE public.invoice_sequences FROM anon, authenticated;

GRANT SELECT ON TABLE public.company_invoice_settings TO authenticated;
GRANT SELECT ON TABLE public.invoices TO authenticated;
GRANT SELECT ON TABLE public.invoice_lines TO authenticated;

CREATE OR REPLACE FUNCTION private.invoice_freight_to_minor_units(
  p_amount numeric,
  p_fraction_digits smallint
)
RETURNS bigint
LANGUAGE plpgsql
IMMUTABLE
STRICT
SET search_path = pg_catalog
AS $$
DECLARE
  v_scaled numeric;
BEGIN
  IF p_amount <= 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2616',
      MESSAGE = 'invoice_trip_not_billable';
  END IF;

  IF p_fraction_digits NOT BETWEEN 0 AND 4 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2621',
      MESSAGE = 'invoice_freight_precision_invalid';
  END IF;

  v_scaled := p_amount * pg_catalog.power(10::numeric, p_fraction_digits);

  IF v_scaled <> pg_catalog.trunc(v_scaled)
     OR v_scaled > 9223372036854775807::numeric THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2621',
      MESSAGE = 'invoice_freight_precision_invalid';
  END IF;

  RETURN v_scaled::bigint;
END;
$$;

CREATE OR REPLACE FUNCTION private.invoice_tax_minor_units(
  p_taxable_minor_units bigint,
  p_tax_rate_basis_points integer
)
RETURNS bigint
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = pg_catalog
AS $$
  SELECT pg_catalog.trunc(
    (
      p_taxable_minor_units::numeric * p_tax_rate_basis_points
      + 5000
    ) / 10000
  )::bigint;
$$;

CREATE OR REPLACE FUNCTION private.write_invoice_audit_event(
  p_company_id uuid,
  p_module text,
  p_entity_type text,
  p_entity_id text,
  p_entity_display_name text,
  p_action text,
  p_audit_event text,
  p_old_values jsonb,
  p_new_values jsonb,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role text;
  v_actor_display_name text;
  v_actor_email text;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2610',
      MESSAGE = 'invoice_permission_denied';
  END IF;

  SELECT
    company_user.role::text,
    COALESCE(
      NULLIF(pg_catalog.btrim(user_profile.full_name), ''),
      auth_user.email,
      v_actor_user_id::text
    ),
    auth_user.email
  INTO
    v_actor_role,
    v_actor_display_name,
    v_actor_email
  FROM public.company_users company_user
  LEFT JOIN public.user_profiles user_profile
    ON user_profile.id = company_user.user_id
  LEFT JOIN auth.users auth_user
    ON auth_user.id = company_user.user_id
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2610',
      MESSAGE = 'invoice_permission_denied';
  END IF;

  INSERT INTO public.audit_logs (
    company_id,
    actor_user_id,
    actor_role,
    actor_display_name,
    actor_email,
    module,
    entity_type,
    entity_id,
    entity_display_name,
    action,
    description,
    old_values,
    new_values,
    metadata
  )
  VALUES (
    p_company_id,
    v_actor_user_id,
    v_actor_role,
    v_actor_display_name,
    v_actor_email,
    p_module,
    p_entity_type,
    p_entity_id,
    p_entity_display_name,
    p_action,
    p_audit_event,
    p_old_values,
    p_new_values,
    COALESCE(p_metadata, '{}'::jsonb)
      || pg_catalog.jsonb_build_object('audit_event', p_audit_event)
  );
END;
$$;

REVOKE ALL ON FUNCTION private.guard_trip_invoice_link() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.invoice_freight_to_minor_units(numeric, smallint)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION private.invoice_tax_minor_units(bigint, integer)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION private.write_invoice_audit_event(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text,
  jsonb,
  jsonb,
  jsonb
) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.update_company_invoice_settings(
  p_company_id uuid,
  p_invoice_prefix text
)
RETURNS public.company_invoice_settings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_prefix text := pg_catalog.upper(pg_catalog.btrim(p_invoice_prefix));
  v_old_prefix text;
  v_settings public.company_invoice_settings%ROWTYPE;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2610',
      MESSAGE = 'invoice_permission_denied';
  END IF;

  IF v_prefix IS NULL
     OR v_prefix !~ '^[A-Z][A-Z0-9-]{0,15}$' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2634',
      MESSAGE = 'invoice_prefix_invalid';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.companies company_row
    WHERE company_row.id = p_company_id
      AND company_row.is_active = true
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2633',
      MESSAGE = 'invoice_company_not_found';
  END IF;

  SELECT settings_row.invoice_prefix
  INTO v_old_prefix
  FROM public.company_invoice_settings settings_row
  WHERE settings_row.company_id = p_company_id
  FOR UPDATE;

  INSERT INTO public.company_invoice_settings (
    company_id,
    invoice_prefix,
    created_by,
    updated_by
  )
  VALUES (
    p_company_id,
    v_prefix,
    v_actor_user_id,
    v_actor_user_id
  )
  ON CONFLICT (company_id) DO UPDATE
  SET
    invoice_prefix = EXCLUDED.invoice_prefix,
    updated_by = v_actor_user_id,
    updated_at = pg_catalog.now()
  RETURNING * INTO v_settings;

  PERFORM private.write_invoice_audit_event(
    p_company_id,
    'invoices',
    'company_settings',
    p_company_id::text,
    v_settings.invoice_prefix,
    'updated',
    'invoice_settings_updated',
    pg_catalog.jsonb_build_object('invoice_prefix', v_old_prefix),
    pg_catalog.jsonb_build_object(
      'invoice_prefix',
      v_settings.invoice_prefix
    )
  );

  RETURN v_settings;
END;
$$;

REVOKE ALL ON FUNCTION public.update_company_invoice_settings(uuid, text)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_company_invoice_settings(uuid, text)
  FROM anon;
GRANT EXECUTE ON FUNCTION public.update_company_invoice_settings(uuid, text)
  TO authenticated;

DO $$
BEGIN
  IF pg_catalog.to_regclass('public.payments') IS NOT NULL
     AND EXISTS (
       SELECT 1
       FROM information_schema.columns
       WHERE table_schema = 'public'
         AND table_name = 'payments'
         AND column_name = 'company_id'
     )
     AND EXISTS (
       SELECT 1
       FROM information_schema.columns
       WHERE table_schema = 'public'
         AND table_name = 'payments'
         AND column_name = 'invoice_id'
     )
     AND NOT EXISTS (
       SELECT 1
       FROM pg_catalog.pg_constraint
       WHERE conname = 'payments_invoice_tenant_fk'
         AND conrelid = 'public.payments'::pg_catalog.regclass
     ) THEN
    ALTER TABLE public.payments
      ADD CONSTRAINT payments_invoice_tenant_fk
      FOREIGN KEY (company_id, invoice_id)
      REFERENCES public.invoices(company_id, id)
      ON DELETE RESTRICT;
  END IF;
END
$$;

DO $$
BEGIN
  IF pg_catalog.to_regclass('public.payments') IS NOT NULL
     AND EXISTS (
       SELECT 1
       FROM information_schema.columns
       WHERE table_schema = 'public'
         AND table_name = 'payments'
         AND column_name = 'company_id'
     )
     AND EXISTS (
       SELECT 1
       FROM information_schema.columns
       WHERE table_schema = 'public'
         AND table_name = 'payments'
         AND column_name = 'invoice_id'
     ) THEN
    EXECUTE
      'CREATE INDEX IF NOT EXISTS payments_company_invoice_idx '
      'ON public.payments (company_id, invoice_id)';
  END IF;
END
$$;

COMMIT;
