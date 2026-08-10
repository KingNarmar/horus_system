-- H.O.R.U.S System — Issue #27 Payments module
--
-- Add payment lifecycle states in their own migration so later migrations can
-- safely use the new enum values after this migration commits.

ALTER TYPE public.invoice_status
  ADD VALUE IF NOT EXISTS 'partially_paid' AFTER 'issued';

ALTER TYPE public.invoice_status
  ADD VALUE IF NOT EXISTS 'paid' AFTER 'partially_paid';
