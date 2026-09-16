-- Issue #232 / PC-08 - Effective-dated Driver compensation history.
--
-- Compensation is intentionally stored outside public.drivers. Historical
-- settlement snapshots remain untouched; PC-09 will consume this history for
-- future settlement alignment.

BEGIN;

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA extensions;

CREATE TABLE public.driver_compensation_revisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  driver_id uuid NOT NULL,
  amount_minor_units bigint NOT NULL,
  currency_code text NOT NULL,
  currency_fraction_digits smallint NOT NULL,
  effective_from date NOT NULL,
  effective_to date NULL,
  contract_reference text NULL,
  contract_document_reference text NULL,
  created_by uuid NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE SET NULL,
  updated_by uuid NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  updated_at timestamptz NOT NULL DEFAULT pg_catalog.now(),

  CONSTRAINT driver_compensation_revisions_company_id_id_unique
    UNIQUE (company_id, id),

  CONSTRAINT driver_compensation_revisions_driver_company_fk
    FOREIGN KEY (company_id, driver_id)
    REFERENCES public.drivers(company_id, id)
    ON DELETE RESTRICT,

  CONSTRAINT driver_compensation_revisions_amount_positive
    CHECK (amount_minor_units > 0),

  CONSTRAINT driver_compensation_revisions_currency_code_check
    CHECK (currency_code ~ '^[A-Z]{3}$'),

  CONSTRAINT driver_compensation_revisions_currency_fraction_digits_check
    CHECK (currency_fraction_digits BETWEEN 0 AND 4),

  CONSTRAINT driver_compensation_revisions_effective_period_check
    CHECK (effective_to IS NULL OR effective_to >= effective_from),

  CONSTRAINT driver_compensation_revisions_contract_reference_check
    CHECK (
      contract_reference IS NULL
      OR length(pg_catalog.btrim(contract_reference)) BETWEEN 1 AND 200
    ),

  CONSTRAINT driver_compensation_revisions_document_reference_check
    CHECK (
      contract_document_reference IS NULL
      OR (
        private.business_document_company_id(contract_document_reference)
          IS NOT NULL
        AND private.business_document_company_id(contract_document_reference)
          = company_id
        AND pg_catalog.split_part(contract_document_reference, '/', 3)
          = 'driver-compensation'
        AND pg_catalog.split_part(contract_document_reference, '/', 4)
          = id::text
        AND pg_catalog.split_part(contract_document_reference, '/', 5)
          = 'employment-contract'
      )
    ),

  CONSTRAINT driver_compensation_revisions_no_overlap
    EXCLUDE USING gist (
      company_id WITH =,
      driver_id WITH =,
      daterange(effective_from, effective_to, '[]') WITH &&
    )
);

COMMENT ON TABLE public.driver_compensation_revisions IS
  'Effective-dated Driver compensation/employment history. Compensation terms are historical records, not mutable Driver profile fields.';

COMMENT ON COLUMN public.driver_compensation_revisions.amount_minor_units IS
  'Exact compensation amount in minor units using the stored currency fraction-digit snapshot.';

COMMENT ON COLUMN public.driver_compensation_revisions.contract_document_reference IS
  'Private PC-03 business-document object reference for the signed employment contract, when attached.';

CREATE INDEX driver_compensation_revisions_driver_effective_from_idx
  ON public.driver_compensation_revisions (
    company_id,
    driver_id,
    effective_from DESC
  );

CREATE OR REPLACE FUNCTION private.guard_driver_compensation_revision_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  IF NEW.company_id IS DISTINCT FROM OLD.company_id
    OR NEW.driver_id IS DISTINCT FROM OLD.driver_id
    OR NEW.amount_minor_units IS DISTINCT FROM OLD.amount_minor_units
    OR NEW.currency_code IS DISTINCT FROM OLD.currency_code
    OR NEW.currency_fraction_digits IS DISTINCT FROM OLD.currency_fraction_digits
    OR NEW.effective_from IS DISTINCT FROM OLD.effective_from
    OR NEW.contract_reference IS DISTINCT FROM OLD.contract_reference
    OR NEW.created_by IS DISTINCT FROM OLD.created_by
    OR NEW.created_at IS DISTINCT FROM OLD.created_at
  THEN
    RAISE EXCEPTION 'driver_compensation_revision_immutable_fields'
      USING ERRCODE = '23514';
  END IF;

  IF OLD.effective_to IS NOT NULL
    AND NEW.effective_to IS DISTINCT FROM OLD.effective_to
  THEN
    RAISE EXCEPTION 'driver_compensation_revision_effective_to_immutable'
      USING ERRCODE = '23514';
  END IF;

  IF OLD.contract_document_reference IS NOT NULL
    AND NEW.contract_document_reference
      IS DISTINCT FROM OLD.contract_document_reference
  THEN
    RAISE EXCEPTION 'driver_compensation_revision_document_immutable'
      USING ERRCODE = '23514';
  END IF;

  NEW.updated_by := auth.uid();
  NEW.updated_at := pg_catalog.now();
  RETURN NEW;
