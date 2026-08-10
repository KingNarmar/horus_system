-- H.O.R.U.S System — Issue #27 Payments module
--
-- Replaces the unused legacy payments shape with the canonical minor-unit
-- contract and applies least-privilege company-scoped read access. Audit and
-- lifecycle RPCs are defined in focused follow-up migrations.

BEGIN;

DO $$
BEGIN
  IF pg_catalog.to_regclass('public.payments') IS NULL THEN
    RAISE EXCEPTION 'Payments migration stopped: public.payments is missing.';
  END IF;

  IF EXISTS (SELECT 1 FROM public.payments LIMIT 1) THEN
    RAISE EXCEPTION
      'Payments migration stopped: public.payments contains legacy data and requires an explicit data migration.';
  END IF;
END
$$;

-- The legacy table is empty and unused. Align money storage with the shared
-- Money value object and make invoice/method links mandatory for Issue #27.
DROP TRIGGER IF EXISTS payments_set_updated_at ON public.payments;

ALTER TABLE public.payments
  DROP CONSTRAINT IF EXISTS payments_amount_positive,
  DROP CONSTRAINT IF EXISTS payments_invoice_tenant_fk,
  DROP CONSTRAINT IF EXISTS payments_customer_id_fkey,
  DROP CONSTRAINT IF EXISTS payments_payment_method_id_fkey,
  DROP CONSTRAINT IF EXISTS payments_company_customer_fk,
  DROP CONSTRAINT IF EXISTS payments_company_method_fk;

ALTER TABLE public.payments
  DROP COLUMN IF EXISTS amount,
  ADD COLUMN amount_minor_units bigint NOT NULL,
  ADD COLUMN currency_code text NOT NULL,
  ALTER COLUMN invoice_id SET NOT NULL,
  ALTER COLUMN payment_method_id SET NOT NULL,
  ALTER COLUMN payment_date DROP DEFAULT;

ALTER TABLE public.payments
  ADD CONSTRAINT payments_amount_minor_units_positive
    CHECK (amount_minor_units > 0),
  ADD CONSTRAINT payments_currency_code_check
    CHECK (currency_code ~ '^[A-Z]{3}$'),
  ADD CONSTRAINT payments_invoice_currency_tenant_fk
    FOREIGN KEY (company_id, invoice_id, currency_code)
    REFERENCES public.invoices(company_id, id, currency_code)
    ON DELETE RESTRICT,
  ADD CONSTRAINT payments_company_customer_fk
    FOREIGN KEY (company_id, customer_id)
    REFERENCES public.customers(company_id, id)
    ON DELETE RESTRICT,
  ADD CONSTRAINT payments_company_method_fk
    FOREIGN KEY (company_id, payment_method_id)
    REFERENCES public.payment_methods(company_id, id)
    ON DELETE RESTRICT;

CREATE TRIGGER payments_set_updated_at
BEFORE UPDATE ON public.payments
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP INDEX IF EXISTS public.idx_payments_company_id;
DROP INDEX IF EXISTS public.idx_payments_customer_id;
DROP INDEX IF EXISTS public.idx_payments_invoice_id;
DROP INDEX IF EXISTS public.payments_company_invoice_idx;

CREATE INDEX payments_company_invoice_idx
  ON public.payments (company_id, invoice_id, created_at DESC);

CREATE INDEX payments_company_customer_date_idx
  ON public.payments (company_id, customer_id, payment_date DESC, created_at DESC);

CREATE INDEX payments_company_date_idx
  ON public.payments (company_id, payment_date DESC, created_at DESC);

-- Paid/partially-paid invoices retain the issued-state metadata contract.
ALTER TABLE public.invoices
  DROP CONSTRAINT IF EXISTS invoices_status_state_check;

ALTER TABLE public.invoices
  ADD CONSTRAINT invoices_status_state_check
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
      status IN ('issued', 'partially_paid', 'paid')
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
  );

-- Payments are readable by business roles only. Registration is RPC-only;
-- authenticated clients receive no direct INSERT/UPDATE/DELETE privilege.
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS payments_select_members ON public.payments;
DROP POLICY IF EXISTS payments_select_business_roles ON public.payments;
DROP POLICY IF EXISTS payments_insert_accounting ON public.payments;
DROP POLICY IF EXISTS payments_update_accounting ON public.payments;
DROP POLICY IF EXISTS payments_delete_accounting ON public.payments;

CREATE POLICY payments_select_business_roles
  ON public.payments
  FOR SELECT
  TO authenticated
  USING (
    private.has_company_role(
      company_id,
      ARRAY[
        'owner'::public.company_role,
        'admin'::public.company_role,
        'operations'::public.company_role,
        'accountant'::public.company_role,
        'viewer'::public.company_role
      ]
    )
  );

REVOKE ALL PRIVILEGES ON TABLE public.payments FROM PUBLIC;
REVOKE ALL PRIVILEGES ON TABLE public.payments FROM anon;
REVOKE ALL PRIVILEGES ON TABLE public.payments FROM authenticated;
GRANT SELECT ON TABLE public.payments TO authenticated;

COMMIT;
