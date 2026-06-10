create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  name text not null,
  contact_person text,
  phone text,
  email text,
  tax_registration_number text,
  address text,
  city text,
  country text,
  credit_limit numeric(14, 2),
  is_active boolean not null default true,
  created_by uuid references auth.users(id),
  updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint customers_company_name_unique unique (company_id, name),
  constraint customers_credit_limit_non_negative check (
    credit_limit is null or credit_limit >= 0
  )
);

create index if not exists customers_company_id_idx
  on public.customers(company_id);

create index if not exists customers_company_active_idx
  on public.customers(company_id, is_active);

alter table public.customers enable row level security;

drop policy if exists "Company members can read customers" on public.customers;
create policy "Company members can read customers"
  on public.customers
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.company_users company_user
      where company_user.company_id = customers.company_id
        and company_user.user_id = auth.uid()
        and company_user.is_active = true
    )
  );

drop policy if exists "Allowed company roles can create customers" on public.customers;
create policy "Allowed company roles can create customers"
  on public.customers
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.company_users company_user
      where company_user.company_id = customers.company_id
        and company_user.user_id = auth.uid()
        and company_user.is_active = true
        and company_user.role in ('owner', 'admin', 'operations')
    )
  );

drop policy if exists "Allowed company roles can update customers" on public.customers;
create policy "Allowed company roles can update customers"
  on public.customers
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.company_users company_user
      where company_user.company_id = customers.company_id
        and company_user.user_id = auth.uid()
        and company_user.is_active = true
        and company_user.role in ('owner', 'admin', 'operations')
    )
  )
  with check (
    exists (
      select 1
      from public.company_users company_user
      where company_user.company_id = customers.company_id
        and company_user.user_id = auth.uid()
        and company_user.is_active = true
        and company_user.role in ('owner', 'admin', 'operations')
    )
  );
