-- Ensure cancelled invoices always carry a real cancellation reason.
-- PostgreSQL CHECK constraints accept NULL expressions unless guarded explicitly.

BEGIN;

ALTER TABLE public.invoices
  DROP CONSTRAINT invoices_status_state_check;

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
      AND cancellation_reason IS NOT NULL
      AND pg_catalog.btrim(cancellation_reason) <> ''
    )
  );

COMMIT;
