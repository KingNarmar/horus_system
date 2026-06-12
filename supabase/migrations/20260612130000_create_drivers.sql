create table if not exists public.drivers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  full_name text not null,
  phone text,
  national_id text,
  license_number text,
  license_expiry_date date,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint drivers_full_name_not_empty check (length(btrim(full_name)) > 0)
);

create index if not exists drivers_company_id_idx on public.drivers(company_id);
create index if not exists drivers_company_active_idx on public.drivers(company_id, is_active);
create unique index if not exists drivers_company_license_number_unique_idx
  on public.drivers(company_id, license_number)
  where license_number is not null;

alter table public.drivers enable row level security;

revoke all on table public.drivers from anon;
revoke all on table public.drivers from authenticated;
grant select, insert, update on table public.drivers to authenticated;

drop policy if exists drivers_select_company_members on public.drivers;
create policy drivers_select_company_members
  on public.drivers
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.company_users cu
      where cu.company_id = drivers.company_id
        and cu.user_id = auth.uid()
        and cu.is_active = true
    )
  );

drop policy if exists drivers_insert_operations on public.drivers;
create policy drivers_insert_operations
  on public.drivers
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.company_users cu
      where cu.company_id = drivers.company_id
        and cu.user_id = auth.uid()
        and cu.is_active = true
        and cu.role::text in ('owner', 'admin', 'operations')
    )
  );

drop policy if exists drivers_update_operations on public.drivers;
create policy drivers_update_operations
  on public.drivers
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.company_users cu
      where cu.company_id = drivers.company_id
        and cu.user_id = auth.uid()
        and cu.is_active = true
        and cu.role::text in ('owner', 'admin', 'operations')
    )
  )
  with check (
    exists (
      select 1
      from public.company_users cu
      where cu.company_id = drivers.company_id
        and cu.user_id = auth.uid()
        and cu.is_active = true
        and cu.role::text in ('owner', 'admin', 'operations')
    )
  );
