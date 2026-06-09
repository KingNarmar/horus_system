-- Issue #8 — Fix initial owner RLS check for company onboarding
--
-- Problem:
-- The app can insert into public.companies, but inserting the initial owner row
-- into public.company_users can fail with:
--   new row violates row-level security policy for table "company_users"
--
-- Root cause:
-- The original company_users insert policy checks public.companies directly.
-- During initial onboarding, the user is not yet a company member, so company
-- membership-based company SELECT policies can prevent that check from seeing
-- the newly created company.
--
-- Fix:
-- Create a private SECURITY DEFINER helper that verifies whether the current
-- authenticated user created the target company, then use it inside the
-- company_users insert policy.

create or replace function private.user_created_company(target_company_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.companies c
    where c.id = target_company_id
      and c.created_by = auth.uid()
  );
$$;

revoke all on function private.user_created_company(uuid) from public;
grant execute on function private.user_created_company(uuid) to authenticated;

drop policy if exists company_users_insert_initial_owner_or_admin
on public.company_users;

create policy company_users_insert_initial_owner_or_admin
on public.company_users
for insert
to authenticated
with check (
  private.is_platform_admin()
  or (
    user_id = auth.uid()
    and role = 'owner'
    and private.user_created_company(company_id)
  )
  or private.has_company_role(company_id, array['owner','admin']::public.company_role[])
);
