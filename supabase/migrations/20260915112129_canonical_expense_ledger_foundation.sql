-- H.O.R.U.S System — Issue #228 / PC-04
-- Canonical expense taxonomy and ledger foundation.
--
-- This migration intentionally does not migrate or retire legacy
-- trip_expenses/company_expenses. Consumer migration belongs to PC-05 and
-- legacy Trip Expense retirement belongs to PC-06.

BEGIN;

-- ---------------------------------------------------------------------------
-- Canonical taxonomy: evolve expense_types instead of creating a third
-- competing expense taxonomy.
-- ---------------------------------------------------------------------------

ALTER TABLE public.expense_types
  ADD COLUMN IF NOT EXISTS code text,
  ADD COLUMN IF NOT EXISTS ledger_eligible boolean NOT NULL DEFAULT true;

UPDATE public.expense_types
SET code = CASE pg_catalog.lower(pg_catalog.btrim(name))
  WHEN 'fuel' THEN 'fuel'
  WHEN 'road fees' THEN 'road_fees'
  WHEN 'weighbridge' THEN 'weighbridge'
  WHEN 'loading' THEN 'loading'
  WHEN 'unloading' THEN 'unloading'
  WHEN 'fines' THEN 'fines'
  WHEN 'emergency maintenance' THEN 'emergency_maintenance'
  WHEN 'other' THEN 'other'
  WHEN 'vehicle maintenance' THEN 'vehicle_maintenance'
  WHEN 'spare parts' THEN 'spare_parts'
  WHEN 'tires' THEN 'tires'
  WHEN 'oils and fluids' THEN 'oils_and_fluids'
  WHEN 'licenses and renewals' THEN 'licenses_and_renewals'
  WHEN 'office expenses' THEN 'office_expenses'
  WHEN 'rent' THEN 'rent'
  WHEN 'admin costs' THEN 'admin_costs'
  WHEN 'driver advance' THEN 'legacy_driver_advance'
  ELSE code
END
WHERE code IS NULL;

-- Driver Advance is a custody/driver-finance movement, not an Expense type.
-- Preserve the legacy row for historical references, but remove it from active
-- expense selection and reject it from the canonical ledger.
UPDATE public.expense_types
SET
  is_active = false,
  ledger_eligible = false,
  code = COALESCE(code, 'legacy_driver_advance')
WHERE pg_catalog.lower(pg_catalog.btrim(name)) = 'driver advance';

CREATE UNIQUE INDEX IF NOT EXISTS expense_types_unique_code_per_company
  ON public.expense_types (company_id, code)
  WHERE code IS NOT NULL;

WITH canonical_defaults(code, name) AS (
  VALUES
    ('fuel', 'Fuel'),
    ('road_fees', 'Road fees'),
    ('weighbridge', 'Weighbridge'),
    ('loading', 'Loading'),
    ('unloading', 'Unloading'),
    ('fines', 'Fines'),
    ('emergency_maintenance', 'Emergency maintenance'),
    ('vehicle_maintenance', 'Vehicle maintenance'),
    ('spare_parts', 'Spare parts'),
    ('tires', 'Tires'),
    ('oils_and_fluids', 'Oils and fluids'),
    ('licenses_and_renewals', 'Licenses and renewals'),
    ('office_expenses', 'Office expenses'),
    ('rent', 'Rent'),
    ('admin_costs', 'Admin costs'),
    ('other', 'Other')
)
INSERT INTO public.expense_types (
  company_id,
  code,
  name,
  is_active,
  ledger_eligible
)
SELECT
  company_row.id,
  defaults.code,
  defaults.name,
  true,
  true
FROM public.companies AS company_row
CROSS JOIN canonical_defaults AS defaults
WHERE NOT EXISTS (
  SELECT 1
  FROM public.expense_types AS existing
  WHERE existing.company_id = company_row.id
    AND (
      existing.code = defaults.code
      OR pg_catalog.lower(pg_catalog.btrim(existing.name)) =
         pg_catalog.lower(pg_catalog.btrim(defaults.name))
    )
);

