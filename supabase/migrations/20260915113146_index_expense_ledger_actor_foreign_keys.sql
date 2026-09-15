-- H.O.R.U.S System — Issue #228 / PC-04
-- Cover actor foreign keys on the canonical expense ledger.

BEGIN;

CREATE INDEX expense_ledger_entries_created_by_idx
  ON public.expense_ledger_entries (created_by)
  WHERE created_by IS NOT NULL;

CREATE INDEX expense_ledger_entries_updated_by_idx
  ON public.expense_ledger_entries (updated_by)
  WHERE updated_by IS NOT NULL;

CREATE INDEX expense_ledger_entries_voided_by_idx
  ON public.expense_ledger_entries (voided_by)
  WHERE voided_by IS NOT NULL;

COMMIT;
