-- Issue #345 — PREPARED FOR REVIEW; NOT YET APPROVED FOR PRODUCTION APPLY.
-- Source: 2026-10-30 Development snapshot zwnfmszssxtfxkaofnhq.
-- Fix: Production-only public TABLE grants/default privileges broadened during
--    the full-schema restore. No data, schema table structure, RLS policies,
--    column grants, Storage, Realtime, auth, or cron changes.
-- Dev expected: 36 public and 1 private app tables.
-- Captured Dev table grant privileges for authenticated/service_role: 65 grants.
-- Fail closed if preimage or postimage differs from independently verified digest.
-- Do not execute on Development; that project is the source freeze.

DO $preflight$
DECLARE v_digest text;
BEGIN
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='public' AND c.relkind IN ('r','p')) <> 36 THEN
    RAISE EXCEPTION 'Issue #345: unexpected public table count';
  END IF;
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
  IF v_digest IS DISTINCT FROM 'b14036e2b986a4daa59b7d9719f91634' THEN
    RAISE EXCEPTION 'Issue #345: Production pre-ACL digest changed: %',v_digest;
  END IF;
END $preflight$;

-- Match Dev's future postgres-created public table defaults: owner full,
-- authenticated/service_role only TRUNCATE, REFERENCES, TRIGGER, MAINTAIN.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  GRANT TRUNCATE, REFERENCES, TRIGGER, MAINTAIN ON TABLES
  TO authenticated, service_role;

-- Existing table-level grants. Column ACLs remain untouched.
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
  FROM PUBLIC, anon, authenticated, service_role;

-- Exact per-table privileges captured from Dev; PostgreSQL 17 syntax.
GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE public.account_deletion_requests TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.account_deletion_requests TO service_role;
GRANT SELECT ON TABLE public.audit_logs TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.audit_logs TO service_role;
GRANT SELECT ON TABLE public.companies TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.companies TO service_role;
GRANT INSERT, SELECT, UPDATE ON TABLE public.company_expense_categories TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.company_expense_categories TO service_role;
GRANT INSERT, SELECT, UPDATE ON TABLE public.company_expenses TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.company_expenses TO service_role;
GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.company_invitations TO service_role;
GRANT SELECT ON TABLE public.company_invoice_settings TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.company_invoice_settings TO service_role;
GRANT SELECT ON TABLE public.company_subscriptions TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.company_subscriptions TO service_role;
GRANT SELECT, UPDATE ON TABLE public.company_users TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.company_users TO service_role;
GRANT INSERT, SELECT, UPDATE ON TABLE public.customers TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.customers TO service_role;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_advances TO service_role;
GRANT SELECT ON TABLE public.driver_compensation_revisions TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_compensation_revisions TO service_role;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_deductions TO service_role;
GRANT INSERT, SELECT ON TABLE public.driver_financial_movements TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_financial_movements TO service_role;
GRANT SELECT ON TABLE public.driver_settlement_items TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_settlement_items TO service_role;
GRANT SELECT, UPDATE ON TABLE public.driver_settlements TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.driver_settlements TO service_role;
GRANT INSERT, SELECT, UPDATE ON TABLE public.drivers TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.drivers TO service_role;
GRANT SELECT ON TABLE public.expense_ledger_entries TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.expense_ledger_entries TO service_role;
GRANT SELECT ON TABLE public.expense_types TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.expense_types TO service_role;
GRANT SELECT ON TABLE public.fleet_license_document_files TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.fleet_license_document_files TO service_role;
GRANT SELECT ON TABLE public.fleet_license_documents TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.fleet_license_documents TO service_role;
GRANT SELECT ON TABLE public.invoice_lines TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.invoice_lines TO service_role;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.invoice_sequences TO service_role;
GRANT SELECT ON TABLE public.invoices TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.invoices TO service_role;
GRANT INSERT, SELECT, UPDATE ON TABLE public.payment_methods TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.payment_methods TO service_role;
GRANT SELECT ON TABLE public.payments TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.payments TO service_role;
GRANT INSERT, UPDATE ON TABLE public.routes TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.routes TO service_role;
GRANT SELECT ON TABLE public.subscription_plans TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.subscription_plans TO service_role;
GRANT INSERT, SELECT, UPDATE ON TABLE public.tractor_heads TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.tractor_heads TO service_role;
GRANT INSERT, SELECT, UPDATE ON TABLE public.trailers TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.trailers TO service_role;
GRANT SELECT ON TABLE public.trip_documents TO authenticated;
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public.trip_documents TO service_role;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.trip_expenses TO service_role;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.trip_sequences TO service_role;
GRANT SELECT ON TABLE public.trip_status_history TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.trip_status_history TO service_role;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.trips TO service_role;
GRANT SELECT ON TABLE public.user_profiles TO authenticated;
GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE public.user_profiles TO service_role;

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
