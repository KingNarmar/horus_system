-- Issue #50 - Company Expenses foundation.
-- Company-scoped operating expenses separate from Trip Expenses and Driver Settlement.

create table if not exists public.company_expense_categories (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  is_active boolean not null default true,
  created_by uuid null default auth.uid(),
  updated_by uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint company_expense_categories_company_id_id_unique
    unique (company_id, id),
  constraint company_expense_categories_unique_name_per_company
    unique (company_id, name)
);

create table if not exists public.company_expenses (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  category_id uuid not null,
  driver_id uuid null,
  tractor_head_id uuid null,
  trailer_id uuid null,
  trip_id uuid null,
  amount numeric(12, 2) not null check (amount > 0),
  expense_date date not null default current_date,
  reference_number text null,
  notes text null,
  is_voided boolean not null default false,
  voided_at timestamptz null,
  voided_by uuid null,
  void_reason text null,
  created_by uuid null default auth.uid(),
  updated_by uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint company_expenses_category_company_fk
    foreign key (company_id, category_id)
    references public.company_expense_categories(company_id, id)
    on delete restrict,

  constraint company_expenses_driver_company_fk
    foreign key (company_id, driver_id)
    references public.drivers(company_id, id)
    on delete set null (driver_id),

  constraint company_expenses_tractor_head_company_fk
    foreign key (company_id, tractor_head_id)
    references public.tractor_heads(company_id, id)
    on delete set null (tractor_head_id),

  constraint company_expenses_trailer_company_fk
    foreign key (company_id, trailer_id)
    references public.trailers(company_id, id)
    on delete set null (trailer_id),

  constraint company_expenses_trip_company_fk
    foreign key (company_id, trip_id)
    references public.trips(company_id, id)
    on delete set null (trip_id),

  constraint company_expenses_void_state_check
    check (
      (
        is_voided = false
        and voided_at is null
        and voided_by is null
        and void_reason is null
      )
      or
      (
        is_voided = true
        and voided_at is not null
      )
    )
);

create index if not exists company_expense_categories_company_idx
on public.company_expense_categories(company_id);

create index if not exists company_expenses_company_idx
on public.company_expenses(company_id);

create index if not exists company_expenses_category_idx
on public.company_expenses(company_id, category_id);

create index if not exists company_expenses_date_idx
on public.company_expenses(company_id, expense_date desc);

create index if not exists company_expenses_driver_idx
on public.company_expenses(company_id, driver_id)
where driver_id is not null;

create index if not exists company_expenses_tractor_head_idx
on public.company_expenses(company_id, tractor_head_id)
where tractor_head_id is not null;

create index if not exists company_expenses_trailer_idx
on public.company_expenses(company_id, trailer_id)
where trailer_id is not null;

create index if not exists company_expenses_trip_idx
on public.company_expenses(company_id, trip_id)
where trip_id is not null;

drop trigger if exists company_expense_categories_set_updated_at
on public.company_expense_categories;

create trigger company_expense_categories_set_updated_at
before update on public.company_expense_categories
for each row
execute function public.set_updated_at();

drop trigger if exists company_expenses_set_updated_at
on public.company_expenses;

create trigger company_expenses_set_updated_at
before update on public.company_expenses
for each row
execute function public.set_updated_at();

create or replace function public.seed_default_company_expense_categories_for_company()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
begin
  insert into public.company_expense_categories (company_id, name)
  values
    (new.id, 'Vehicle maintenance'),
    (new.id, 'Spare parts'),
    (new.id, 'Tires'),
    (new.id, 'Oils and fluids'),
    (new.id, 'Licenses and renewals'),
    (new.id, 'Office expenses'),
    (new.id, 'Rent'),
    (new.id, 'Salaries'),
    (new.id, 'Admin costs'),
    (new.id, 'Fines'),
    (new.id, 'Other')
  on conflict do nothing;

  return new;
end;
$function$;

drop trigger if exists companies_seed_default_company_expense_categories
on public.companies;

create trigger companies_seed_default_company_expense_categories
after insert on public.companies
for each row
execute function public.seed_default_company_expense_categories_for_company();

insert into public.company_expense_categories (company_id, name)
select
  c.id,
  default_category.name
from public.companies c
cross join (
  values
    ('Vehicle maintenance'),
    ('Spare parts'),
    ('Tires'),
    ('Oils and fluids'),
    ('Licenses and renewals'),
    ('Office expenses'),
    ('Rent'),
    ('Salaries'),
    ('Admin costs'),
    ('Fines'),
    ('Other')
) as default_category(name)
on conflict do nothing;

alter table public.company_expense_categories enable row level security;
alter table public.company_expenses enable row level security;

revoke all on public.company_expense_categories from anon;
revoke all on public.company_expense_categories from authenticated;
revoke all on public.company_expenses from anon;
revoke all on public.company_expenses from authenticated;

grant select, insert, update on public.company_expense_categories to authenticated;
grant select, insert, update on public.company_expenses to authenticated;

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

drop policy if exists company_expense_categories_insert_finance_roles
on public.company_expense_categories;

create policy company_expense_categories_insert_finance_roles
on public.company_expense_categories
for insert
to authenticated
with check (
  private.has_company_role(
    company_id,
    array['owner'::company_role, 'admin'::company_role, 'accountant'::company_role]
  )
);

drop policy if exists company_expense_categories_update_finance_roles
on public.company_expense_categories;

create policy company_expense_categories_update_finance_roles
on public.company_expense_categories
for update
to authenticated
using (
  private.has_company_role(
    company_id,
    array['owner'::company_role, 'admin'::company_role, 'accountant'::company_role]
  )
)
with check (
  private.has_company_role(
    company_id,
    array['owner'::company_role, 'admin'::company_role, 'accountant'::company_role]
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

drop policy if exists company_expenses_insert_finance_roles
on public.company_expenses;

create policy company_expenses_insert_finance_roles
on public.company_expenses
for insert
to authenticated
with check (
  private.has_company_role(
    company_id,
    array['owner'::company_role, 'admin'::company_role, 'accountant'::company_role]
  )
);

drop policy if exists company_expenses_update_finance_roles
on public.company_expenses;

create policy company_expenses_update_finance_roles
on public.company_expenses
for update
to authenticated
using (
  private.has_company_role(
    company_id,
    array['owner'::company_role, 'admin'::company_role, 'accountant'::company_role]
  )
)
with check (
  private.has_company_role(
    company_id,
    array['owner'::company_role, 'admin'::company_role, 'accountant'::company_role]
  )
);
