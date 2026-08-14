alter table public.subscription_plans enable row level security;
alter table public.company_subscriptions enable row level security;

revoke all on table public.subscription_plans from anon;
revoke all on table public.company_subscriptions from anon;
revoke insert, update, delete on table public.subscription_plans from authenticated;
revoke insert, update, delete on table public.company_subscriptions from authenticated;

grant select on table public.subscription_plans to authenticated;
grant select on table public.company_subscriptions to authenticated;

drop policy if exists company_subscriptions_select_company_members on public.company_subscriptions;
drop policy if exists company_subscriptions_manage_owner_admin_or_platform_admin on public.company_subscriptions;

create policy company_subscriptions_select_owner_or_platform_admin
on public.company_subscriptions
for select
to authenticated
using (
  private.has_company_role(
    company_id,
    array['owner'::public.company_role]
  )
  or private.is_platform_admin()
);

create policy company_subscriptions_insert_owner_admin_or_platform_admin
on public.company_subscriptions
for insert
to authenticated
with check (
  private.has_company_role(
    company_id,
    array['owner'::public.company_role, 'admin'::public.company_role]
  )
  or private.is_platform_admin()
);

create policy company_subscriptions_update_owner_admin_or_platform_admin
on public.company_subscriptions
for update
to authenticated
using (
  private.has_company_role(
    company_id,
    array['owner'::public.company_role, 'admin'::public.company_role]
  )
  or private.is_platform_admin()
)
with check (
  private.has_company_role(
    company_id,
    array['owner'::public.company_role, 'admin'::public.company_role]
  )
  or private.is_platform_admin()
);

create policy company_subscriptions_delete_owner_admin_or_platform_admin
on public.company_subscriptions
for delete
to authenticated
using (
  private.has_company_role(
    company_id,
    array['owner'::public.company_role, 'admin'::public.company_role]
  )
  or private.is_platform_admin()
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'company_subscriptions_company_id_key'
      and conrelid = 'public.company_subscriptions'::regclass
  ) then
    alter table public.company_subscriptions
      add constraint company_subscriptions_company_id_key unique (company_id);
  end if;
end $$;

create index if not exists idx_company_subscriptions_plan_id
on public.company_subscriptions (plan_id);
