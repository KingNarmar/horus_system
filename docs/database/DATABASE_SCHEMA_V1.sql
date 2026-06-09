-- H.O.R.U.S System — Database Schema V1
-- Heavy Operations & Route Unified System
--
-- Purpose:
-- Initial Supabase/PostgreSQL schema for the H.O.R.U.S SaaS platform.
--
-- Critical project rules:
-- 1. SaaS multi-tenant from day one.
-- 2. Every operational table must include company_id.
-- 3. Company data isolation must be enforced by Row Level Security.
-- 4. This schema supports Clean Architecture by the book by keeping persistence concerns
--    outside the Domain Layer in the Flutter application.
-- 5. This is an initial migration and should be reviewed before production use.

-- =========================================================
-- 1. Extensions
-- =========================================================

create extension if not exists pgcrypto;

-- =========================================================
-- 2. Private helper schema
-- =========================================================

create schema if not exists private;

-- =========================================================
-- 3. Enums
-- =========================================================

do $$
begin
  if not exists (select 1 from pg_type where typname = 'company_role') then
    create type public.company_role as enum (
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer',
      'driver'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'subscription_status') then
    create type public.subscription_status as enum (
      'trialing',
      'active',
      'past_due',
      'cancelled',
      'expired',
      'suspended'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'vehicle_status') then
    create type public.vehicle_status as enum (
      'available',
      'on_trip',
      'loading',
      'unloading',
      'maintenance',
      'stopped',
      'inactive'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'driver_status') then
    create type public.driver_status as enum (
      'available',
      'on_trip',
      'vacation',
      'suspended',
      'inactive'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'trip_status') then
    create type public.trip_status as enum (
      'created',
      'assigned',
      'loaded',
      'on_road',
      'arrived',
      'delivered',
      'documents_received',
      'invoiced',
      'paid',
      'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'expense_paid_by') then
    create type public.expense_paid_by as enum (
      'company',
      'driver_advance',
      'driver_cash',
      'customer',
      'other'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'invoice_status') then
    create type public.invoice_status as enum (
      'draft',
      'issued',
      'partially_paid',
      'paid',
      'overdue',
      'cancelled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'payment_method_code') then
    create type public.payment_method_code as enum (
      'cash',
      'bank_transfer',
      'cheque',
      'card',
      'other'
    );
  end if;
end $$;

-- =========================================================
-- 4. Utility trigger
-- =========================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =========================================================
-- 5. SaaS core tables
-- =========================================================

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  is_platform_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  business_type text,
  phone text,
  email text,
  country text,
  city text,
  logo_url text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint companies_name_not_empty check (length(trim(name)) > 0)
);

create table if not exists public.company_users (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.company_role not null default 'viewer',
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint company_users_unique_user_per_company unique (company_id, user_id)
);

create table if not exists public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  monthly_price numeric(12,2) not null default 0,
  max_users integer,
  max_vehicles integer,
  max_trips_per_month integer,
  has_driver_app boolean not null default false,
  has_advanced_reports boolean not null default false,
  has_document_upload boolean not null default false,
  has_maintenance boolean not null default false,
  has_whatsapp_notifications boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint subscription_plans_price_non_negative check (monthly_price >= 0)
);

create table if not exists public.company_subscriptions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  plan_id uuid not null references public.subscription_plans(id),
  status public.subscription_status not null default 'trialing',
  trial_ends_at timestamptz,
  current_period_start timestamptz,
  current_period_end timestamptz,
  external_provider text,
  external_subscription_id text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =========================================================
-- 6. Master data tables
-- =========================================================

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  phone text,
  governorate text,
  address text,
  contact_person text,
  payment_terms text,
  credit_limit numeric(14,2),
  notes text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint customers_name_not_empty check (length(trim(name)) > 0),
  constraint customers_credit_limit_non_negative check (credit_limit is null or credit_limit >= 0),
  constraint customers_unique_name_per_company unique (company_id, name)
);

create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  phone text,
  national_id text,
  license_type text,
  license_expiry_date date,
  status public.driver_status not null default 'available',
  notes text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint drivers_name_not_empty check (length(trim(name)) > 0),
  constraint drivers_unique_national_id_per_company unique (company_id, national_id)
);

