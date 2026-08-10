-- H.O.R.U.S System — Issue #46 Payment Methods management foundation
--
-- Keeps payment methods company-scoped, prevents normalized duplicate names,
-- enables authenticated read/manage privileges subject to RLS, and preserves
-- the no-hard-delete contract.

begin;

-- Fail safely if legacy data contains names that would collide after
-- whitespace/case normalization. The live table was verified empty before
-- this migration was authored, but this guard protects other environments.
do $$
begin
  if exists (
    select 1
    from public.payment_methods
    group by company_id, lower(btrim(name))
    having count(*) > 1
  ) then
    raise exception
      'payment_methods contains duplicate names after normalization';
  end if;
end
$$;

-- Replace the case-sensitive uniqueness rule with tenant-scoped normalized
-- uniqueness. This prevents values such as Cash, cash, and " Cash " from
-- coexisting for the same company without introducing a citext dependency.
alter table public.payment_methods
  drop constraint if exists payment_methods_unique_name_per_company;

drop index if exists public.payment_methods_unique_normalized_name_per_company;

create unique index payment_methods_unique_normalized_name_per_company
  on public.payment_methods (company_id, lower(btrim(name)));

-- RLS remains the security boundary for row access. Re-assert the intended
-- policies so Issue #46 has a reproducible company/role contract.
alter table public.payment_methods enable row level security;

drop policy if exists payment_methods_select_members
  on public.payment_methods;
create policy payment_methods_select_members
  on public.payment_methods
  for select
  to authenticated
  using (private.is_company_member(company_id));

drop policy if exists payment_methods_insert_accounting
  on public.payment_methods;
create policy payment_methods_insert_accounting
  on public.payment_methods
  for insert
  to authenticated
  with check (
    private.has_company_role(
      company_id,
      array[
        'owner'::public.company_role,
        'admin'::public.company_role,
        'accountant'::public.company_role
      ]
    )
  );

drop policy if exists payment_methods_update_accounting
  on public.payment_methods;
create policy payment_methods_update_accounting
  on public.payment_methods
  for update
  to authenticated
  using (
    private.has_company_role(
      company_id,
      array[
        'owner'::public.company_role,
        'admin'::public.company_role,
        'accountant'::public.company_role
      ]
    )
  )
  with check (
    private.has_company_role(
      company_id,
      array[
        'owner'::public.company_role,
        'admin'::public.company_role,
        'accountant'::public.company_role
      ]
    )
  );

-- Tight grants: authenticated users may read/create/update only. RLS narrows
-- those privileges by tenant and role. Hard delete remains unavailable.
revoke all privileges on table public.payment_methods from public;
revoke all privileges on table public.payment_methods from anon;
revoke all privileges on table public.payment_methods from authenticated;

grant select, insert, update
  on table public.payment_methods
  to authenticated;

commit;
