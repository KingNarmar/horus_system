-- Issue #345. Source-confirmed 13 app-owned Storage policies (Development).
-- Execute only AFTER restoring public/private and all needed app-owned functions.
-- No Storage buckets, objects, internal triggers or Supabase service tables are modified.
-- Must run in the SAME controlled Production transaction as the schema replacement.

SET search_path TO public, pg_catalog;

DROP POLICY IF EXISTS business_documents_delete_managers ON storage.objects;
CREATE POLICY business_documents_delete_managers ON storage.objects AS PERMISSIVE FOR DELETE TO authenticated
USING (((bucket_id = 'business-documents'::text) AND (private.trip_document_storage_trip_id(name) IS NULL) AND (private.fleet_license_document_storage_asset_type(name) IS NULL) AND private.has_company_role(private.business_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role])));

DROP POLICY IF EXISTS business_documents_delete_unregistered_fleet_license_documents ON storage.objects;
CREATE POLICY business_documents_delete_unregistered_fleet_license_documents ON storage.objects AS PERMISSIVE FOR DELETE TO authenticated
USING (((bucket_id = 'business-documents'::text) AND (private.fleet_license_document_storage_asset_type(name) IS NOT NULL) AND private.has_company_role(private.business_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role]) AND (((private.fleet_license_document_storage_asset_type(name) = 'tractor_head'::text) AND (EXISTS ( SELECT 1
   FROM tractor_heads asset
  WHERE ((asset.company_id = private.business_document_company_id(objects.name)) AND (asset.id = private.fleet_license_document_storage_asset_id(objects.name)))))) OR ((private.fleet_license_document_storage_asset_type(name) = 'trailer'::text) AND (EXISTS ( SELECT 1
   FROM trailers asset
  WHERE ((asset.company_id = private.business_document_company_id(objects.name)) AND (asset.id = private.fleet_license_document_storage_asset_id(objects.name))))))) AND (NOT (EXISTS ( SELECT 1
   FROM fleet_license_document_files file_row
  WHERE ((file_row.company_id = private.business_document_company_id(objects.name)) AND (file_row.storage_reference = objects.name)))))));

DROP POLICY IF EXISTS business_documents_delete_unregistered_trip_documents ON storage.objects;
CREATE POLICY business_documents_delete_unregistered_trip_documents ON storage.objects AS PERMISSIVE FOR DELETE TO authenticated
USING (((bucket_id = 'business-documents'::text) AND (private.trip_document_storage_trip_id(name) IS NOT NULL) AND private.has_company_role(private.business_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role]) AND (EXISTS ( SELECT 1
   FROM trips trip_row
  WHERE ((trip_row.company_id = private.business_document_company_id(objects.name)) AND (trip_row.id = private.trip_document_storage_trip_id(objects.name))))) AND (NOT (EXISTS ( SELECT 1
   FROM trip_documents document_row
  WHERE ((document_row.company_id = private.business_document_company_id(objects.name)) AND (document_row.storage_reference = objects.name)))))));

DROP POLICY IF EXISTS business_documents_insert_fleet_license_documents ON storage.objects;
CREATE POLICY business_documents_insert_fleet_license_documents ON storage.objects AS PERMISSIVE FOR INSERT TO authenticated
WITH CHECK (((bucket_id = 'business-documents'::text) AND (private.fleet_license_document_storage_asset_type(name) IS NOT NULL) AND private.has_company_role(private.business_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role]) AND (((private.fleet_license_document_storage_asset_type(name) = 'tractor_head'::text) AND (EXISTS ( SELECT 1
   FROM tractor_heads asset
  WHERE ((asset.company_id = private.business_document_company_id(objects.name)) AND (asset.id = private.fleet_license_document_storage_asset_id(objects.name)))))) OR ((private.fleet_license_document_storage_asset_type(name) = 'trailer'::text) AND (EXISTS ( SELECT 1
   FROM trailers asset
  WHERE ((asset.company_id = private.business_document_company_id(objects.name)) AND (asset.id = private.fleet_license_document_storage_asset_id(objects.name)))))))));

DROP POLICY IF EXISTS business_documents_insert_managers ON storage.objects;
CREATE POLICY business_documents_insert_managers ON storage.objects AS PERMISSIVE FOR INSERT TO authenticated
WITH CHECK (((bucket_id = 'business-documents'::text) AND (private.trip_document_storage_trip_id(name) IS NULL) AND (private.fleet_license_document_storage_asset_type(name) IS NULL) AND private.has_company_role(private.business_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role])));

