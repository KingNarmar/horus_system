-- H.O.R.U.S System — Issue #5 Follow-up Migration
-- Add company-scoped relational integrity constraints.
--
-- Purpose:
-- Strengthen SaaS multi-tenant database integrity by ensuring that child records
-- cannot reference parent records from another company.
--
-- Important:
-- This migration does not replace RLS.
-- RLS remains the first security isolation layer.
-- These constraints reinforce database-level consistency.

-- =========================================================
-- 1. Add composite unique constraints on company-scoped parent tables
-- =========================================================

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'customers_company_id_id_unique'
      and conrelid = 'public.customers'::regclass
  ) then
    alter table public.customers
    add constraint customers_company_id_id_unique unique (company_id, id);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'drivers_company_id_id_unique'
      and conrelid = 'public.drivers'::regclass
  ) then
    alter table public.drivers
    add constraint drivers_company_id_id_unique unique (company_id, id);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'tractor_heads_company_id_id_unique'
      and conrelid = 'public.tractor_heads'::regclass
  ) then
    alter table public.tractor_heads
    add constraint tractor_heads_company_id_id_unique unique (company_id, id);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trailers_company_id_id_unique'
      and conrelid = 'public.trailers'::regclass
  ) then
    alter table public.trailers
    add constraint trailers_company_id_id_unique unique (company_id, id);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'routes_company_id_id_unique'
      and conrelid = 'public.routes'::regclass
  ) then
    alter table public.routes
    add constraint routes_company_id_id_unique unique (company_id, id);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'expense_types_company_id_id_unique'
      and conrelid = 'public.expense_types'::regclass
  ) then
    alter table public.expense_types
    add constraint expense_types_company_id_id_unique unique (company_id, id);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'payment_methods_company_id_id_unique'
      and conrelid = 'public.payment_methods'::regclass
  ) then
    alter table public.payment_methods
    add constraint payment_methods_company_id_id_unique unique (company_id, id);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trips_company_id_id_unique'
      and conrelid = 'public.trips'::regclass
  ) then
    alter table public.trips
    add constraint trips_company_id_id_unique unique (company_id, id);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'invoices_company_id_id_unique'
      and conrelid = 'public.invoices'::regclass
  ) then
    alter table public.invoices
    add constraint invoices_company_id_id_unique unique (company_id, id);
  end if;
end $$;

-- =========================================================
-- 2. Add company-scoped foreign keys for trips
-- =========================================================

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'trips_company_customer_fk'
      and conrelid = 'public.trips'::regclass
  ) then
    alter table public.trips
    add constraint trips_company_customer_fk
    foreign key (company_id, customer_id)
    references public.customers(company_id, id)
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trips_company_driver_fk'
      and conrelid = 'public.trips'::regclass
  ) then
    alter table public.trips
    add constraint trips_company_driver_fk
    foreign key (company_id, driver_id)
    references public.drivers(company_id, id)
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trips_company_tractor_fk'
      and conrelid = 'public.trips'::regclass
  ) then
    alter table public.trips
    add constraint trips_company_tractor_fk
    foreign key (company_id, tractor_head_id)
    references public.tractor_heads(company_id, id)
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trips_company_trailer_fk'
      and conrelid = 'public.trips'::regclass
  ) then
    alter table public.trips
    add constraint trips_company_trailer_fk
    foreign key (company_id, trailer_id)
    references public.trailers(company_id, id)
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trips_company_route_fk'
      and conrelid = 'public.trips'::regclass
  ) then
    alter table public.trips
    add constraint trips_company_route_fk
    foreign key (company_id, route_id)
    references public.routes(company_id, id)
    not valid;
  end if;
end $$;

-- =========================================================
-- 3. Add company-scoped foreign keys for operations tables
-- =========================================================

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'trip_status_history_company_trip_fk'
      and conrelid = 'public.trip_status_history'::regclass
  ) then
    alter table public.trip_status_history
    add constraint trip_status_history_company_trip_fk
    foreign key (company_id, trip_id)
    references public.trips(company_id, id)
    on delete cascade
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trip_expenses_company_trip_fk'
      and conrelid = 'public.trip_expenses'::regclass
  ) then
    alter table public.trip_expenses
    add constraint trip_expenses_company_trip_fk
    foreign key (company_id, trip_id)
    references public.trips(company_id, id)
    on delete cascade
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'trip_expenses_company_type_fk'
      and conrelid = 'public.trip_expenses'::regclass
  ) then
    alter table public.trip_expenses
    add constraint trip_expenses_company_type_fk
    foreign key (company_id, expense_type_id)
    references public.expense_types(company_id, id)
    not valid;
  end if;
