revoke update on table public.driver_financial_movements from authenticated;

drop policy if exists driver_financial_movements_insert_company_members on public.driver_financial_movements;
drop policy if exists driver_financial_movements_update_company_members on public.driver_financial_movements;

create policy driver_financial_movements_insert_finance_roles
on public.driver_financial_movements
for insert
to authenticated
with check (
  exists (
    select 1
    from public.company_users cu
    where cu.company_id = driver_financial_movements.company_id
      and cu.user_id = auth.uid()
      and cu.is_active = true
      and cu.role::text in ('owner', 'admin', 'accountant')
  )
);
