-- H.O.R.U.S System — Issue #46 harden payment methods read-role RLS
--
-- Aligns the database SELECT policy with the Domain role matrix.
-- Owner/Admin/Operations/Accountant/Viewer may read payment methods.
-- Driver remains denied at the RLS boundary.

begin;

drop policy if exists payment_methods_select_members
  on public.payment_methods;

drop policy if exists payment_methods_select_business_roles
  on public.payment_methods;

create policy payment_methods_select_business_roles
  on public.payment_methods
  for select
  to authenticated
  using (
    private.has_company_role(
      company_id,
      array[
        'owner'::public.company_role,
        'admin'::public.company_role,
        'operations'::public.company_role,
        'accountant'::public.company_role,
        'viewer'::public.company_role
      ]
    )
  );

commit;
