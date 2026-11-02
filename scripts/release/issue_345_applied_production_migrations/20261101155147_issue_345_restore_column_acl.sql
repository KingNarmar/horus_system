-- Issue #345 — production-only column-ACL recovery after table-ACL rebuild.
-- Root cause: PostgreSQL REVOKE of table privilege also revoked grants on
-- individual columns. The prior table-ACL migration inadvertently removed
-- exactly 56 per-column ACLs; this correction restores them from Development.
-- Explicit 58 grants across 56 columns in 4 public tables. Two compensation
-- columns each carry both INSERT and UPDATE.
-- Authorization continues to be enforced by the existing RLS and Domain policy.
-- Only GRANT (...column list...) is performed, inside one atomic DO statement.
-- No data writes, no table-level GRANT, no Supabase Auth/Storage/Realtime/Cron
-- changes, no DROP/REVOKE and no SECURITY DEFINER change.
-- Captured baseline: Development zwnfmszssxtfxkaofnhq, 2026-11-01.
-- Intended target only: Production rkhmfbxlduuovlbsxhgy.
-- Preconditions and postconditions abort the entire DO on unexpected catalog
-- changes, rolling back all the column GRANTs.

DO $issue_345_column_acl_repair$
DECLARE
  v_table_digest text;
  v_col_digest text;
  v_col_count integer;
  v_app_tables integer;
  v_unprotected integer;
BEGIN
  SELECT count(*) INTO v_app_tables
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p');
  IF v_app_tables <> 37 THEN
    RAISE EXCEPTION 'Issue #345: app table count drift (got %)',v_app_tables;
  END IF;
  SELECT count(*) INTO v_unprotected
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
  AND NOT c.relrowsecurity;
  IF v_unprotected <> 0 THEN
    RAISE EXCEPTION 'Issue #345: missing RLS on % tables',v_unprotected;
  END IF;

  WITH t AS (SELECT n.nspname,c.relname,
(SELECT COALESCE(string_agg(COALESCE(r.rolname,'PUBLIC')||':'||a.privilege_type||':'||a.is_grantable::text,
',' ORDER BY COALESCE(r.rolname,'PUBLIC'),a.privilege_type,a.is_grantable),'')
FROM aclexplode(COALESCE(c.relacl,acldefault('r',c.relowner))) a LEFT JOIN pg_roles r ON r.oid=a.grantee) AS privileges
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p'))
SELECT md5(string_agg(nspname||'.'||relname||'='||privileges,chr(10) ORDER BY nspname,relname)) INTO v_table_digest FROM t;
  IF v_table_digest IS DISTINCT FROM '434a5ab8b04ed46eae6aee32f1379535' THEN
    RAISE EXCEPTION 'Issue #345: table ACL drift before column repair: %',v_table_digest;
  END IF;

  SELECT count(*) INTO v_col_count
  FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
  AND a.attnum>0 AND NOT a.attisdropped AND a.attacl IS NOT NULL;
  IF v_col_count <> 0 THEN
    RAISE EXCEPTION 'Issue #345: unexpected existing column ACLs: %',v_col_count;
  END IF;

  -- Column-specific grants captured exactly from Development (NOT blanket
  -- table grants). DO is an atomic SQL statement and fails closed on verify.
  EXECUTE 'GRANT INSERT (amount_minor_units, company_id, contract_document_reference, contract_reference, currency_code, currency_fraction_digits, driver_id, effective_from, effective_to, id) ON TABLE public.driver_compensation_revisions TO authenticated';
  EXECUTE 'GRANT UPDATE (contract_document_reference, effective_to) ON TABLE public.driver_compensation_revisions TO authenticated';
  EXECUTE 'GRANT UPDATE (is_active, name, updated_by) ON TABLE public.expense_types TO authenticated';
  EXECUTE 'GRANT SELECT (company_id, created_at, created_by, governorate_from, governorate_to, id, is_active, loading_location, notes, unloading_location, updated_at, updated_by) ON TABLE public.routes TO authenticated';
  EXECUTE 'GRANT SELECT (actual_delivery_at, actual_loading_at, arrival_time, cargo_type, company_id, created_at, created_by, customer_id, departure_time, documents_received_at, driver_id, id, invoice_id, loading_location, loading_order_number, loading_time, notes, quantity_tons, route_id, scheduled_delivery_at, scheduled_loading_at, status, tractor_head_id, trailer_id, trip_date, trip_number, unloading_location, unloading_time, updated_at, updated_by, waybill_number) ON TABLE public.trips TO authenticated';

  SELECT count(*) INTO v_col_count
  FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
  AND a.attnum>0 AND NOT a.attisdropped AND a.attacl IS NOT NULL;
  WITH column_acl AS (
SELECT n.nspname,c.relname,a.attname,
(SELECT COALESCE(string_agg(COALESCE(r.rolname,'PUBLIC')||':'||x.privilege_type||':'||x.is_grantable::text,
 ',' ORDER BY COALESCE(r.rolname,'PUBLIC'),x.privilege_type,x.is_grantable),'')
 FROM aclexplode(a.attacl) x LEFT JOIN pg_roles r ON r.oid=x.grantee) AS acl
FROM pg_attribute a JOIN pg_class c ON a.attrelid=c.oid JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
AND a.attnum>0 AND NOT a.attisdropped AND a.attacl IS NOT NULL)
SELECT md5(string_agg(nspname||'.'||relname||'.'||attname||'='||acl,chr(10)
 ORDER BY nspname,relname,attname)) INTO v_col_digest FROM column_acl;
  IF v_col_count <> 56 OR v_col_digest IS DISTINCT FROM
     'c07c2e5b2207af0b9d29d5c9659293f5' THEN
    RAISE EXCEPTION 'Issue #345: column ACL post-verify failed: count %, digest %',
      v_col_count,v_col_digest;
  END IF;
  WITH t AS (SELECT n.nspname,c.relname,
(SELECT COALESCE(string_agg(COALESCE(r.rolname,'PUBLIC')||':'||a.privilege_type||':'||a.is_grantable::text,
',' ORDER BY COALESCE(r.rolname,'PUBLIC'),a.privilege_type,a.is_grantable),'')
FROM aclexplode(COALESCE(c.relacl,acldefault('r',c.relowner))) a LEFT JOIN pg_roles r ON r.oid=a.grantee) AS privileges
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p'))
SELECT md5(string_agg(nspname||'.'||relname||'='||privileges,chr(10) ORDER BY nspname,relname)) INTO v_table_digest FROM t;
  IF v_table_digest IS DISTINCT FROM '434a5ab8b04ed46eae6aee32f1379535' THEN
    RAISE EXCEPTION 'Issue #345: table ACL modified unintentionally';
  END IF;
  IF NOT has_column_privilege('authenticated','public.trips','company_id','SELECT')
     OR NOT has_column_privilege('authenticated','public.trips','status','SELECT')
     OR has_table_privilege('authenticated','public.trips','SELECT')
     OR has_column_privilege('anon','public.trips','company_id','SELECT')
  THEN
    RAISE EXCEPTION 'Issue #345: trips SELECT scope mismatch';
  END IF;
END $issue_345_column_acl_repair$;
