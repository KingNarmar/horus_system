-- H.O.R.U.S System — Audit display snapshots
-- Issue #40: Customer details and activity timeline.

alter table public.audit_logs
  add column if not exists actor_display_name text,
  add column if not exists actor_email text,
  add column if not exists entity_display_name text;

update public.audit_logs al
set
  actor_display_name = coalesce(
    (
      select nullif(trim(up.full_name), '')
      from public.user_profiles up
      where up.id = al.actor_user_id
    ),
    (
      select au.email
      from auth.users au
      where au.id = al.actor_user_id
    ),
    nullif(trim(al.actor_role), ''),
    'Unknown user'
  ),
  actor_email = coalesce(
    (
      select au.email
      from auth.users au
      where au.id = al.actor_user_id
    ),
    al.actor_email
  ),
  entity_display_name = coalesce(
    nullif(trim(al.new_values ->> 'name'), ''),
    nullif(trim(al.old_values ->> 'name'), ''),
    al.entity_display_name
  )
where al.actor_display_name is null
   or al.actor_email is null
   or al.entity_display_name is null;
