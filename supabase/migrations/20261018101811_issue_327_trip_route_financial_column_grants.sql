-- Issue #327 — final direct-table column-read boundary for Trips and Routes.
-- PostgreSQL RLS protects rows, not columns. Authenticated is shared by all
-- company roles; this migration denies financial columns at SQL privilege level.
-- Monetary access remains available through tenant-checked, role-projected RPCs.
BEGIN;

-- This finance-only report has an explicit active owner/admin/accountant
-- membership guard and company_id predicates on all monetary source tables.
-- It must run with server privileges once raw freight columns are revoked.
ALTER FUNCTION public.get_trip_net_profit_report_source(uuid,date,date)
SECURITY DEFINER;
ALTER FUNCTION public.get_trip_net_profit_report_source(uuid,date,date)
SET search_path = pg_catalog;

REVOKE SELECT ON TABLE public.trips FROM PUBLIC, anon, authenticated;
GRANT SELECT (
  id, company_id, trip_number, customer_id, driver_id, tractor_head_id,
  trailer_id, route_id, trip_date, loading_location, unloading_location,
  cargo_type, quantity_tons, loading_order_number, waybill_number, status,
  loading_time, departure_time, arrival_time, unloading_time,
  documents_received_at, notes, created_by, updated_by, created_at,
  updated_at, scheduled_loading_at, scheduled_delivery_at,
  actual_loading_at, actual_delivery_at, invoice_id
) ON TABLE public.trips TO authenticated;

REVOKE SELECT ON TABLE public.routes FROM PUBLIC, anon, authenticated;
GRANT SELECT (
  id, company_id, loading_location, unloading_location,
  governorate_from, governorate_to, notes, is_active,
  created_by, updated_by, created_at, updated_at
) ON TABLE public.routes TO authenticated;

-- No column-level financial GRANTs. These assertions fail the migration
-- atomically if another earlier grant would still expose any monetary field.
DO $verify$
BEGIN
  IF has_column_privilege(
    'authenticated','public.trips','freight_price','SELECT'
  ) OR has_column_privilege(
    'authenticated','public.trips','agreed_freight_rate_per_ton','SELECT'
  ) OR has_column_privilege(
    'authenticated','public.trips','total_expenses','SELECT'
  ) OR has_column_privilege(
    'authenticated','public.routes','default_freight_price','SELECT'
  ) THEN
    RAISE EXCEPTION 'Issue #327: financial columns remain publicly readable';
  END IF;

  IF NOT has_column_privilege(
    'authenticated','public.trips','id','SELECT'
  ) OR NOT has_column_privilege(
    'authenticated','public.routes','id','SELECT'
  ) THEN
    RAISE EXCEPTION 'Issue #327: operational read columns were lost';
  END IF;
END;
$verify$;

COMMIT;
