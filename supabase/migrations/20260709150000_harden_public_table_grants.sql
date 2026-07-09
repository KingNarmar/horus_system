-- Harden existing public table grants for SaaS tenant isolation.
--
-- The application grants table access explicitly per migration and relies on RLS
-- for tenant isolation. Public client roles must not keep broad or destructive
-- table privileges on existing business tables.
--
-- Note: default privileges are intentionally not changed here because Supabase
-- SQL execution may not be allowed to alter default privileges for roles such as
-- supabase_admin from the migration/runtime role. Default ACL hardening must be
-- handled through an owner-supported/admin-supported workflow if required.

begin;

-- Existing tables: anonymous users must not have direct table privileges.
revoke all privileges on all tables in schema public from anon;

-- Existing tables: authenticated users keep business-required SELECT/INSERT/UPDATE
-- grants that are already managed by table-specific migrations and RLS policies,
-- but must not be able to perform destructive or schema-adjacent table actions.
revoke delete, truncate, references, trigger, maintain
on all tables in schema public
from authenticated;

commit;