DROP POLICY IF EXISTS business_documents_insert_trip_documents ON storage.objects;
CREATE POLICY business_documents_insert_trip_documents ON storage.objects AS PERMISSIVE FOR INSERT TO authenticated
WITH CHECK (((bucket_id = 'business-documents'::text) AND (private.trip_document_storage_trip_id(name) IS NOT NULL) AND private.has_company_role(private.business_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role]) AND (EXISTS ( SELECT 1
   FROM trips trip_row
  WHERE ((trip_row.company_id = private.business_document_company_id(objects.name)) AND (trip_row.id = private.trip_document_storage_trip_id(objects.name)))))));

DROP POLICY IF EXISTS business_documents_select_fleet_license_documents ON storage.objects;
CREATE POLICY business_documents_select_fleet_license_documents ON storage.objects AS PERMISSIVE FOR SELECT TO authenticated
USING (((bucket_id = 'business-documents'::text) AND (private.fleet_license_document_storage_asset_type(name) IS NOT NULL) AND private.has_company_role(private.business_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role, 'accountant'::company_role, 'viewer'::company_role]) AND (((private.fleet_license_document_storage_asset_type(name) = 'tractor_head'::text) AND (EXISTS ( SELECT 1
   FROM tractor_heads asset
  WHERE ((asset.company_id = private.business_document_company_id(objects.name)) AND (asset.id = private.fleet_license_document_storage_asset_id(objects.name)))))) OR ((private.fleet_license_document_storage_asset_type(name) = 'trailer'::text) AND (EXISTS ( SELECT 1
   FROM trailers asset
  WHERE ((asset.company_id = private.business_document_company_id(objects.name)) AND (asset.id = private.fleet_license_document_storage_asset_id(objects.name)))))))));

DROP POLICY IF EXISTS business_documents_select_managers ON storage.objects;
CREATE POLICY business_documents_select_managers ON storage.objects AS PERMISSIVE FOR SELECT TO authenticated
USING (((bucket_id = 'business-documents'::text) AND private.has_company_role(private.business_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role])));

DROP POLICY IF EXISTS business_documents_select_trip_documents ON storage.objects;
CREATE POLICY business_documents_select_trip_documents ON storage.objects AS PERMISSIVE FOR SELECT TO authenticated
USING (((bucket_id = 'business-documents'::text) AND (private.trip_document_storage_trip_id(name) IS NOT NULL) AND private.has_company_role(private.business_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role, 'accountant'::company_role, 'viewer'::company_role]) AND (EXISTS ( SELECT 1
   FROM trips trip_row
  WHERE ((trip_row.company_id = private.business_document_company_id(objects.name)) AND (trip_row.id = private.trip_document_storage_trip_id(objects.name)))))));

DROP POLICY IF EXISTS driver_documents_delete_managers ON storage.objects;
CREATE POLICY driver_documents_delete_managers ON storage.objects AS PERMISSIVE FOR DELETE TO authenticated
USING (((bucket_id = 'driver-documents'::text) AND private.has_company_role(private.driver_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role])));

DROP POLICY IF EXISTS driver_documents_insert_managers ON storage.objects;
CREATE POLICY driver_documents_insert_managers ON storage.objects AS PERMISSIVE FOR INSERT TO authenticated
WITH CHECK (((bucket_id = 'driver-documents'::text) AND private.has_company_role(private.driver_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role])));

DROP POLICY IF EXISTS driver_documents_select_company_roles ON storage.objects;
CREATE POLICY driver_documents_select_company_roles ON storage.objects AS PERMISSIVE FOR SELECT TO authenticated
USING (((bucket_id = 'driver-documents'::text) AND private.has_company_role(private.driver_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role, 'accountant'::company_role, 'viewer'::company_role])));

DROP POLICY IF EXISTS driver_documents_update_managers ON storage.objects;
CREATE POLICY driver_documents_update_managers ON storage.objects AS PERMISSIVE FOR UPDATE TO authenticated
USING (((bucket_id = 'driver-documents'::text) AND private.has_company_role(private.driver_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role])))
WITH CHECK (((bucket_id = 'driver-documents'::text) AND private.has_company_role(private.driver_document_company_id(name), ARRAY['owner'::company_role, 'admin'::company_role, 'operations'::company_role])));
