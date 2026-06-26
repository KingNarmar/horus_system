-- Fix grants required for Issue #22 trip expenses.
-- RLS policies already restrict access by company_id and role.

grant select, insert, update
on table public.trip_expenses
to authenticated;

grant select
on table public.expense_types
to authenticated;
