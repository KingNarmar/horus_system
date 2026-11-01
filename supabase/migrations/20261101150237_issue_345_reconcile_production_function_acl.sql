-- Issue #345: restore Production public-function grants to the reviewed
-- Development baseline after the full-schema Production rebuild.
-- Source: Dev zwnfmszssxtfxkaofnhq, frozen 2026-10-30.
-- Scope: public function EXECUTE ACLs and postgres/public function defaults ONLY.
-- No table, RLS, data, auth-user, storage, realtime, or cron mutations.
-- Run as a single tracked Supabase migration; fail closed on drift.
--
-- Baseline: 63 public functions (56 SECURITY DEFINER).
-- Explicit EXECUTE ACL counts by grantee:
--   postgres 63, authenticated 56, service_role 5, PUBLIC 2, anon 0.
-- SECURITY DEFINER effective EXECUTE:
--   anon 0, authenticated 51, service_role 3.

DO $preflight$
BEGIN
  IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
      WHERE n.nspname='public' AND p.prokind='f') <> 63
    OR (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
        WHERE n.nspname='public' AND p.prokind='f' AND p.prosecdef) <> 56
  THEN
    RAISE EXCEPTION 'Issue #345: public function catalog drift; no grants modified';
  END IF;
  IF (SELECT count(*) FROM pg_default_acl d JOIN pg_namespace n ON n.oid=d.defaclnamespace
      WHERE n.nspname='public' AND d.defaclrole='postgres'::regrole
        AND d.defaclobjtype='f') <> 1
  THEN
    RAISE EXCEPTION 'Issue #345: postgres/public default-function ACL drift';
  END IF;
END $preflight$;

-- The rebuilt Production database retained a pre-existing postgres/public
-- default granting EXECUTE to anon/authenticated/service_role. Dev has only
-- the postgres owner grant. Do not touch supabase_admin defaults.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon, authenticated, service_role;

-- Restore exact explicitly reviewed public-function grants.
-- The function bodies and security model are unchanged.
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- These five functions have no non-owner explicit EXECUTE grant in Dev.
REVOKE EXECUTE ON FUNCTION public.handle_new_user_profile() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.seed_default_company_expense_categories_for_company() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.seed_default_expense_types_for_company() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.update_company_regional_settings(uuid,text,smallint,text) FROM authenticated;

-- These two trigger helpers are granted to PUBLIC in Dev, not by
-- role-specific authenticated/anon ACL entries.
REVOKE EXECUTE ON FUNCTION public.set_updated_at() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.sync_driver_name_fields() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.set_updated_at() TO PUBLIC;
GRANT EXECUTE ON FUNCTION public.sync_driver_name_fields() TO PUBLIC;

-- Five narrowly identified service_role grants present on Dev.
GRANT EXECUTE ON FUNCTION public.create_expense_ledger_entry(
  uuid,uuid,bigint,text,integer,date,text,uuid,uuid,uuid,uuid,text,text,text
) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_dashboard_source(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_trip_expenses_report_source(uuid,date,date) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_trip_net_profit_report_source(uuid,date,date) TO service_role;
GRANT EXECUTE ON FUNCTION public.void_expense_ledger_entry(uuid,uuid,text) TO service_role;

DO $verify$
DECLARE
  v_postgres integer;
  v_auth integer;
  v_service integer;
  v_anon integer;
  v_public integer;
  v_secdef_anon integer;
  v_secdef_auth integer;
  v_secdef_service integer;
BEGIN
  SELECT
    count(*) FILTER (WHERE x.grantee='postgres'::regrole),
    count(*) FILTER (WHERE x.grantee='authenticated'::regrole),
    count(*) FILTER (WHERE x.grantee='service_role'::regrole),
    count(*) FILTER (WHERE x.grantee='anon'::regrole),
    count(*) FILTER (WHERE x.grantee=0)
  INTO v_postgres,v_auth,v_service,v_anon,v_public
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) x
  WHERE n.nspname='public' AND p.prokind='f' AND x.privilege_type='EXECUTE';

  SELECT
    count(*) FILTER (WHERE has_function_privilege('anon',p.oid,'EXECUTE')),
    count(*) FILTER (WHERE has_function_privilege('authenticated',p.oid,'EXECUTE')),
    count(*) FILTER (WHERE has_function_privilege('service_role',p.oid,'EXECUTE'))
  INTO v_secdef_anon,v_secdef_auth,v_secdef_service
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.prokind='f' AND p.prosecdef;

  IF (v_postgres,v_auth,v_service,v_anon,v_public) IS DISTINCT FROM (63,56,5,0,2)
     OR (v_secdef_anon,v_secdef_auth,v_secdef_service) IS DISTINCT FROM (0,51,3)
  THEN
    RAISE EXCEPTION 'Issue #345 ACL verification failed: grants=(%,%,%,%,%) definer=(%,%,%)',
      v_postgres,v_auth,v_service,v_anon,v_public,
      v_secdef_anon,v_secdef_auth,v_secdef_service;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_default_acl d JOIN pg_namespace n ON n.oid=d.defaclnamespace
    CROSS JOIN LATERAL aclexplode(d.defaclacl) x
    WHERE n.nspname='public' AND d.defaclrole='postgres'::regrole
      AND d.defaclobjtype='f' AND x.grantee <> 'postgres'::regrole
  ) THEN
    RAISE EXCEPTION 'Issue #345: postgres/public default-function grants still too broad';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) x
    WHERE n.nspname='public' AND p.prokind='f'
      AND (x.privilege_type <> 'EXECUTE' OR x.is_grantable)
  ) THEN
    RAISE EXCEPTION 'Issue #345: unexpected function privilege/grant option';
  END IF;
END $verify$;
