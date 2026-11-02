-- Issue #345 — migration-history compatibility checkpoint (20261101152235_issue_345_reconcile_production_table_acl.sql).
-- Verify already-correct app table and default ACLs; no mutations.
-- Production ALREADY applied the original, state-changing migration under
-- this exact version during the 2026-11-01 cutover recovery.
-- Exact original SQL is preserved, UNMODIFIED, at:
-- scripts/release/issue_345_applied_production_migrations/20261101152235_issue_345_reconcile_production_table_acl.sql
--
-- Development already has these permissions from its frozen baseline.
-- This version is a READ-ONLY, FAIL-CLOSED state assertion for Development
-- and clean instances. No Production repair SQL must be replayed there.
-- If the expected baseline differs, STOP and reconcile explicitly;
-- do not silently broaden ACLs, change RLS, or repair migration history.
-- Applied Production version remains registered; this file is not re-run.

DO $verify$
DECLARE v_digest text; v_defaults jsonb;
BEGIN
  WITH table_acl AS (
 SELECT n.nspname,c.relname,
 (SELECT COALESCE(string_agg(COALESCE(r.rolname,'PUBLIC') || ':' || x.privilege_type || ':' || x.is_grantable::text,
         ',' ORDER BY COALESCE(r.rolname,'PUBLIC'),x.privilege_type,x.is_grantable),'')
  FROM aclexplode(COALESCE(c.relacl,acldefault('r',c.relowner))) x
  LEFT JOIN pg_roles r ON r.oid=x.grantee) AS grants
 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
)
SELECT md5(string_agg(nspname || '.' || relname || '=' || grants,chr(10) ORDER BY nspname,relname))
INTO v_digest FROM table_acl;
  IF v_digest IS DISTINCT FROM '434a5ab8b04ed46eae6aee32f1379535' THEN
    RAISE EXCEPTION 'Issue #345: table grant parity mismatch: %',v_digest;
  END IF;

  SELECT jsonb_object_agg(COALESCE(r.rolname,'PUBLIC'), privileges)
  INTO v_defaults
  FROM (
    SELECT x.grantee, string_agg(x.privilege_type,',' ORDER BY x.privilege_type) AS privileges
    FROM pg_default_acl d
    JOIN pg_namespace n ON n.oid=d.defaclnamespace
    CROSS JOIN LATERAL aclexplode(d.defaclacl) x
    WHERE n.nspname='public' AND d.defaclrole='postgres'::regrole
      AND d.defaclobjtype='r'
    GROUP BY x.grantee
  ) t
  LEFT JOIN pg_roles r ON r.oid=t.grantee;

  IF v_defaults IS DISTINCT FROM
    '{"postgres":"DELETE,INSERT,MAINTAIN,REFERENCES,SELECT,TRIGGER,TRUNCATE,UPDATE",
       "authenticated":"MAINTAIN,REFERENCES,TRIGGER,TRUNCATE",
       "service_role":"MAINTAIN,REFERENCES,TRIGGER,TRUNCATE"}'::jsonb
  THEN
    RAISE EXCEPTION 'Issue #345: postgres/public future table defaults mismatch';
  END IF;
END $verify$;
