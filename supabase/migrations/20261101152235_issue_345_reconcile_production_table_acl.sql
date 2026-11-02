-- Issue #345 — portability-safe reconciliation of exact app table/default ACLs.
-- Original SQL applied to Production is archived, byte-exact, at
-- scripts/release/issue_345_applied_production_migrations/20261101152235_issue_345_reconcile_production_table_acl.sql
-- Production records this version as applied; Development (already correct)
-- is a no-op. A fresh replay may apply only the observed ACL preimage.
-- No DML, no RLS policy changes and no action against linked databases here.
-- Historical SQL and this portability wrapper intentionally differ.

DO $issue_345_table_repair$
DECLARE v_digest text;
BEGIN
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='public' AND c.relkind IN ('r','p')) <> 36
     OR (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='private' AND c.relkind IN ('r','p')) <> 1
     OR EXISTS (
       SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
       WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
         AND NOT c.relrowsecurity
     )
  THEN
    RAISE EXCEPTION 'Issue #345: table catalog/RLS preflight mismatch';
  END IF;

  WITH table_acl AS (
  SELECT n.nspname,c.relname,
    (SELECT COALESCE(string_agg(COALESCE(r.rolname,'PUBLIC')||':'||x.privilege_type||':'||x.is_grantable::text,
        ',' ORDER BY COALESCE(r.rolname,'PUBLIC'),x.privilege_type,x.is_grantable),'')
     FROM aclexplode(COALESCE(c.relacl,acldefault('r',c.relowner))) x
     LEFT JOIN pg_roles r ON r.oid=x.grantee) AS grants
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
)
SELECT md5(string_agg(nspname||'.'||relname||'='||grants,chr(10) ORDER BY nspname,relname))
INTO v_digest FROM table_acl;

  IF v_digest = '434a5ab8b04ed46eae6aee32f1379535' THEN
    RETURN; -- Already-correct Development baseline; no table ACL changes.
  END IF;

  IF v_digest IS DISTINCT FROM '0b99a85e20ae98a5386274ac10fad882' THEN
    RAISE EXCEPTION 'Issue #345: unknown table ACL preimage (%), refusing to reconcile',v_digest;
  END IF;

  EXECUTE $ddl$ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated, service_role$ddl$;
  EXECUTE $ddl$ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLES
  TO authenticated, service_role$ddl$;
  EXECUTE $ddl$REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
  FROM PUBLIC, anon, authenticated, service_role$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE public.account_deletion_requests TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.account_deletion_requests TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.audit_logs TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.audit_logs TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.companies TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.companies TO service_role$ddl$;
  EXECUTE $ddl$GRANT INSERT, SELECT, UPDATE ON TABLE public.company_expense_categories TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.company_expense_categories TO service_role$ddl$;
  EXECUTE $ddl$GRANT INSERT, SELECT, UPDATE ON TABLE public.company_expenses TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.company_expenses TO service_role$ddl$;
  EXECUTE $ddl$GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.company_invitations TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.company_invoice_settings TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.company_invoice_settings TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.company_subscriptions TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.company_subscriptions TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT, UPDATE ON TABLE public.company_users TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.company_users TO service_role$ddl$;
  EXECUTE $ddl$GRANT INSERT, SELECT, UPDATE ON TABLE public.customers TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.customers TO service_role$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_advances TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.driver_compensation_revisions TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_compensation_revisions TO service_role$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_deductions TO service_role$ddl$;
  EXECUTE $ddl$GRANT INSERT, SELECT ON TABLE public.driver_financial_movements TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_financial_movements TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.driver_settlement_items TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_settlement_items TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT, UPDATE ON TABLE public.driver_settlements TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_settlements TO service_role$ddl$;
  EXECUTE $ddl$GRANT INSERT, SELECT, UPDATE ON TABLE public.drivers TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.drivers TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.expense_ledger_entries TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.expense_ledger_entries TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.expense_types TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.expense_types TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.fleet_license_document_files TO authenticated$ddl$;
  EXECUTE $ddl$GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.fleet_license_document_files TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.fleet_license_documents TO authenticated$ddl$;
  EXECUTE $ddl$GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.fleet_license_documents TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.invoice_lines TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.invoice_lines TO service_role$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.invoice_sequences TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.invoices TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.invoices TO service_role$ddl$;
  EXECUTE $ddl$GRANT INSERT, SELECT, UPDATE ON TABLE public.payment_methods TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.payment_methods TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.payments TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.payments TO service_role$ddl$;
  EXECUTE $ddl$GRANT INSERT, UPDATE ON TABLE public.routes TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.routes TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.subscription_plans TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.subscription_plans TO service_role$ddl$;
  EXECUTE $ddl$GRANT INSERT, SELECT, UPDATE ON TABLE public.tractor_heads TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.tractor_heads TO service_role$ddl$;
  EXECUTE $ddl$GRANT INSERT, SELECT, UPDATE ON TABLE public.trailers TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.trailers TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.trip_documents TO authenticated$ddl$;
  EXECUTE $ddl$GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.trip_documents TO service_role$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.trip_expenses TO service_role$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.trip_sequences TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.trip_status_history TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.trip_status_history TO service_role$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.trips TO service_role$ddl$;
  EXECUTE $ddl$GRANT SELECT ON TABLE public.user_profiles TO authenticated$ddl$;
  EXECUTE $ddl$GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.user_profiles TO service_role$ddl$;
END $issue_345_table_repair$;

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
