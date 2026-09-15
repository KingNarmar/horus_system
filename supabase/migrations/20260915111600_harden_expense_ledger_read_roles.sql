-- H.O.R.U.S System — Issue #228 / PC-04
-- Align the canonical expense-ledger read boundary with Domain permissions.
-- Drivers are company members but are not allowed to read company expenses.

BEGIN;

DROP POLICY IF EXISTS expense_ledger_entries_select_members
  ON public.expense_ledger_entries;

CREATE POLICY expense_ledger_entries_select_company_roles
  ON public.expense_ledger_entries
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

COMMIT;
