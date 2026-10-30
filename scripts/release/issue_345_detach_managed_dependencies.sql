-- Issue #345 managed dependency detachment ONLY. Destructive; must be used inside ONE approved Production transaction.
-- Requires the Production-only digest to have been stored in the session-local pg_temp.horus345_prod_invitation_key table.
-- Do NOT execute alone or on Development. Immediately follow with scoped application schema replacement and policy restore.
-- Do NOT touch Supabase's own internal Storage/Auth/Realtime triggers or schemas.

DO $$
BEGIN
  IF to_regclass('pg_temp.horus345_prod_invitation_key') IS NULL THEN
    RAISE EXCEPTION 'Production invitation digest was not preserved in this session';
  END IF;
END $$;

DROP TRIGGER IF EXISTS on_auth_user_created_create_profile ON auth.users;
DROP EVENT TRIGGER IF EXISTS ensure_rls;
DROP POLICY IF EXISTS business_documents_delete_managers ON storage.objects;
DROP POLICY IF EXISTS business_documents_delete_unregistered_fleet_license_documents ON storage.objects;
DROP POLICY IF EXISTS business_documents_delete_unregistered_trip_documents ON storage.objects;
DROP POLICY IF EXISTS business_documents_insert_fleet_license_documents ON storage.objects;
DROP POLICY IF EXISTS business_documents_insert_managers ON storage.objects;
DROP POLICY IF EXISTS business_documents_insert_trip_documents ON storage.objects;
DROP POLICY IF EXISTS business_documents_select_fleet_license_documents ON storage.objects;
DROP POLICY IF EXISTS business_documents_select_managers ON storage.objects;
DROP POLICY IF EXISTS business_documents_select_trip_documents ON storage.objects;
DROP POLICY IF EXISTS driver_documents_delete_managers ON storage.objects;
DROP POLICY IF EXISTS driver_documents_insert_managers ON storage.objects;
DROP POLICY IF EXISTS driver_documents_select_company_roles ON storage.objects;
DROP POLICY IF EXISTS driver_documents_update_managers ON storage.objects;
DROP POLICY IF EXISTS horus_company_expenses_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_customers_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_driver_finance_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_driver_settlements_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_drivers_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_expense_ledger_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_fleet_license_documents_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_fleet_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_invoices_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_payments_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_routes_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_trip_documents_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_trip_expenses_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_trips_realtime_receive ON realtime.messages;
DROP POLICY IF EXISTS horus_user_membership_realtime_receive ON realtime.messages;
