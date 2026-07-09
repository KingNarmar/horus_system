-- H.O.R.U.S System
-- Issue #51: Driver settlement and salary foundation.
-- Adds company-scoped settlement snapshots without duplicating trip/company expenses.

create type driver_settlement_status as enum (
  'draft',
  'finalized',
  'voided'
);

create type driver_settlement_item_source_type as enum (
  'driver_financial_movement',
  'trip_expense',
  'manual_adjustment'
);

create type driver_settlement_item_direction as enum (
  'company_to_driver',
  'driver_to_company',
  'neutral'
);

create table public.driver_settlements (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  driver_id uuid not null,
  period_start date not null,
  period_end date not null,
  opening_driver_balance numeric(14, 2) not null default 0,
  advances_total numeric(14, 2) not null default 0,
  driver_paid_trip_expenses_total numeric(14, 2) not null default 0,
  returned_cash_total numeric(14, 2) not null default 0,
  deductions_total numeric(14, 2) not null default 0,
  settlement_deductions_total numeric(14, 2) not null default 0,
  gross_salary numeric(14, 2) not null default 0,
  salary_deductions_total numeric(14, 2) not null default 0,
  balance_deduction_applied numeric(14, 2) not null default 0,
  net_salary_payable numeric(14, 2) not null default 0,
  closing_driver_balance numeric(14, 2) not null default 0,
  status driver_settlement_status not null default 'draft',
  notes text,
  finalized_at timestamp with time zone,
  finalized_by uuid references auth.users(id) on delete set null,
  voided_at timestamp with time zone,
  voided_by uuid references auth.users(id) on delete set null,
  void_reason text,
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint driver_settlements_company_id_id_unique unique (company_id, id),
  constraint driver_settlements_driver_company_fk
    foreign key (company_id, driver_id)
    references public.drivers(company_id, id)
    on delete restrict,
  constraint driver_settlements_period_check
    check (period_start <= period_end),
  constraint driver_settlements_non_negative_totals_check
    check (
      advances_total >= 0
      and driver_paid_trip_expenses_total >= 0
      and returned_cash_total >= 0
      and deductions_total >= 0
      and settlement_deductions_total >= 0
      and gross_salary >= 0
      and salary_deductions_total >= 0
      and balance_deduction_applied >= 0
      and net_salary_payable >= 0
    ),
  constraint driver_settlements_status_state_check
    check (
      (
        status = 'draft'
        and finalized_at is null
        and finalized_by is null
        and voided_at is null
        and voided_by is null
        and void_reason is null
      )
      or (
        status = 'finalized'
        and finalized_at is not null
        and finalized_by is not null
        and voided_at is null
        and voided_by is null
        and void_reason is null
      )
      or (
        status = 'voided'
        and voided_at is not null
        and voided_by is not null
        and length(trim(void_reason)) > 0
      )
    )
);

create table public.driver_settlement_items (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  settlement_id uuid not null,
  source_type driver_settlement_item_source_type not null,
  source_id uuid,
  source_date date,
  direction driver_settlement_item_direction not null,
  amount numeric(14, 2) not null,
  label_key text not null,
  description_key text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamp with time zone not null default now(),
  constraint driver_settlement_items_company_id_id_unique unique (company_id, id),
  constraint driver_settlement_items_settlement_company_fk
    foreign key (company_id, settlement_id)
    references public.driver_settlements(company_id, id)
    on delete cascade,
  constraint driver_settlement_items_amount_check
    check (amount >= 0),
  constraint driver_settlement_items_label_key_not_empty
    check (length(trim(label_key)) > 0),
  constraint driver_settlement_items_metadata_object_check
    check (jsonb_typeof(metadata) = 'object'),
  constraint driver_settlement_items_source_reference_check
    check (
      (source_type = 'manual_adjustment' and source_id is null)
      or (source_type <> 'manual_adjustment' and source_id is not null)
    )
);

create unique index driver_settlements_unique_active_period_idx
  on public.driver_settlements (company_id, driver_id, period_start, period_end)
  where status <> 'voided';

create index driver_settlements_company_driver_period_idx
  on public.driver_settlements (company_id, driver_id, period_start, period_end);

create index driver_settlements_company_status_idx
  on public.driver_settlements (company_id, status);

create index driver_settlements_created_by_idx
  on public.driver_settlements (company_id, created_by)
  where created_by is not null;

create index driver_settlement_items_settlement_idx
  on public.driver_settlement_items (company_id, settlement_id);

create index driver_settlement_items_source_idx
  on public.driver_settlement_items (company_id, source_type, source_id)
  where source_id is not null;

create index trip_expenses_driver_settlement_lookup_idx
  on public.trip_expenses (company_id, paid_by, expense_date desc, trip_id)
  where paid_by in ('driver_advance'::expense_paid_by, 'driver_cash'::expense_paid_by);

create trigger driver_settlements_set_updated_at
  before update on public.driver_settlements
  for each row
  execute function public.set_updated_at();

alter table public.driver_settlements enable row level security;
alter table public.driver_settlement_items enable row level security;

revoke all on public.driver_settlements from anon, authenticated, public;
revoke all on public.driver_settlement_items from anon, authenticated, public;

grant select, insert, update on public.driver_settlements to authenticated;
grant select, insert on public.driver_settlement_items to authenticated;

create policy driver_settlements_select_finance_roles
  on public.driver_settlements
  for select
  to authenticated
  using (
    private.has_company_role(
      company_id,
      array['owner'::company_role, 'admin'::company_role, 'accountant'::company_role]
    )
  );

create policy driver_settlements_insert_finance_roles
  on public.driver_settlements
  for insert
  to authenticated
  with check (
    status = 'draft'
    and private.has_company_role(
      company_id,
      array['owner'::company_role, 'admin'::company_role, 'accountant'::company_role]
    )
  );

create policy driver_settlements_update_finance_roles
  on public.driver_settlements
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

create policy driver_settlement_items_select_finance_roles
  on public.driver_settlement_items
  for select
  to authenticated
  using (
    private.has_company_role(
      company_id,
      array['owner'::company_role, 'admin'::company_role, 'accountant'::company_role]
    )
  );

create policy driver_settlement_items_insert_finance_roles
  on public.driver_settlement_items
  for insert
  to authenticated
  with check (
    private.has_company_role(
      company_id,
      array['owner'::company_role, 'admin'::company_role, 'accountant'::company_role]
    )
    and exists (
      select 1
      from public.driver_settlements ds
      where ds.company_id = driver_settlement_items.company_id
        and ds.id = driver_settlement_items.settlement_id
        and ds.status = 'draft'
    )
  );
