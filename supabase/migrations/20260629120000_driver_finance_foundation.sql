-- Issue #24 - Driver advances and deductions foundation.
-- Company-scoped financial movements for driver advances and deductions.

create table if not exists public.driver_financial_movements (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  driver_id uuid not null references public.drivers(id) on delete restrict,
  trip_id uuid null references public.trips(id) on delete set null,
  movement_type text not null check (movement_type in ('advance', 'deduction')),
  amount numeric(12, 2) not null check (amount > 0),
  movement_date date not null default current_date,
  notes text null,
  created_by uuid null default auth.uid(),
  updated_by uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint driver_financial_movements_trip_link_check
    check (trip_id is null or movement_type = 'deduction')
);

create index if not exists driver_financial_movements_company_idx
on public.driver_financial_movements(company_id);

create index if not exists driver_financial_movements_driver_idx
on public.driver_financial_movements(company_id, driver_id);

create index if not exists driver_financial_movements_trip_idx
on public.driver_financial_movements(company_id, trip_id)
where trip_id is not null;

create index if not exists driver_financial_movements_date_idx
on public.driver_financial_movements(company_id, movement_date desc);

alter table public.driver_financial_movements enable row level security;

revoke all on public.driver_financial_movements from anon;
revoke all on public.driver_financial_movements from authenticated;

grant select, insert, update on public.driver_financial_movements to authenticated;

drop policy if exists driver_financial_movements_select_company_members
on public.driver_financial_movements;

create policy driver_financial_movements_select_company_members
on public.driver_financial_movements
for select
to authenticated
using (private.is_company_member(company_id));

drop policy if exists driver_financial_movements_insert_company_members
on public.driver_financial_movements;

create policy driver_financial_movements_insert_company_members
on public.driver_financial_movements
for insert
to authenticated
with check (private.is_company_member(company_id));

drop policy if exists driver_financial_movements_update_company_members
on public.driver_financial_movements;

create policy driver_financial_movements_update_company_members
on public.driver_financial_movements
for update
to authenticated
using (private.is_company_member(company_id))
with check (private.is_company_member(company_id));
