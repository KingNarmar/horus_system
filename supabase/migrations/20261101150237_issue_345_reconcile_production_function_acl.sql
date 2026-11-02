-- Issue #345 — migration-history compatibility checkpoint (20261101150237_issue_345_reconcile_production_function_acl.sql).
-- Verify already-correct public function EXECUTE/default ACLs; no mutations.
-- Production ALREADY applied the original, state-changing migration under
-- this exact version during the 2026-11-01 cutover recovery.
-- Exact original SQL is preserved, UNMODIFIED, at:
-- scripts/release/issue_345_applied_production_migrations/20261101150237_issue_345_reconcile_production_function_acl.sql
--
-- Development already has these permissions from its frozen baseline.
-- This version is a READ-ONLY, FAIL-CLOSED state assertion for Development
-- and clean instances. No Production repair SQL must be replayed there.
-- If the expected baseline differs, STOP and reconcile explicitly;
-- do not silently broaden ACLs, change RLS, or repair migration history.
-- Applied Production version remains registered; this file is not re-run.

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