end $$;

-- =========================================================
-- 4. Add company-scoped foreign keys for finance tables
-- =========================================================

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'invoices_company_customer_fk'
      and conrelid = 'public.invoices'::regclass
  ) then
    alter table public.invoices
    add constraint invoices_company_customer_fk
    foreign key (company_id, customer_id)
    references public.customers(company_id, id)
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'invoice_trips_company_invoice_fk'
      and conrelid = 'public.invoice_trips'::regclass
  ) then
    alter table public.invoice_trips
    add constraint invoice_trips_company_invoice_fk
    foreign key (company_id, invoice_id)
    references public.invoices(company_id, id)
    on delete cascade
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'invoice_trips_company_trip_fk'
      and conrelid = 'public.invoice_trips'::regclass
  ) then
    alter table public.invoice_trips
    add constraint invoice_trips_company_trip_fk
    foreign key (company_id, trip_id)
    references public.trips(company_id, id)
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'payments_company_invoice_fk'
      and conrelid = 'public.payments'::regclass
  ) then
    alter table public.payments
    add constraint payments_company_invoice_fk
    foreign key (company_id, invoice_id)
    references public.invoices(company_id, id)
    on delete set null
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'payments_company_customer_fk'
      and conrelid = 'public.payments'::regclass
  ) then
    alter table public.payments
    add constraint payments_company_customer_fk
    foreign key (company_id, customer_id)
    references public.customers(company_id, id)
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'payments_company_method_fk'
      and conrelid = 'public.payments'::regclass
  ) then
    alter table public.payments
    add constraint payments_company_method_fk
    foreign key (company_id, payment_method_id)
    references public.payment_methods(company_id, id)
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'driver_advances_company_driver_fk'
      and conrelid = 'public.driver_advances'::regclass
  ) then
    alter table public.driver_advances
    add constraint driver_advances_company_driver_fk
    foreign key (company_id, driver_id)
    references public.drivers(company_id, id)
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'driver_deductions_company_driver_fk'
      and conrelid = 'public.driver_deductions'::regclass
  ) then
    alter table public.driver_deductions
    add constraint driver_deductions_company_driver_fk
    foreign key (company_id, driver_id)
    references public.drivers(company_id, id)
    not valid;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'driver_deductions_company_trip_fk'
      and conrelid = 'public.driver_deductions'::regclass
  ) then
    alter table public.driver_deductions
    add constraint driver_deductions_company_trip_fk
    foreign key (company_id, trip_id)
    references public.trips(company_id, id)
    on delete set null
    not valid;
  end if;
end $$;

-- =========================================================
-- 5. Validate constraints
-- =========================================================

alter table public.trips validate constraint trips_company_customer_fk;
alter table public.trips validate constraint trips_company_driver_fk;
alter table public.trips validate constraint trips_company_tractor_fk;
alter table public.trips validate constraint trips_company_trailer_fk;
alter table public.trips validate constraint trips_company_route_fk;

alter table public.trip_status_history validate constraint trip_status_history_company_trip_fk;
alter table public.trip_expenses validate constraint trip_expenses_company_trip_fk;
alter table public.trip_expenses validate constraint trip_expenses_company_type_fk;

alter table public.invoices validate constraint invoices_company_customer_fk;
alter table public.invoice_trips validate constraint invoice_trips_company_invoice_fk;
alter table public.invoice_trips validate constraint invoice_trips_company_trip_fk;

alter table public.payments validate constraint payments_company_invoice_fk;
alter table public.payments validate constraint payments_company_customer_fk;
alter table public.payments validate constraint payments_company_method_fk;

alter table public.driver_advances validate constraint driver_advances_company_driver_fk;
alter table public.driver_deductions validate constraint driver_deductions_company_driver_fk;
alter table public.driver_deductions validate constraint driver_deductions_company_trip_fk;

-- =========================================================
-- 6. Notes
-- =========================================================

-- This migration intentionally adds constraints without changing the original V1 schema file.
-- If validation fails, existing data must be checked for cross-company references before retrying.