END;
$function$;

REVOKE ALL
ON FUNCTION private.guard_driver_compensation_revision_update()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS driver_compensation_revisions_guard_update
  ON public.driver_compensation_revisions;
CREATE TRIGGER driver_compensation_revisions_guard_update
BEFORE UPDATE ON public.driver_compensation_revisions
FOR EACH ROW
EXECUTE FUNCTION private.guard_driver_compensation_revision_update();

ALTER TABLE public.driver_compensation_revisions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS driver_compensation_revisions_select_finance_roles
  ON public.driver_compensation_revisions;
CREATE POLICY driver_compensation_revisions_select_finance_roles
ON public.driver_compensation_revisions
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY['owner', 'admin', 'accountant']::public.company_role[]
  )
);

DROP POLICY IF EXISTS driver_compensation_revisions_insert_managers
  ON public.driver_compensation_revisions;
CREATE POLICY driver_compensation_revisions_insert_managers
ON public.driver_compensation_revisions
FOR INSERT
TO authenticated
WITH CHECK (
  private.has_company_role(
    company_id,
    ARRAY['owner', 'admin']::public.company_role[]
  )
);

DROP POLICY IF EXISTS driver_compensation_revisions_update_managers
  ON public.driver_compensation_revisions;
CREATE POLICY driver_compensation_revisions_update_managers
ON public.driver_compensation_revisions
FOR UPDATE
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY['owner', 'admin']::public.company_role[]
  )
)
WITH CHECK (
  private.has_company_role(
    company_id,
    ARRAY['owner', 'admin']::public.company_role[]
  )
);

REVOKE ALL ON TABLE public.driver_compensation_revisions FROM anon, authenticated;
GRANT SELECT ON TABLE public.driver_compensation_revisions TO authenticated;
GRANT INSERT (
  id,
  company_id,
  driver_id,
  amount_minor_units,
  currency_code,
  currency_fraction_digits,
  effective_from,
  effective_to,
  contract_reference,
  contract_document_reference
)
ON TABLE public.driver_compensation_revisions TO authenticated;
GRANT UPDATE (
  effective_to,
  contract_document_reference
)
ON TABLE public.driver_compensation_revisions TO authenticated;

DROP POLICY IF EXISTS audit_logs_select_accountant_driver_compensation
  ON public.audit_logs;
CREATE POLICY audit_logs_select_accountant_driver_compensation
ON public.audit_logs
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY['accountant']::public.company_role[]
  )
  AND module = 'drivers'
  AND entity_type = 'driver'
  AND metadata IS NOT NULL
  AND NULLIF(pg_catalog.btrim(metadata ->> 'compensation_revision_id'), '')
    IS NOT NULL
  AND entity_id = metadata ->> 'driver_id'
  AND metadata ->> 'audit_event' IN (
    'driver_compensation_revision_created',
    'driver_compensation_revision_ended',
    'driver_compensation_contract_attached'
  )
  AND description = metadata ->> 'audit_event'
);

CREATE OR REPLACE FUNCTION private.company_has_currency_bound_financial_data(
  p_company_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog'
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
      FROM public.driver_compensation_revisions AS row
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
          pg_catalog.coalesce(row.freight_price, 0::numeric) <> 0
          OR pg_catalog.coalesce(row.agreed_freight_rate_per_ton, 0::numeric) <> 0
          OR pg_catalog.coalesce(row.total_expenses, 0::numeric) <> 0
        )
    )
    OR EXISTS (
      SELECT 1
      FROM public.routes AS row
      WHERE row.company_id = p_company_id
        AND pg_catalog.coalesce(row.default_freight_price, 0::numeric) <> 0
    )
    OR EXISTS (
      SELECT 1
      FROM public.customers AS row
      WHERE row.company_id = p_company_id
        AND pg_catalog.coalesce(row.credit_limit, 0::numeric) <> 0
    );
END;
$function$;

COMMIT;
