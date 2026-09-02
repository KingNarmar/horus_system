begin;

do $$
begin
  if exists (
    select 1
    from public.expense_types
    group by company_id, lower(btrim(name))
    having count(*) > 1
  ) then
    raise exception
      'Cannot enforce normalized expense type uniqueness while duplicate names exist within a company.';
  end if;
end
$$;

alter table public.expense_types
  drop constraint if exists expense_types_unique_name_per_company;

drop index if exists public.expense_types_unique_normalized_name_per_company;

create unique index expense_types_unique_normalized_name_per_company
  on public.expense_types (company_id, lower(btrim(name)));

alter table public.expense_types enable row level security;

drop policy if exists expense_types_select_members on public.expense_types;
create policy expense_types_select_members
  on public.expense_types
  for select
  to authenticated
  using (private.is_company_member(company_id));

drop policy if exists expense_types_insert_accounting on public.expense_types;
create policy expense_types_insert_accounting
  on public.expense_types
  for insert
  to authenticated
  with check (
    private.has_company_role(company_id, array['owner', 'admin', 'accountant'])
  );

drop policy if exists expense_types_update_accounting on public.expense_types;
create policy expense_types_update_accounting
  on public.expense_types
  for update
  to authenticated
  using (
    private.has_company_role(company_id, array['owner', 'admin', 'accountant'])
  )
  with check (
    private.has_company_role(company_id, array['owner', 'admin', 'accountant'])
  );

revoke all on table public.expense_types from public;
revoke all on table public.expense_types from anon;
revoke all on table public.expense_types from authenticated;

grant select, insert, update on table public.expense_types to authenticated;

commit;
