-- H.O.R.U.S System — Audit Logs Foundation
-- Issue #38: app-wide audit and accountability trail.

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  actor_role text,
  module text not null,
  entity_type text not null,
  entity_id text not null,
  action text not null,
  description text not null,
  old_values jsonb,
  new_values jsonb,
  metadata jsonb,
  created_at timestamptz not null default now(),
  constraint audit_logs_module_not_empty check (length(trim(module)) > 0),
  constraint audit_logs_entity_type_not_empty check (length(trim(entity_type)) > 0),
  constraint audit_logs_entity_id_not_empty check (length(trim(entity_id)) > 0),
  constraint audit_logs_action_not_empty check (length(trim(action)) > 0),
  constraint audit_logs_description_not_empty check (length(trim(description)) > 0)
);

create index if not exists idx_audit_logs_company_id on public.audit_logs(company_id);
create index if not exists idx_audit_logs_actor_user_id on public.audit_logs(actor_user_id);
create index if not exists idx_audit_logs_module on public.audit_logs(module);
create index if not exists idx_audit_logs_entity on public.audit_logs(entity_type, entity_id);
create index if not exists idx_audit_logs_action on public.audit_logs(action);
create index if not exists idx_audit_logs_created_at on public.audit_logs(created_at desc);

alter table public.audit_logs enable row level security;

drop policy if exists audit_logs_select_owner_admin_or_platform_admin on public.audit_logs;
create policy audit_logs_select_owner_admin_or_platform_admin
on public.audit_logs
for select
to authenticated
using (
  private.has_company_role(company_id, array['owner','admin']::public.company_role[])
  or private.is_platform_admin()
);

drop policy if exists audit_logs_insert_company_members on public.audit_logs;
create policy audit_logs_insert_company_members
on public.audit_logs
for insert
to authenticated
with check (
  auth.uid() is not null
  and private.is_company_member(company_id)
  and (actor_user_id is null or actor_user_id = auth.uid())
);

grant select, insert on table public.audit_logs to authenticated;
