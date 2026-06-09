-- Issue #8 — Grant company onboarding table permissions
--
-- Purpose:
-- Enable authenticated users to run the company onboarding flow while keeping
-- tenant protection enforced by Row Level Security policies.
--
-- Why this is needed:
-- RLS policies decide which rows are allowed, but PostgreSQL table privileges
-- are still required before those policies can be evaluated by the API role.

-- Allow authenticated users to access the public schema objects exposed by PostgREST.
grant usage on schema public to authenticated;

-- Companies:
-- Required for:
-- - selecting companies visible through RLS
-- - inserting the first company where created_by = auth.uid()
-- - future owner/admin updates guarded by RLS
grant select, insert, update on table public.companies to authenticated;

-- Company users:
-- Required for:
-- - inserting the initial owner row after company creation
-- - selecting company membership through RLS
-- - future owner/admin role updates guarded by RLS
grant select, insert, update on table public.company_users to authenticated;
