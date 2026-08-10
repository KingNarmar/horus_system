-- H.O.R.U.S System — Issue #27 Payments module
-- Accountant audit visibility for payment and invoice payment lifecycle events.

BEGIN;

DROP POLICY IF EXISTS audit_logs_select_accountant_payments
  ON public.audit_logs;

CREATE POLICY audit_logs_select_accountant_payments
  ON public.audit_logs
  FOR SELECT
  TO authenticated
  USING (
    private.has_company_role(
      company_id,
      ARRAY['accountant'::public.company_role]
    )
    AND module = 'payments'
    AND entity_type = 'payment'
    AND metadata IS NOT NULL
    AND description = metadata ->> 'audit_event'
    AND action = 'registered'
    AND metadata ->> 'audit_event' = 'payment_registered'
  );

DROP POLICY IF EXISTS audit_logs_select_accountant_invoices
  ON public.audit_logs;

CREATE POLICY audit_logs_select_accountant_invoices
  ON public.audit_logs
  FOR SELECT
  TO authenticated
  USING (
    private.has_company_role(
      company_id,
      ARRAY['accountant'::public.company_role]
    )
    AND module = 'invoices'
    AND entity_type = 'invoice'
    AND metadata IS NOT NULL
    AND NULLIF(pg_catalog.btrim(entity_id), '') IS NOT NULL
    AND description = metadata ->> 'audit_event'
    AND (
      (action = 'created' AND metadata ->> 'audit_event' = 'invoice_created')
      OR (action = 'updated' AND metadata ->> 'audit_event' = 'invoice_updated')
      OR (action = 'issued' AND metadata ->> 'audit_event' = 'invoice_issued')
      OR (action = 'cancelled' AND metadata ->> 'audit_event' = 'invoice_cancelled')
      OR (
        action = 'payment_status_changed'
        AND metadata ->> 'audit_event' = 'invoice_payment_status_changed'
      )
    )
  );

COMMIT;
