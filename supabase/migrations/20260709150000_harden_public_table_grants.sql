-- Harden public table grants for SaaS tenant isolation.
--
-- The application grants table access explicitly per migration and relies on RLS
-- for tenant isolation. Public roles must not inherit broad or destructive table
-- privileges from default ACLs.

begin;

-- Existing tables: anonymous users must not have direct table privileges.
revoke all privileges on all tables in schema public from anon;

-- Existing tables: authenticated users keep business-required SELECT/INSERT/UPDATE
-- grants that are already managed by table-specific migrations and RLS policies,
-- but must not be able to perform destructive or schema-adjacent table actions.
revoke delete, truncate, references, trigger, maintain
on all tables in schema public
from authenticated;

-- Future tables created by the standard migration owner must not automatically
-- grant table privileges to public client roles. Every table migration should grant
-- only the exact privileges required by the feature after RLS is enabled.
alter default privileges for role postgres in schema public
revoke all privileges on tables from anon;

alter default privileges for role postgres in schema public
revoke all privileges on tables from authenticated;

-- Future tables created by Supabase-owned/admin flows must follow the same rule:
-- no implicit table grants to client roles. Feature migrations remain responsible
-- for explicit grants and RLS policies.
alter default privileges for role supabase_admin in schema public
revoke all privileges on tables from anon;

alter default privileges for role supabase_admin in schema public
revoke all privileges on tables from authenticated;

commit;
