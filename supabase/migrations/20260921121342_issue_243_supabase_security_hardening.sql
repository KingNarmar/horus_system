-- Issue #243: Supabase Security Advisor hardening.
--
-- Scope:
-- 1. Pin mutable trigger-function search_path values.
-- 2. Remove direct API-role EXECUTE access from infrastructure-only
--    SECURITY DEFINER trigger/event-trigger functions.
--
-- These functions remain available to their existing database triggers.
-- No application RPC contract or table/RLS policy is broadened here.

BEGIN;

ALTER FUNCTION public.set_updated_at()
  SET search_path TO pg_catalog;

ALTER FUNCTION public.sync_driver_name_fields()
  SET search_path TO pg_catalog;

REVOKE ALL ON FUNCTION public.handle_new_user_profile()
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.handle_new_user_profile()
  FROM anon;
REVOKE ALL ON FUNCTION public.handle_new_user_profile()
  FROM authenticated;
REVOKE ALL ON FUNCTION public.handle_new_user_profile()
  FROM service_role;

REVOKE ALL ON FUNCTION public.rls_auto_enable()
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.rls_auto_enable()
  FROM anon;
REVOKE ALL ON FUNCTION public.rls_auto_enable()
  FROM authenticated;
REVOKE ALL ON FUNCTION public.rls_auto_enable()
  FROM service_role;

REVOKE ALL ON FUNCTION public.seed_default_company_expense_categories_for_company()
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.seed_default_company_expense_categories_for_company()
  FROM anon;
REVOKE ALL ON FUNCTION public.seed_default_company_expense_categories_for_company()
  FROM authenticated;
REVOKE ALL ON FUNCTION public.seed_default_company_expense_categories_for_company()
  FROM service_role;

COMMIT;
