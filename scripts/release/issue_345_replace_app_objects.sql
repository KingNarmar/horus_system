-- Issue #345 — deterministic application-owned replacement (PostgreSQL 17).
-- DESTRUCTIVE: DO NOT execute by itself. Must run only inside a psql
-- --single-transaction sequence after source hash, project ref, app maintenance,
-- Cron pause and Production-specific digest preservation and policy detachment.
-- No DROP SCHEMA and NO CASCADE anywhere.
-- Names and counts sourced from frozen Development schema on 2026-10-30.
-- Every unexpected dependent object aborts the enclosing transaction.

DO $preflight$
DECLARE
  table_count integer;
  function_count integer;
  enum_count integer;
  external_extension_owned integer;
BEGIN
  IF to_regclass('pg_temp.horus345_prod_invitation_key') IS NULL THEN
    RAISE EXCEPTION 'Production invitation digest missing: not in cutover session';
  END IF;

  SELECT count(*) INTO table_count
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p');
  SELECT count(*) INTO function_count
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname IN ('public','private') AND p.prokind = 'f';
  SELECT count(*) INTO enum_count
  FROM pg_type t JOIN pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname IN ('public','private') AND t.typtype = 'e';
  SELECT count(*) INTO external_extension_owned
  FROM pg_depend d JOIN pg_proc p ON p.oid=d.objid
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname IN ('public','private')
    AND d.classid='pg_proc'::regclass AND d.deptype='e';

  IF table_count<>37 OR function_count<>110 OR enum_count<>13 OR external_extension_owned<>0 THEN
    RAISE EXCEPTION 'Drift before replacement: tables %, functions %, enum types %, extension-owned functions %',
      table_count,function_count,enum_count,external_extension_owned;
  END IF;
END $preflight$;

-- A small set of RPCs have PostgreSQL-tracked dependencies on composite
-- row types of application tables (7 in the verified Production catalog).
-- Removing those RPCs first allows all 37 related tables to be dropped
-- TOGETHER under RESTRICT (including mutual foreign keys).
DO $rowtypes$
DECLARE item record;
BEGIN
  IF (
    SELECT count(DISTINCT p.oid)
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    JOIN pg_depend d ON d.objid=p.oid AND d.classid='pg_proc'::regclass
    JOIN pg_class c ON c.reltype=d.refobjid AND d.refclassid='pg_type'::regclass
    JOIN pg_namespace tn ON tn.oid=c.relnamespace
    WHERE n.nspname IN ('public','private') AND tn.nspname IN ('public','private')
      AND c.relkind IN ('r','p')
  ) <> 7 THEN
    RAISE EXCEPTION 'Unexpected app RPC -> table rowtype dependencies';
  END IF;
  FOR item IN
    SELECT DISTINCT p.oid,n.nspname AS s,p.proname AS name,
      pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    JOIN pg_depend d ON d.objid=p.oid AND d.classid='pg_proc'::regclass
    JOIN pg_class c ON c.reltype=d.refobjid AND d.refclassid='pg_type'::regclass
    JOIN pg_namespace tn ON tn.oid=c.relnamespace
    WHERE n.nspname IN ('public','private') AND tn.nspname IN ('public','private')
      AND c.relkind IN ('r','p')
  LOOP
    EXECUTE format('DROP FUNCTION %I.%I(%s) RESTRICT',item.s,item.name,item.args);
  END LOOP;
END $rowtypes$;

-- One RESTRICT statement covers app-owned FKs between these 37 tables.
-- Fails rather than affecting any managed Supabase object outside this list.
DROP TABLE
  "public"."expense_ledger_entries",
  "public"."payments",
  "public"."companies",
  "public"."company_invoice_settings",
  "private"."company_invitation_confirmation_keys",
  "public"."account_deletion_requests",
  "public"."audit_logs",
  "public"."company_expense_categories",
  "public"."company_expenses",
  "public"."company_invitations",
  "public"."company_subscriptions",
  "public"."company_users",
  "public"."customers",
  "public"."driver_advances",
  "public"."driver_compensation_revisions",
  "public"."driver_deductions",
  "public"."driver_financial_movements",
  "public"."driver_settlement_items",
  "public"."driver_settlements",
  "public"."drivers",
  "public"."expense_types",
  "public"."fleet_license_document_files",
  "public"."fleet_license_documents",
  "public"."invoice_lines",
  "public"."invoice_sequences",
  "public"."invoices",
  "public"."payment_methods",
  "public"."routes",
  "public"."subscription_plans",
  "public"."tractor_heads",
  "public"."trailers",
  "public"."trip_documents",
  "public"."trip_expenses",
  "public"."trip_sequences",
  "public"."trip_status_history",
  "public"."trips",
  "public"."user_profiles"
RESTRICT;

-- The remaining application functions cannot retain the old enum types.
-- Separate RESTRICT drops fail closed on any unreviewed external dependency.
DO $functions$
DECLARE item record;
BEGIN
  FOR item IN
    SELECT n.nspname AS s,p.proname AS name,pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname IN ('public','private') AND p.prokind='f'
    ORDER BY n.nspname,p.proname,pg_get_function_identity_arguments(p.oid)
  LOOP
    EXECUTE format('DROP FUNCTION %I.%I(%s) RESTRICT',item.s,item.name,item.args);
  END LOOP;
END $functions$;

DROP TYPE
  "public"."account_deletion_request_status",
  "public"."company_invitation_status",
  "public"."company_role",
  "public"."driver_settlement_item_direction",
  "public"."driver_settlement_item_source_type",
  "public"."driver_settlement_status",
  "public"."driver_status",
  "public"."expense_paid_by",
  "public"."invoice_status",
  "public"."payment_method_code",
  "public"."subscription_status",
  "public"."trip_status",
  "public"."vehicle_status"
RESTRICT;

-- Fail closed against lingering app-owned structures before exact schema replay.
DO $postdrop$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
              WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p','v','m'))
     OR EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
                 WHERE n.nspname IN ('public','private'))
     OR EXISTS (SELECT 1 FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
                 WHERE n.nspname IN ('public','private') AND t.typtype='e')
  THEN
    RAISE EXCEPTION 'Incomplete application object removal — rolled back';
  END IF;
END $postdrop$;