CREATE OR REPLACE FUNCTION public.seed_default_expense_types_for_company()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  INSERT INTO public.expense_types (
    company_id,
    code,
    name,
    is_active,
    ledger_eligible
  )
  VALUES
    (NEW.id, 'fuel', 'Fuel', true, true),
    (NEW.id, 'road_fees', 'Road fees', true, true),
    (NEW.id, 'weighbridge', 'Weighbridge', true, true),
    (NEW.id, 'loading', 'Loading', true, true),
    (NEW.id, 'unloading', 'Unloading', true, true),
    (NEW.id, 'fines', 'Fines', true, true),
    (NEW.id, 'emergency_maintenance', 'Emergency maintenance', true, true),
    (NEW.id, 'vehicle_maintenance', 'Vehicle maintenance', true, true),
    (NEW.id, 'spare_parts', 'Spare parts', true, true),
    (NEW.id, 'tires', 'Tires', true, true),
    (NEW.id, 'oils_and_fluids', 'Oils and fluids', true, true),
    (NEW.id, 'licenses_and_renewals', 'Licenses and renewals', true, true),
    (NEW.id, 'office_expenses', 'Office expenses', true, true),
    (NEW.id, 'rent', 'Rent', true, true),
    (NEW.id, 'admin_costs', 'Admin costs', true, true),
    (NEW.id, 'other', 'Other', true, true)
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$function$;

-- Protect taxonomy-owned semantic columns from authenticated clients. Existing
-- settings flows keep name/status management; code and ledger_eligible are
-- migration/system-owned.
REVOKE INSERT, UPDATE ON TABLE public.expense_types FROM authenticated;
GRANT INSERT (company_id, name, created_by)
  ON TABLE public.expense_types TO authenticated;
GRANT UPDATE (name, is_active, updated_by)
  ON TABLE public.expense_types TO authenticated;

-- ---------------------------------------------------------------------------
-- Canonical ledger.
-- Exact money is stored as minor units + currency snapshot. Business date is
-- explicit; no device/server CURRENT_DATE default is allowed.
-- ---------------------------------------------------------------------------

CREATE TABLE public.expense_ledger_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  expense_type_id uuid NOT NULL,
  amount_minor_units bigint NOT NULL,
  currency_code text NOT NULL,
  currency_fraction_digits smallint NOT NULL,
  expense_date date NOT NULL,
  funding_source text NOT NULL DEFAULT 'company',
  trip_id uuid NULL,
  driver_id uuid NULL,
  tractor_head_id uuid NULL,
  trailer_id uuid NULL,
  reference_number text NULL,
  notes text NULL,
  origin_kind text NOT NULL DEFAULT 'manual',
  origin_id uuid NULL,
  is_voided boolean NOT NULL DEFAULT false,
  voided_at timestamptz NULL,
  voided_by uuid NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  void_reason text NULL,
  created_by uuid NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by uuid NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  updated_at timestamptz NOT NULL DEFAULT pg_catalog.now(),

  CONSTRAINT expense_ledger_entries_company_id_id_unique
    UNIQUE (company_id, id),

  CONSTRAINT expense_ledger_entries_expense_type_company_fk
    FOREIGN KEY (company_id, expense_type_id)
    REFERENCES public.expense_types(company_id, id)
    ON DELETE RESTRICT,

  CONSTRAINT expense_ledger_entries_trip_company_fk
    FOREIGN KEY (company_id, trip_id)
    REFERENCES public.trips(company_id, id)
    ON DELETE RESTRICT,

  CONSTRAINT expense_ledger_entries_driver_company_fk
    FOREIGN KEY (company_id, driver_id)
    REFERENCES public.drivers(company_id, id)
    ON DELETE RESTRICT,

  CONSTRAINT expense_ledger_entries_tractor_company_fk
    FOREIGN KEY (company_id, tractor_head_id)
    REFERENCES public.tractor_heads(company_id, id)
    ON DELETE RESTRICT,

  CONSTRAINT expense_ledger_entries_trailer_company_fk
    FOREIGN KEY (company_id, trailer_id)
    REFERENCES public.trailers(company_id, id)
    ON DELETE RESTRICT,

  CONSTRAINT expense_ledger_entries_amount_positive
    CHECK (amount_minor_units > 0),

  CONSTRAINT expense_ledger_entries_currency_code_check
    CHECK (currency_code ~ '^[A-Z]{3}$'),

  CONSTRAINT expense_ledger_entries_currency_fraction_digits_check
    CHECK (currency_fraction_digits BETWEEN 0 AND 4),

  CONSTRAINT expense_ledger_entries_funding_source_check
    CHECK (
      funding_source IN (
        'company',
        'driver_advance',
        'driver_cash',
        'customer',
        'other'
      )
    ),

  -- A trip is the canonical attribution when present. Driver/vehicle links are
  -- standalone attribution only, preventing contradictory trip + asset links.
  CONSTRAINT expense_ledger_entries_attribution_check
    CHECK (
      trip_id IS NULL
      OR (
        driver_id IS NULL
        AND tractor_head_id IS NULL
        AND trailer_id IS NULL
      )
    ),

  CONSTRAINT expense_ledger_entries_origin_check
    CHECK (
      origin_kind IN ('manual', 'legacy_trip_expense', 'legacy_company_expense')
    ),

  CONSTRAINT expense_ledger_entries_void_state_check
    CHECK (
      (
        is_voided = false
        AND voided_at IS NULL
        AND voided_by IS NULL
        AND void_reason IS NULL
      )
      OR
      (
        is_voided = true
        AND voided_at IS NOT NULL
      )
    )
);