create table if not exists public.tractor_heads (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  plate_number text not null,
  license_expiry_date date,
  expected_fuel_consumption numeric(12,3),
  status public.vehicle_status not null default 'available',
  notes text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tractor_heads_plate_not_empty check (length(trim(plate_number)) > 0),
  constraint tractor_heads_expected_fuel_non_negative check (expected_fuel_consumption is null or expected_fuel_consumption >= 0),
  constraint tractor_heads_unique_plate_per_company unique (company_id, plate_number)
);

create table if not exists public.trailers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  plate_number text not null,
  license_expiry_date date,
  status public.vehicle_status not null default 'available',
  technical_notes text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trailers_plate_not_empty check (length(trim(plate_number)) > 0),
  constraint trailers_unique_plate_per_company unique (company_id, plate_number)
);

create table if not exists public.routes (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  loading_location text not null,
  unloading_location text not null,
  governorate_from text,
  governorate_to text,
  default_freight_price numeric(14,2),
  notes text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint routes_loading_not_empty check (length(trim(loading_location)) > 0),
  constraint routes_unloading_not_empty check (length(trim(unloading_location)) > 0),
  constraint routes_default_price_non_negative check (default_freight_price is null or default_freight_price >= 0),
  constraint routes_unique_per_company unique (company_id, loading_location, unloading_location)
);

create table if not exists public.expense_types (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint expense_types_name_not_empty check (length(trim(name)) > 0),
  constraint expense_types_unique_name_per_company unique (company_id, name)
);

create table if not exists public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  code public.payment_method_code not null default 'other',
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payment_methods_name_not_empty check (length(trim(name)) > 0),
  constraint payment_methods_unique_name_per_company unique (company_id, name)
);

-- =========================================================
-- 7. Operations tables
-- =========================================================

create table if not exists public.trips (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  trip_number text not null,
  customer_id uuid not null references public.customers(id),
  driver_id uuid references public.drivers(id),
  tractor_head_id uuid references public.tractor_heads(id),
  trailer_id uuid references public.trailers(id),
  route_id uuid references public.routes(id),
  trip_date date not null default current_date,
  loading_location text not null,
  unloading_location text not null,
  cargo_type text not null default 'Cement',
  quantity_tons numeric(12,3),
  loading_order_number text,
  waybill_number text,
  freight_price numeric(14,2) not null default 0,
  status public.trip_status not null default 'created',
  loading_time timestamptz,
  departure_time timestamptz,
  arrival_time timestamptz,
  unloading_time timestamptz,
  documents_received_at timestamptz,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trips_unique_number_per_company unique (company_id, trip_number),
  constraint trips_quantity_positive check (quantity_tons is null or quantity_tons > 0),
  constraint trips_freight_non_negative check (freight_price >= 0),
  constraint trips_loading_not_empty check (length(trim(loading_location)) > 0),
  constraint trips_unloading_not_empty check (length(trim(unloading_location)) > 0)
);

create table if not exists public.trip_status_history (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  trip_id uuid not null references public.trips(id) on delete cascade,
  old_status public.trip_status,
  new_status public.trip_status not null,
  changed_at timestamptz not null default now(),
  changed_by uuid references auth.users(id) on delete set null,
  notes text
);

create table if not exists public.trip_expenses (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  trip_id uuid not null references public.trips(id) on delete cascade,
  expense_type_id uuid references public.expense_types(id),
  expense_name text not null,
  amount numeric(14,2) not null,
  paid_by public.expense_paid_by not null default 'company',
  deduct_from_driver boolean not null default false,
  charge_to_customer boolean not null default false,
  expense_date date not null default current_date,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trip_expenses_name_not_empty check (length(trim(expense_name)) > 0),
  constraint trip_expenses_amount_positive check (amount > 0)
);

-- =========================================================
-- 8. Finance tables
-- =========================================================

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  invoice_number text not null,
  customer_id uuid not null references public.customers(id),
  invoice_date date not null default current_date,
  due_date date,
  total_amount numeric(14,2) not null default 0,
  discount_amount numeric(14,2) not null default 0,
  tax_amount numeric(14,2) not null default 0,
  net_amount numeric(14,2) not null default 0,
  status public.invoice_status not null default 'draft',
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint invoices_unique_number_per_company unique (company_id, invoice_number),
  constraint invoices_amounts_non_negative check (
    total_amount >= 0 and discount_amount >= 0 and tax_amount >= 0 and net_amount >= 0
  )
);

