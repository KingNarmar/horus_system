-- Issue #345 — migration-history compatibility checkpoint (20261101155147_issue_345_restore_column_acl.sql).
-- Verify already-correct column grants and table/RLS safety; no mutations.
-- Production ALREADY applied the original, state-changing migration under
-- this exact version during the 2026-11-01 cutover recovery.
-- Exact original SQL is preserved, UNMODIFIED, at:
-- scripts/release/issue_345_applied_production_migrations/20261101155147_issue_345_restore_column_acl.sql
--
-- Development already has these permissions from its frozen baseline.
-- This version is a READ-ONLY, FAIL-CLOSED state assertion for Development
-- and clean instances. No Production repair SQL must be replayed there.
-- If the expected baseline differs, STOP and reconcile explicitly;
-- do not silently broaden ACLs, change RLS, or repair migration history.
-- Applied Production version remains registered; this file is not re-run.

DO $verify_column_acl$
DECLARE
  v_table_digest text;
  v_col_digest text;
  v_col_count integer;
BEGIN
  IF (SELECT count(*)
      FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')) <> 37
     OR EXISTS (
       SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
       WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
         AND NOT c.relrowsecurity
     )
  THEN RAISE EXCEPTION 'Issue #345: table inventory/RLS baseline drift'; END IF;

  SELECT count(*) INTO v_col_count
  FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
    AND a.attnum>0 AND NOT a.attisdropped AND a.attacl IS NOT NULL;

  WITH column_acl AS (
    SELECT n.nspname,c.relname,a.attname,
      (SELECT COALESCE(
        string_agg(COALESCE(r.rolname,'PUBLIC')||':'||x.privilege_type||':'||x.is_grantable::text,
                   ',' ORDER BY COALESCE(r.rolname,'PUBLIC'),x.privilege_type,x.is_grantable),
        '')
       FROM aclexplode(a.attacl) x LEFT JOIN pg_roles r ON r.oid=x.grantee) AS acl
    FROM pg_attribute a JOIN pg_class c ON a.attrelid=c.oid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
      AND a.attnum>0 AND NOT a.attisdropped AND a.attacl IS NOT NULL
  )
  SELECT md5(string_agg(nspname||'.'||relname||'.'||attname||'='||acl,chr(10)
                        ORDER BY nspname,relname,attname))
    INTO v_col_digest FROM column_acl;

  IF v_col_count <> 56
     OR v_col_digest IS DISTINCT FROM 'c07c2e5b2207af0b9d29d5c9659293f5'
  THEN RAISE EXCEPTION 'Issue #345: column ACL baseline mismatch (% columns, % fingerprint)',
                       v_col_count,v_col_digest;
  END IF;

  WITH app_table_acl AS (
    SELECT n.nspname,c.relname,
      (SELECT COALESCE(
        string_agg(COALESCE(r.rolname,'PUBLIC')||':'||x.privilege_type||':'||x.is_grantable::text,
                   ',' ORDER BY COALESCE(r.rolname,'PUBLIC'),x.privilege_type,x.is_grantable),
        '')
       FROM aclexplode(COALESCE(c.relacl,acldefault('r',c.relowner))) x
       LEFT JOIN pg_roles r ON r.oid=x.grantee) AS grants
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
  )
  SELECT md5(string_agg(nspname||'.'||relname||'='||grants,chr(10)
                        ORDER BY nspname,relname))
    INTO v_table_digest FROM app_table_acl;

  IF v_table_digest IS DISTINCT FROM '434a5ab8b04ed46eae6aee32f1379535'
     OR NOT has_column_privilege('authenticated','public.trips','company_id','SELECT')
     OR NOT has_column_privilege('authenticated','public.trips','status','SELECT')
     OR has_table_privilege('authenticated','public.trips','SELECT')
     OR has_column_privilege('anon','public.trips','company_id','SELECT')
  THEN RAISE EXCEPTION 'Issue #345: table/column privileges baseline drift'; END IF;
END $verify_column_acl$;