COMMENT ON TABLE public.expense_ledger_entries IS
  'Canonical company expense ledger. Driver advances, driver charges, and driver salary/settlement movements remain separate financial concepts.';

COMMENT ON COLUMN public.expense_ledger_entries.funding_source IS
  'How an expense was funded. driver_advance means the expense consumed advance custody; the advance itself remains a Driver Finance movement.';

COMMENT ON COLUMN public.expense_ledger_entries.origin_kind IS
  'Migration provenance. PC-05 may populate legacy source kinds; live app writes use manual.';

CREATE UNIQUE INDEX expense_ledger_entries_unique_origin
  ON public.expense_ledger_entries (company_id, origin_kind, origin_id)
  WHERE origin_id IS NOT NULL;

CREATE INDEX expense_ledger_entries_company_date_idx
  ON public.expense_ledger_entries (company_id, expense_date DESC, created_at DESC);

CREATE INDEX expense_ledger_entries_type_idx
  ON public.expense_ledger_entries (company_id, expense_type_id);

CREATE INDEX expense_ledger_entries_trip_idx
  ON public.expense_ledger_entries (company_id, trip_id)
  WHERE trip_id IS NOT NULL;

CREATE INDEX expense_ledger_entries_driver_idx
  ON public.expense_ledger_entries (company_id, driver_id)
  WHERE driver_id IS NOT NULL;

CREATE INDEX expense_ledger_entries_tractor_idx
  ON public.expense_ledger_entries (company_id, tractor_head_id)
  WHERE tractor_head_id IS NOT NULL;

CREATE INDEX expense_ledger_entries_trailer_idx
  ON public.expense_ledger_entries (company_id, trailer_id)
  WHERE trailer_id IS NOT NULL;

DROP TRIGGER IF EXISTS expense_ledger_entries_set_updated_at
  ON public.expense_ledger_entries;
CREATE TRIGGER expense_ledger_entries_set_updated_at
BEFORE UPDATE ON public.expense_ledger_entries
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.expense_ledger_entries ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.expense_ledger_entries FROM PUBLIC;
REVOKE ALL ON TABLE public.expense_ledger_entries FROM anon;
REVOKE ALL ON TABLE public.expense_ledger_entries FROM authenticated;
GRANT SELECT ON TABLE public.expense_ledger_entries TO authenticated;

CREATE POLICY expense_ledger_entries_select_members
  ON public.expense_ledger_entries
  FOR SELECT
  TO authenticated
  USING (private.is_company_member(company_id));