create table if not exists public.invoice_trips (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  trip_id uuid not null references public.trips(id),
  created_at timestamptz not null default now(),
  constraint invoice_trips_unique_trip unique (company_id, trip_id),
  constraint invoice_trips_unique_invoice_trip unique (invoice_id, trip_id)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  invoice_id uuid references public.invoices(id) on delete set null,
  customer_id uuid not null references public.customers(id),
  payment_method_id uuid references public.payment_methods(id),
  payment_date date not null default current_date,
  amount numeric(14,2) not null,
  reference_number text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payments_amount_positive check (amount > 0)
);

create table if not exists public.driver_advances (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  driver_id uuid not null references public.drivers(id),
  advance_date date not null default current_date,
  amount numeric(14,2) not null,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint driver_advances_amount_positive check (amount > 0)
);

create table if not exists public.driver_deductions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  driver_id uuid not null references public.drivers(id),
  trip_id uuid references public.trips(id) on delete set null,
  deduction_date date not null default current_date,
  amount numeric(14,2) not null,
  reason text not null,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint driver_deductions_amount_positive check (amount > 0),
  constraint driver_deductions_reason_not_empty check (length(trim(reason)) > 0)
);

-- =========================================================
-- 9. Indexes
-- =========================================================

create index if not exists idx_company_users_company_id on public.company_users(company_id);
create index if not exists idx_company_users_user_id on public.company_users(user_id);

create index if not exists idx_company_subscriptions_company_id on public.company_subscriptions(company_id);

create index if not exists idx_customers_company_id on public.customers(company_id);
create index if not exists idx_drivers_company_id on public.drivers(company_id);
create index if not exists idx_tractor_heads_company_id on public.tractor_heads(company_id);
create index if not exists idx_trailers_company_id on public.trailers(company_id);
create index if not exists idx_routes_company_id on public.routes(company_id);
create index if not exists idx_expense_types_company_id on public.expense_types(company_id);
create index if not exists idx_payment_methods_company_id on public.payment_methods(company_id);

create index if not exists idx_trips_company_id on public.trips(company_id);
create index if not exists idx_trips_customer_id on public.trips(customer_id);
create index if not exists idx_trips_driver_id on public.trips(driver_id);
create index if not exists idx_trips_status on public.trips(status);
create index if not exists idx_trips_trip_date on public.trips(trip_date);

create index if not exists idx_trip_status_history_company_id on public.trip_status_history(company_id);
create index if not exists idx_trip_status_history_trip_id on public.trip_status_history(trip_id);

create index if not exists idx_trip_expenses_company_id on public.trip_expenses(company_id);
create index if not exists idx_trip_expenses_trip_id on public.trip_expenses(trip_id);

create index if not exists idx_invoices_company_id on public.invoices(company_id);
create index if not exists idx_invoices_customer_id on public.invoices(customer_id);
create index if not exists idx_invoices_status on public.invoices(status);

create index if not exists idx_invoice_trips_company_id on public.invoice_trips(company_id);
create index if not exists idx_invoice_trips_invoice_id on public.invoice_trips(invoice_id);
create index if not exists idx_invoice_trips_trip_id on public.invoice_trips(trip_id);

create index if not exists idx_payments_company_id on public.payments(company_id);
create index if not exists idx_payments_invoice_id on public.payments(invoice_id);
create index if not exists idx_payments_customer_id on public.payments(customer_id);

create index if not exists idx_driver_advances_company_id on public.driver_advances(company_id);
create index if not exists idx_driver_advances_driver_id on public.driver_advances(driver_id);
create index if not exists idx_driver_deductions_company_id on public.driver_deductions(company_id);
create index if not exists idx_driver_deductions_driver_id on public.driver_deductions(driver_id);

-- =========================================================
-- 10. Updated-at triggers
-- =========================================================

drop trigger if exists user_profiles_set_updated_at on public.user_profiles;
create trigger user_profiles_set_updated_at
before update on public.user_profiles
for each row execute function public.set_updated_at();

