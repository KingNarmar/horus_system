-- Issue #50 hardening - keep company expenses SELECT aligned with Domain policy.
-- Drivers must not read general company expenses.

drop policy if exists company_expense_categories_select_company_members
on public.company_expense_categories;

create policy company_expense_categories_select_company_members
on public.company_expense_categories
for select
to authenticated
using (
  private.has_company_role(
    company_id,
    array[
      'owner'::company_role,
      'admin'::company_role,
      'operations'::company_role,
      'accountant'::company_role,
      'viewer'::company_role
    ]
  )
);

drop policy if exists company_expenses_select_company_members
on public.company_expenses;

create policy company_expenses_select_company_members
on public.company_expenses
for select
to authenticated
using (
  private.has_company_role(
    company_id,
    array[
      'owner'::company_role,
      'admin'::company_role,
      'operations'::company_role,
      'accountant'::company_role,
      'viewer'::company_role
    ]
  )
);
