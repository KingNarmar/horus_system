alter table public.company_expense_categories
  add column if not exists code text;

update public.company_expense_categories
set code = case name
  when 'Vehicle maintenance' then 'vehicle_maintenance'
  when 'Spare parts' then 'spare_parts'
  when 'Tires' then 'tires'
  when 'Oils and fluids' then 'oils_and_fluids'
  when 'Licenses and renewals' then 'licenses_and_renewals'
  when 'Office expenses' then 'office_expenses'
  when 'Rent' then 'rent'
  when 'Salaries' then 'salaries'
  when 'Admin costs' then 'admin_costs'
  when 'Fines' then 'fines'
  when 'Other' then 'other'
  else code
end
where code is null;

create unique index if not exists company_expense_categories_unique_code_per_company
  on public.company_expense_categories (company_id, code)
  where code is not null;

create or replace function public.seed_default_company_expense_categories_for_company()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.company_expense_categories (company_id, code, name)
  values
    (new.id, 'vehicle_maintenance', 'Vehicle maintenance'),
    (new.id, 'spare_parts', 'Spare parts'),
    (new.id, 'tires', 'Tires'),
    (new.id, 'oils_and_fluids', 'Oils and fluids'),
    (new.id, 'licenses_and_renewals', 'Licenses and renewals'),
    (new.id, 'office_expenses', 'Office expenses'),
    (new.id, 'rent', 'Rent'),
    (new.id, 'salaries', 'Salaries'),
    (new.id, 'admin_costs', 'Admin costs'),
    (new.id, 'fines', 'Fines'),
    (new.id, 'other', 'Other')
  on conflict do nothing;

  return new;
end;
$function$;