drop trigger if exists companies_set_updated_at on public.companies;
create trigger companies_set_updated_at
before update on public.companies
for each row execute function public.set_updated_at();

drop trigger if exists company_users_set_updated_at on public.company_users;
create trigger company_users_set_updated_at
before update on public.company_users
for each row execute function public.set_updated_at();

drop trigger if exists subscription_plans_set_updated_at on public.subscription_plans;
create trigger subscription_plans_set_updated_at
before update on public.subscription_plans
for each row execute function public.set_updated_at();

drop trigger if exists company_subscriptions_set_updated_at on public.company_subscriptions;
create trigger company_subscriptions_set_updated_at
before update on public.company_subscriptions
for each row execute function public.set_updated_at();

drop trigger if exists customers_set_updated_at on public.customers;
create trigger customers_set_updated_at
before update on public.customers
for each row execute function public.set_updated_at();

drop trigger if exists drivers_set_updated_at on public.drivers;
create trigger drivers_set_updated_at
before update on public.drivers
for each row execute function public.set_updated_at();

drop trigger if exists tractor_heads_set_updated_at on public.tractor_heads;
create trigger tractor_heads_set_updated_at
before update on public.tractor_heads
for each row execute function public.set_updated_at();

drop trigger if exists trailers_set_updated_at on public.trailers;
create trigger trailers_set_updated_at
before update on public.trailers
for each row execute function public.set_updated_at();

drop trigger if exists routes_set_updated_at on public.routes;
create trigger routes_set_updated_at
before update on public.routes
for each row execute function public.set_updated_at();

drop trigger if exists expense_types_set_updated_at on public.expense_types;
create trigger expense_types_set_updated_at
before update on public.expense_types
for each row execute function public.set_updated_at();

drop trigger if exists payment_methods_set_updated_at on public.payment_methods;
create trigger payment_methods_set_updated_at
before update on public.payment_methods
for each row execute function public.set_updated_at();

drop trigger if exists trips_set_updated_at on public.trips;
create trigger trips_set_updated_at
before update on public.trips
for each row execute function public.set_updated_at();

drop trigger if exists trip_expenses_set_updated_at on public.trip_expenses;
create trigger trip_expenses_set_updated_at
before update on public.trip_expenses
for each row execute function public.set_updated_at();

drop trigger if exists invoices_set_updated_at on public.invoices;
create trigger invoices_set_updated_at
before update on public.invoices
for each row execute function public.set_updated_at();

drop trigger if exists payments_set_updated_at on public.payments;
create trigger payments_set_updated_at
before update on public.payments
for each row execute function public.set_updated_at();

drop trigger if exists driver_advances_set_updated_at on public.driver_advances;
create trigger driver_advances_set_updated_at
before update on public.driver_advances
for each row execute function public.set_updated_at();

drop trigger if exists driver_deductions_set_updated_at on public.driver_deductions;
create trigger driver_deductions_set_updated_at
before update on public.driver_deductions
for each row execute function public.set_updated_at();

-- =========================================================
-- 11. Security helper functions
-- =========================================================

create or replace function private.is_platform_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.user_profiles up
    where up.id = auth.uid()
      and up.is_platform_admin = true
  );
$$;

create or replace function private.is_company_member(target_company_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.company_users cu
    where cu.company_id = target_company_id
      and cu.user_id = auth.uid()
      and cu.is_active = true
  );
$$;

create or replace function private.has_company_role(
  target_company_id uuid,
  allowed_roles public.company_role[]
)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.company_users cu
    where cu.company_id = target_company_id
      and cu.user_id = auth.uid()
      and cu.is_active = true
      and cu.role = any(allowed_roles)
  );
$$;

revoke all on function private.is_platform_admin() from public;
revoke all on function private.is_company_member(uuid) from public;
revoke all on function private.has_company_role(uuid, public.company_role[]) from public;

grant execute on function private.is_platform_admin() to authenticated;
grant execute on function private.is_company_member(uuid) to authenticated;
grant execute on function private.has_company_role(uuid, public.company_role[]) to authenticated;

-- =========================================================
-- 12. Enable RLS
-- =========================================================

