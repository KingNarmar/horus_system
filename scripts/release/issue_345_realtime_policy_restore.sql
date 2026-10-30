-- Issue #345: managed Realtime policy restore sidecar
-- Source: Development zwnfmszssxtfxkaofnhq; captured 2026-10-30.
-- Apply only after verified public/private restore and required grants.
-- Requires approved Production cutover window; NEVER run on Development.
-- No Supabase-managed schema/table/function is dropped by this artifact.
-- Policy replacement must run inside the cutover transaction.

DO $$ BEGIN
  IF to_regprocedure('private.has_company_role(uuid,public.company_role[])') IS NULL THEN
    RAISE EXCEPTION 'Missing private.has_company_role; application restore is incomplete';
  END IF;
END $$;

DROP POLICY IF EXISTS horus_company_expenses_realtime_receive ON realtime.messages;
CREATE POLICY horus_company_expenses_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:company_expenses$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'accountant'::company_role])));

DROP POLICY IF EXISTS horus_customers_realtime_receive ON realtime.messages;
CREATE POLICY horus_customers_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:customers$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role, 'accountant'::company_role, 'viewer'::company_role])));

DROP POLICY IF EXISTS horus_driver_finance_realtime_receive ON realtime.messages;
CREATE POLICY horus_driver_finance_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:driver_finance$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'accountant'::company_role])));

DROP POLICY IF EXISTS horus_driver_settlements_realtime_receive ON realtime.messages;
CREATE POLICY horus_driver_settlements_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:driver_settlements$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'accountant'::company_role])));

DROP POLICY IF EXISTS horus_drivers_realtime_receive ON realtime.messages;
CREATE POLICY horus_drivers_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:drivers$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role, 'accountant'::company_role, 'viewer'::company_role])));

DROP POLICY IF EXISTS horus_expense_ledger_realtime_receive ON realtime.messages;
CREATE POLICY horus_expense_ledger_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:expense_ledger$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'accountant'::company_role])));

DROP POLICY IF EXISTS horus_fleet_license_documents_realtime_receive ON realtime.messages;
CREATE POLICY horus_fleet_license_documents_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:fleet_license_documents$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role, 'accountant'::company_role, 'viewer'::company_role])));

DROP POLICY IF EXISTS horus_fleet_realtime_receive ON realtime.messages;
CREATE POLICY horus_fleet_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:fleet$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role, 'accountant'::company_role, 'viewer'::company_role])));

DROP POLICY IF EXISTS horus_invoices_realtime_receive ON realtime.messages;
CREATE POLICY horus_invoices_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:invoices$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'accountant'::company_role])));

DROP POLICY IF EXISTS horus_payments_realtime_receive ON realtime.messages;
CREATE POLICY horus_payments_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:payments$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'accountant'::company_role])));

DROP POLICY IF EXISTS horus_routes_realtime_receive ON realtime.messages;
CREATE POLICY horus_routes_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:routes$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role, 'accountant'::company_role, 'viewer'::company_role])));

DROP POLICY IF EXISTS horus_trip_documents_realtime_receive ON realtime.messages;
CREATE POLICY horus_trip_documents_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:trip_documents$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role, 'accountant'::company_role, 'viewer'::company_role])));

DROP POLICY IF EXISTS horus_trip_expenses_realtime_receive ON realtime.messages;
CREATE POLICY horus_trip_expenses_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:trip_expenses$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'accountant'::company_role])));

DROP POLICY IF EXISTS horus_trips_realtime_receive ON realtime.messages;
CREATE POLICY horus_trips_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND private.has_company_role(
CASE
    WHEN (realtime.topic() ~ '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:trips$'::text) THEN (split_part(realtime.topic(), ':'::text, 3))::uuid
    ELSE NULL::uuid
END, ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role, 'accountant'::company_role, 'viewer'::company_role])));

DROP POLICY IF EXISTS horus_user_membership_realtime_receive ON realtime.messages;
CREATE POLICY horus_user_membership_realtime_receive ON realtime.messages AS PERMISSIVE FOR SELECT TO authenticated
USING (((extension = 'broadcast'::text) AND (realtime.topic() = (('horus:user:'::text || (( SELECT auth.uid() AS uid))::text) || ':membership'::text))));
