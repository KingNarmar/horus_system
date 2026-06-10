alter table public.customers
  add column if not exists contact_person text,
  add column if not exists phone text,
  add column if not exists email text,
  add column if not exists tax_registration_number text,
  add column if not exists address text,
  add column if not exists city text,
  add column if not exists country text,
  add column if not exists credit_limit numeric(14, 2),
  add column if not exists is_active boolean not null default true,
  add column if not exists created_by uuid references auth.users(id),
  add column if not exists updated_by uuid references auth.users(id),
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create index if not exists customers_company_id_idx
  on public.customers(company_id);

create index if not exists customers_company_active_idx
  on public.customers(company_id, is_active);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'customers_credit_limit_non_negative'
  ) then
    alter table public.customers
      add constraint customers_credit_limit_non_negative
      check (credit_limit is null or credit_limit >= 0);
  end if;
end $$;