-- ---------------------------------------------------------------------------
-- Audited mutation boundaries. No authenticated direct INSERT/UPDATE/DELETE
-- grant exists on the ledger table.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.create_expense_ledger_entry(
  p_company_id uuid,
  p_expense_type_id uuid,
  p_amount_minor_units bigint,
  p_currency_code text,
  p_currency_fraction_digits integer,
  p_expense_date date,
  p_funding_source text DEFAULT 'company',
  p_trip_id uuid DEFAULT NULL,
  p_driver_id uuid DEFAULT NULL,
  p_tractor_head_id uuid DEFAULT NULL,
  p_trailer_id uuid DEFAULT NULL,
  p_reference_number text DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS public.expense_ledger_entries
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_company public.companies%ROWTYPE;
  v_expense_type public.expense_types%ROWTYPE;
  v_entry public.expense_ledger_entries%ROWTYPE;
  v_currency_code text := pg_catalog.upper(pg_catalog.btrim(p_currency_code));
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  IF p_trip_id IS NULL THEN
    IF NOT private.has_company_role(
      p_company_id,
      ARRAY['owner', 'admin', 'accountant']::public.company_role[]
    ) THEN
      RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
    END IF;
  ELSE
    IF NOT private.has_company_role(
      p_company_id,
      ARRAY['owner', 'admin', 'operations', 'accountant']::public.company_role[]
    ) THEN
      RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
    END IF;
  END IF;

  IF p_trip_id IS NOT NULL
     AND (p_driver_id IS NOT NULL OR p_tractor_head_id IS NOT NULL OR p_trailer_id IS NOT NULL) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2802', MESSAGE = 'expense_ledger_attribution_invalid';
  END IF;

  IF p_amount_minor_units IS NULL OR p_amount_minor_units <= 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P2808', MESSAGE = 'expense_ledger_amount_invalid';
  END IF;

  IF p_funding_source IS NULL
     OR p_funding_source NOT IN ('company', 'driver_advance', 'driver_cash', 'customer', 'other') THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'expense_ledger_funding_source_invalid';
  END IF;

  SELECT company_row.*
  INTO v_company
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2806', MESSAGE = 'expense_ledger_company_not_found';
  END IF;

  IF v_company.base_currency_code IS NULL
     OR v_company.base_currency_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2804', MESSAGE = 'expense_ledger_financial_configuration_required';
  END IF;

  IF v_currency_code IS DISTINCT FROM v_company.base_currency_code
     OR p_currency_fraction_digits IS DISTINCT FROM v_company.base_currency_fraction_digits THEN
    RAISE EXCEPTION USING ERRCODE = 'P2805', MESSAGE = 'expense_ledger_currency_mismatch';
  END IF;

  SELECT expense_type_row.*
  INTO v_expense_type
  FROM public.expense_types AS expense_type_row
  WHERE expense_type_row.company_id = p_company_id
    AND expense_type_row.id = p_expense_type_id;

  IF NOT FOUND
     OR v_expense_type.is_active = false
     OR v_expense_type.ledger_eligible = false THEN
    RAISE EXCEPTION USING ERRCODE = 'P2803', MESSAGE = 'expense_ledger_expense_type_unavailable';
  END IF;

  INSERT INTO public.expense_ledger_entries (
    company_id,
    expense_type_id,
    amount_minor_units,
    currency_code,
    currency_fraction_digits,
    expense_date,
    funding_source,
    trip_id,
    driver_id,
    tractor_head_id,
    trailer_id,
    reference_number,
    notes,
    origin_kind,
    created_by
  )
  VALUES (
    p_company_id,
    p_expense_type_id,
    p_amount_minor_units,
    v_currency_code,
    p_currency_fraction_digits,
    p_expense_date,
    p_funding_source,
    p_trip_id,
    p_driver_id,
    p_tractor_head_id,
    p_trailer_id,
    NULLIF(pg_catalog.btrim(p_reference_number), ''),
    NULLIF(pg_catalog.btrim(p_notes), ''),
    'manual',
    v_actor_user_id
  )
  RETURNING * INTO v_entry;

  PERFORM private.write_audit_event(
    p_company_id,
    'expenses',
    'expense_ledger_entry',
    v_entry.id::text,
    v_expense_type.name,
    'created',
    'expense_ledger_entry_created',
    NULL,
    pg_catalog.jsonb_build_object(
      'expense_type_id', v_entry.expense_type_id,
      'amount_minor_units', v_entry.amount_minor_units,
      'currency_code', v_entry.currency_code,
      'currency_fraction_digits', v_entry.currency_fraction_digits,
      'expense_date', v_entry.expense_date,
      'funding_source', v_entry.funding_source,
      'trip_id', v_entry.trip_id,
      'driver_id', v_entry.driver_id,
      'tractor_head_id', v_entry.tractor_head_id,
      'trailer_id', v_entry.trailer_id,
      'reference_number', v_entry.reference_number,
      'notes', v_entry.notes
    ),
    pg_catalog.jsonb_build_object('source', 'expense_ledger')
  );

  RETURN v_entry;
END;
$function$;

CREATE OR REPLACE FUNCTION public.void_expense_ledger_entry(
  p_company_id uuid,
  p_expense_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS public.expense_ledger_entries
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_entry public.expense_ledger_entries%ROWTYPE;
  v_expense_type_name text;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  SELECT entry_row.*
  INTO v_entry
  FROM public.expense_ledger_entries AS entry_row
  WHERE entry_row.company_id = p_company_id
    AND entry_row.id = p_expense_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2806', MESSAGE = 'expense_ledger_not_found';
  END IF;

  IF v_entry.trip_id IS NULL
     AND NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  IF v_entry.is_voided THEN
    RAISE EXCEPTION USING ERRCODE = 'P2807', MESSAGE = 'expense_ledger_already_voided';
  END IF;

  SELECT expense_type_row.name
  INTO v_expense_type_name
  FROM public.expense_types AS expense_type_row
  WHERE expense_type_row.company_id = p_company_id
    AND expense_type_row.id = v_entry.expense_type_id;

  UPDATE public.expense_ledger_entries
  SET
    is_voided = true,
    voided_at = pg_catalog.now(),
    voided_by = v_actor_user_id,
    void_reason = NULLIF(pg_catalog.btrim(p_reason), ''),
    updated_by = v_actor_user_id
  WHERE company_id = p_company_id
    AND id = p_expense_id
  RETURNING * INTO v_entry;

  PERFORM private.write_audit_event(
    p_company_id,
    'expenses',
    'expense_ledger_entry',
    v_entry.id::text,
    v_expense_type_name,
    'voided',
    'expense_ledger_entry_voided',
    pg_catalog.jsonb_build_object('is_voided', false),
    pg_catalog.jsonb_build_object(
      'is_voided', true,
      'voided_at', v_entry.voided_at,
      'void_reason', v_entry.void_reason
    ),
    pg_catalog.jsonb_build_object('source', 'expense_ledger')
  );

  RETURN v_entry;
END;
$function$;

REVOKE ALL ON FUNCTION public.create_expense_ledger_entry(
  uuid, uuid, bigint, text, integer, date, text, uuid, uuid, uuid, uuid, text, text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_expense_ledger_entry(
  uuid, uuid, bigint, text, integer, date, text, uuid, uuid, uuid, uuid, text, text
) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_expense_ledger_entry(
  uuid, uuid, bigint, text, integer, date, text, uuid, uuid, uuid, uuid, text, text
) TO authenticated;

REVOKE ALL ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text) TO authenticated;

-- ---------------------------------------------------------------------------
-- PC-02 currency locking must recognize the new canonical financial source.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION private.company_has_currency_bound_financial_data(
  p_company_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  RETURN
    EXISTS (
      SELECT 1
      FROM public.expense_ledger_entries AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.company_expenses AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.trip_expenses AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_financial_movements AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_advances AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_deductions AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_settlements AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_settlement_items AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.invoices AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.invoice_lines AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.payments AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.trips AS row
      WHERE row.company_id = p_company_id
        AND (
          COALESCE(row.freight_price, 0::numeric) <> 0
          OR COALESCE(row.total_expenses, 0::numeric) <> 0
        )
    )
    OR EXISTS (
      SELECT 1
      FROM public.routes AS row
      WHERE row.company_id = p_company_id
        AND COALESCE(row.default_freight_price, 0::numeric) <> 0
    )
    OR EXISTS (
      SELECT 1
      FROM public.customers AS row
      WHERE row.company_id = p_company_id
        AND COALESCE(row.credit_limit, 0::numeric) <> 0
    );
END;
$function$;

COMMIT;