alter table public.user_profiles enable row level security;
alter table public.companies enable row level security;
alter table public.company_users enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.company_subscriptions enable row level security;
alter table public.customers enable row level security;
alter table public.drivers enable row level security;
alter table public.tractor_heads enable row level security;
alter table public.trailers enable row level security;
alter table public.routes enable row level security;
alter table public.expense_types enable row level security;
alter table public.payment_methods enable row level security;
alter table public.trips enable row level security;
alter table public.trip_status_history enable row level security;
alter table public.trip_expenses enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_trips enable row level security;
alter table public.payments enable row level security;
alter table public.driver_advances enable row level security;
alter table public.driver_deductions enable row level security;

-- =========================================================
-- 13. RLS policies — platform and SaaS core
-- =========================================================

create policy user_profiles_select_own_or_platform_admin
on public.user_profiles
for select
to authenticated
using (id = auth.uid() or private.is_platform_admin());

create policy user_profiles_insert_own
on public.user_profiles
for insert
to authenticated
with check (id = auth.uid());

create policy user_profiles_update_own_or_platform_admin
on public.user_profiles
for update
to authenticated
using (id = auth.uid() or private.is_platform_admin())
with check (id = auth.uid() or private.is_platform_admin());

create policy companies_select_member_or_platform_admin
on public.companies
for select
to authenticated
using (private.is_company_member(id) or private.is_platform_admin());

create policy companies_insert_authenticated
on public.companies
for insert
to authenticated
with check (created_by = auth.uid());

create policy companies_update_owner_admin_or_platform_admin
on public.companies
for update
to authenticated
using (
  private.has_company_role(id, array['owner','admin']::public.company_role[])
  or private.is_platform_admin()
)
with check (
  private.has_company_role(id, array['owner','admin']::public.company_role[])
  or private.is_platform_admin()
);

create policy company_users_select_company_members
on public.company_users
for select
to authenticated
using (private.is_company_member(company_id) or private.is_platform_admin());

create policy company_users_insert_initial_owner_or_admin
on public.company_users
for insert
to authenticated
with check (
  private.is_platform_admin()
  or (
    user_id = auth.uid()
    and role = 'owner'
    and exists (
      select 1 from public.companies c
      where c.id = company_id
        and c.created_by = auth.uid()
    )
  )
  or private.has_company_role(company_id, array['owner','admin']::public.company_role[])
);

create policy company_users_update_owner_admin_or_platform_admin
on public.company_users
for update
to authenticated
using (
  private.has_company_role(company_id, array['owner','admin']::public.company_role[])
  or private.is_platform_admin()
)
with check (
  private.has_company_role(company_id, array['owner','admin']::public.company_role[])
  or private.is_platform_admin()
);

create policy subscription_plans_select_active_or_platform_admin
on public.subscription_plans
for select
to authenticated
using (is_active = true or private.is_platform_admin());

create policy company_subscriptions_select_company_members
on public.company_subscriptions
for select
to authenticated
using (private.is_company_member(company_id) or private.is_platform_admin());

create policy company_subscriptions_manage_owner_admin_or_platform_admin
on public.company_subscriptions
for all
to authenticated
using (
  private.has_company_role(company_id, array['owner','admin']::public.company_role[])
  or private.is_platform_admin()
)
with check (
  private.has_company_role(company_id, array['owner','admin']::public.company_role[])
  or private.is_platform_admin()
);

-- =========================================================
-- 14. RLS policies — master data
-- =========================================================

create policy customers_select_members
on public.customers
for select
to authenticated
using (private.is_company_member(company_id));

create policy customers_insert_operations_accounting
on public.customers
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','operations','accountant']::public.company_role[]));

create policy customers_update_operations_accounting
on public.customers
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','operations','accountant']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','operations','accountant']::public.company_role[]));

create policy drivers_select_members
on public.drivers
for select
to authenticated
using (private.is_company_member(company_id));

create policy drivers_insert_operations
on public.drivers
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy drivers_update_operations
on public.drivers
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy tractor_heads_select_members
on public.tractor_heads
for select
to authenticated
using (private.is_company_member(company_id));

create policy tractor_heads_insert_operations
on public.tractor_heads
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy tractor_heads_update_operations
on public.tractor_heads
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy trailers_select_members
on public.trailers
for select
to authenticated
using (private.is_company_member(company_id));

