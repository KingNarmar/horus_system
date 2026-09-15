-- PC-06 hardening: remove the exact legacy RLS policy names that predate
-- the canonical Expense Ledger cutover. Grants were already revoked by the
-- primary retirement migration; these policies are removed as defense in depth
-- and to leave trip_expenses as a purely archival table for app roles.

DROP POLICY IF EXISTS trip_expenses_select_members
  ON public.trip_expenses;
DROP POLICY IF EXISTS trip_expenses_insert_operations_accounting
  ON public.trip_expenses;
DROP POLICY IF EXISTS trip_expenses_update_operations_accounting
  ON public.trip_expenses;

-- Canonical expense taxonomy codes are system-owned. The historical accounting
-- insert policy must not survive after custom Expense Type creation is retired.
DROP POLICY IF EXISTS expense_types_insert_accounting
  ON public.expense_types;
