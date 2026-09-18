-- H.O.R.U.S System — Issue #236 / PC-12
-- Avoid nested private-schema resolution inside Storage RLS execution.
-- The authenticated role can execute this helper through stored policy references,
-- but it intentionally does not receive USAGE on the whole private schema.

BEGIN;

CREATE OR REPLACE FUNCTION private.fleet_license_document_storage_asset_id(
  object_name text
)
RETURNS uuid
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
  SELECT CASE
    WHEN object_name ~ '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/tractor-heads/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/license/[0-9a-f]{32}\.(pdf|jpg|jpeg|png|webp|heic|heif)$'
      THEN split_part(object_name, '/', 4)::uuid
    WHEN object_name ~ '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/trailers/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/license/[0-9a-f]{32}\.(pdf|jpg|jpeg|png|webp|heic|heif)$'
      THEN split_part(object_name, '/', 4)::uuid
    ELSE NULL
  END;
$function$;

REVOKE ALL
ON FUNCTION private.fleet_license_document_storage_asset_id(text)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION private.fleet_license_document_storage_asset_id(text)
TO authenticated;

COMMIT;