create policy trailers_insert_operations
on public.trailers
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy trailers_update_operations
on public.trailers
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy routes_select_members
on public.routes
for select
to authenticated
using (private.is_company_member(company_id));

create policy routes_insert_operations
on public.routes
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy routes_update_operations
on public.routes
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy expense_types_select_members
on public.expense_types
for select
to authenticated
using (private.is_company_member(company_id));

create policy expense_types_insert_accounting
on public.expense_types
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy expense_types_update_accounting
on public.expense_types
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy payment_methods_select_members
on public.payment_methods
for select
to authenticated
using (private.is_company_member(company_id));

create policy payment_methods_insert_accounting
on public.payment_methods
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy payment_methods_update_accounting
on public.payment_methods
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

-- =========================================================
-- 15. RLS policies — operations
-- =========================================================

create policy trips_select_members
on public.trips
for select
to authenticated
using (private.is_company_member(company_id));

create policy trips_insert_operations
on public.trips
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy trips_update_operations
on public.trips
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy trip_status_history_select_members
on public.trip_status_history
for select
to authenticated
using (private.is_company_member(company_id));

create policy trip_status_history_insert_operations
on public.trip_status_history
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','operations']::public.company_role[]));

create policy trip_expenses_select_members
on public.trip_expenses
for select
to authenticated
using (private.is_company_member(company_id));

create policy trip_expenses_insert_operations_accounting
on public.trip_expenses
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','operations','accountant']::public.company_role[]));

create policy trip_expenses_update_operations_accounting
on public.trip_expenses
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','operations','accountant']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','operations','accountant']::public.company_role[]));

-- =========================================================
-- 16. RLS policies — finance
-- =========================================================

create policy invoices_select_members
on public.invoices
for select
to authenticated
using (private.is_company_member(company_id));

create policy invoices_insert_accounting
on public.invoices
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy invoices_update_accounting
on public.invoices
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy invoice_trips_select_members
on public.invoice_trips
for select
to authenticated
using (private.is_company_member(company_id));

create policy invoice_trips_insert_accounting
on public.invoice_trips
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy payments_select_members
on public.payments
for select
to authenticated
using (private.is_company_member(company_id));

create policy payments_insert_accounting
on public.payments
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy payments_update_accounting
on public.payments
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy driver_advances_select_members
on public.driver_advances
for select
to authenticated
using (private.is_company_member(company_id));

create policy driver_advances_insert_accounting
on public.driver_advances
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy driver_advances_update_accounting
on public.driver_advances
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy driver_deductions_select_members
on public.driver_deductions
for select
to authenticated
using (private.is_company_member(company_id));

create policy driver_deductions_insert_accounting
on public.driver_deductions
for insert
to authenticated
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

create policy driver_deductions_update_accounting
on public.driver_deductions
for update
to authenticated
using (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]))
with check (private.has_company_role(company_id, array['owner','admin','accountant']::public.company_role[]));

-- =========================================================
-- 17. Seed subscription plans
-- =========================================================

insert into public.subscription_plans (
  code,
  name,
  monthly_price,
  max_users,
  max_vehicles,
  max_trips_per_month,
  has_driver_app,
  has_advanced_reports,
  has_document_upload,
  has_maintenance,
  has_whatsapp_notifications
)
values
  ('basic', 'Basic', 0, 3, 5, 100, false, false, false, false, false),
  ('pro', 'Pro', 0, 10, 25, 1000, false, true, true, false, false),
  ('enterprise', 'Enterprise', 0, null, null, null, true, true, true, true, true)
on conflict (code) do nothing;

-- =========================================================
-- 18. Notes
-- =========================================================

-- No DELETE policies are intentionally added in V1.
-- Master data should be deactivated using is_active instead of hard deletion.
-- Hard delete operations, if ever needed, should be handled by privileged admin/service flows only.
--
-- Next recommended migration:
-- 1. Add secure RPC for company onboarding.
-- 2. Add trip number and invoice number generation functions.
-- 3. Add audit logging for critical financial and lifecycle actions.
-- 4. Add attachments/storage policies when document upload enters scope.
