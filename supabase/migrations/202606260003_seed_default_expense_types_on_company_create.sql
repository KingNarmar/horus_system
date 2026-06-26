-- Keep expense_types ready for every newly-created company.
-- Existing companies are handled by 202606260002_seed_default_expense_types.sql.

create or replace function public.seed_default_expense_types_for_company()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.expense_types (company_id, name)
  values
    (new.id, 'Fuel'),
    (new.id, 'Road fees'),
    (new.id, 'Weighbridge'),
    (new.id, 'Loading'),
    (new.id, 'Unloading'),
    (new.id, 'Fines'),
    (new.id, 'Emergency maintenance'),
    (new.id, 'Driver advance'),
    (new.id, 'Other')
  on conflict do nothing;

  return new;
end;
$$;

drop trigger if exists companies_seed_default_expense_types on public.companies;

create trigger companies_seed_default_expense_types
after insert on public.companies
for each row
execute function public.seed_default_expense_types_for_company();
