-- Issue #10 — Allow company members to read basic profile details
--
-- Problem:
-- Company Users page needs to display human-readable user details instead of
-- raw auth UUIDs. The app reads public.user_profiles for users who belong to
-- the same company, but authenticated users may not have SELECT permission or
-- an RLS policy that allows shared-company profile reads.
--
-- Security intent:
-- - Authenticated users may read basic profile rows only for users who share at
--   least one active company membership with them.
-- - This supports company user lists without exposing auth.users directly.
-- - Sensitive permissions remain controlled by company_users RLS and role rules.

-- Required table privilege. RLS still controls which rows are visible.
grant select on table public.user_profiles to authenticated;

-- Keep existing policy for own profile / platform admin.
-- Add shared-company visibility for members of the same active company.
drop policy if exists user_profiles_select_shared_company_members
on public.user_profiles;

create policy user_profiles_select_shared_company_members
on public.user_profiles
for select
to authenticated
using (
  exists (
    select 1
    from public.company_users viewer_membership
    join public.company_users target_membership
      on target_membership.company_id = viewer_membership.company_id
    where viewer_membership.user_id = auth.uid()
      and viewer_membership.is_active = true
      and target_membership.user_id = user_profiles.id
      and target_membership.is_active = true
  )
);
