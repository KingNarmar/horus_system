-- Issue #345 — portability-safe reconciliation of the canonical Dev function ACLs.
-- PROVENANCE: Exact statements applied in Production on 2026-11-01 remain
-- archived in scripts/release/issue_345_applied_production_migrations/20261101150237_issue_345_reconcile_production_function_acl.sql
-- Production already records this migration version and will not rerun it.
--
-- On already-correct Development: a no-op, followed by strict verification.
-- On a fresh CLI migration replay: permit remediation ONLY for the observed
-- well-defined broader SQL function-grant preimage. Anything else fails closed.
-- The repair changes EXECUTE grants/defaults only; never data, RLS or users.
-- Reviewer note: replayed migration SQL differs intentionally from archived
-- Production historical SQL. See migration archive README.

DO $issue_345_function_repair$
DECLARE
  v_digest text;
  v_postgres integer;
  v_auth integer;
  v_service integer;
  v_anon integer;
  v_public integer;
  v_secdef_anon integer;
  v_secdef_auth integer;
  v_secdef_service integer;
BEGIN
  WITH funcs AS (
  SELECT n.nspname,p.proname,pg_get_function_identity_arguments(p.oid) identity_args,
    (SELECT COALESCE(string_agg(COALESCE(r.rolname,'PUBLIC')||':'||x.privilege_type||':'||x.is_grantable::text,
         ',' ORDER BY COALESCE(r.rolname,'PUBLIC'),x.privilege_type,x.is_grantable),'')
     FROM aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) x
     LEFT JOIN pg_roles r ON r.oid=x.grantee) acl
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.prokind='f'
)
SELECT md5(string_agg(nspname||'.'||proname||'('||identity_args||')='||acl,
                      chr(10) ORDER BY nspname,proname,identity_args))
INTO v_digest FROM funcs;

  IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
      WHERE n.nspname='public' AND p.prokind='f') <> 63
    OR (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
        WHERE n.nspname='public' AND p.prokind='f' AND p.prosecdef) <> 56
  THEN
    RAISE EXCEPTION 'Issue #345: public function inventory drift';
  END IF;

  IF v_digest = 'da4e478fae96c1e5f406388f96191816' THEN
    RETURN; -- Development/post-repair state; no ACL mutations.
  END IF;

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

  IF (v_postgres,v_auth,v_service,v_anon,v_public)
       IS DISTINCT FROM (63,57,59,1,1)
    OR (v_secdef_anon,v_secdef_auth,v_secdef_service)
       IS DISTINCT FROM (0,51,53)
    OR (SELECT count(*) FROM pg_default_acl d JOIN pg_namespace n ON n.oid=d.defaclnamespace
        WHERE n.nspname='public' AND d.defaclrole='postgres'::regrole
          AND d.defaclobjtype='f') <> 1
  THEN
    RAISE EXCEPTION 'Issue #345: unknown function ACL preimage; refusing to reconcile';
  END IF;

  EXECUTE $ddl$ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon, authenticated, service_role$ddl$;
  EXECUTE $ddl$REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public
  FROM PUBLIC, anon, authenticated, service_role$ddl$;
  EXECUTE $ddl$GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated$ddl$;
  EXECUTE $ddl$REVOKE EXECUTE ON FUNCTION public.handle_new_user_profile() FROM authenticated$ddl$;
  EXECUTE $ddl$REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM authenticated$ddl$;
  EXECUTE $ddl$REVOKE EXECUTE ON FUNCTION public.seed_default_company_expense_categories_for_company() FROM authenticated$ddl$;
  EXECUTE $ddl$REVOKE EXECUTE ON FUNCTION public.seed_default_expense_types_for_company() FROM authenticated$ddl$;
  EXECUTE $ddl$REVOKE EXECUTE ON FUNCTION public.update_company_regional_settings(uuid,text,smallint,text) FROM authenticated$ddl$;
  EXECUTE $ddl$REVOKE EXECUTE ON FUNCTION public.set_updated_at() FROM authenticated$ddl$;
  EXECUTE $ddl$REVOKE EXECUTE ON FUNCTION public.sync_driver_name_fields() FROM authenticated$ddl$;
  EXECUTE $ddl$GRANT EXECUTE ON FUNCTION public.set_updated_at() TO PUBLIC$ddl$;
  EXECUTE $ddl$GRANT EXECUTE ON FUNCTION public.sync_driver_name_fields() TO PUBLIC$ddl$;
  EXECUTE $ddl$GRANT EXECUTE ON FUNCTION public.create_expense_ledger_entry(
  uuid,uuid,bigint,text,integer,date,text,uuid,uuid,uuid,uuid,text,text,text
) TO service_role$ddl$;
  EXECUTE $ddl$GRANT EXECUTE ON FUNCTION public.get_dashboard_source(uuid) TO service_role$ddl$;
  EXECUTE $ddl$GRANT EXECUTE ON FUNCTION public.get_trip_expenses_report_source(uuid,date,date) TO service_role$ddl$;
  EXECUTE $ddl$GRANT EXECUTE ON FUNCTION public.get_trip_net_profit_report_source(uuid,date,date) TO service_role$ddl$;
  EXECUTE $ddl$GRANT EXECUTE ON FUNCTION public.void_expense_ledger_entry(uuid,uuid,text) TO service_role$ddl$;
END $issue_345_function_repair$;

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

  IF (WITH funcs AS (
  SELECT n.nspname,p.proname,pg_get_function_identity_arguments(p.oid) identity_args,
    (SELECT COALESCE(string_agg(COALESCE(r.rolname,'PUBLIC')||':'||x.privilege_type||':'||x.is_grantable::text,
         ',' ORDER BY COALESCE(r.rolname,'PUBLIC'),x.privilege_type,x.is_grantable),'')
     FROM aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) x
     LEFT JOIN pg_roles r ON r.oid=x.grantee) acl
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public' AND p.prokind='f'
)
SELECT md5(string_agg(nspname||'.'||proname||'('||identity_args||')='||acl,
                      chr(10) ORDER BY nspname,proname,identity_args))
FROM funcs) IS DISTINCT FROM 'da4e478fae96c1e5f406388f96191816' THEN
    RAISE EXCEPTION 'Issue #345 function ACL per-signature drift';
  END IF;
END $verify$;
