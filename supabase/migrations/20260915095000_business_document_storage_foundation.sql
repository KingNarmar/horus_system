-- H.O.R.U.S System — Issue #227 / PC-03
-- Secure reusable storage foundation for company-owned business documents.

BEGIN;

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'business-documents',
  'business-documents',
  false,
  10485760,
  ARRAY[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif'
  ]
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE OR REPLACE FUNCTION private.business_document_company_id(object_name text)
RETURNS uuid
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
  SELECT CASE
    WHEN object_name ~ '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?/[0-9a-f]{32}\.(pdf|jpg|jpeg|png|webp|heic|heif)$'
      THEN split_part(object_name, '/', 2)::uuid
    ELSE NULL
  END;
$function$;

REVOKE ALL
ON FUNCTION private.business_document_company_id(text)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION private.business_document_company_id(text)
TO authenticated;

DROP POLICY IF EXISTS business_documents_select_managers ON storage.objects;
DROP POLICY IF EXISTS business_documents_insert_managers ON storage.objects;
DROP POLICY IF EXISTS business_documents_update_managers ON storage.objects;
DROP POLICY IF EXISTS business_documents_delete_managers ON storage.objects;

CREATE POLICY business_documents_select_managers
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'business-documents'
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin']::public.company_role[]
  )
);

CREATE POLICY business_documents_insert_managers
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'business-documents'
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin']::public.company_role[]
  )
);

CREATE POLICY business_documents_update_managers
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'business-documents'
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin']::public.company_role[]
  )
)
WITH CHECK (
  bucket_id = 'business-documents'
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin']::public.company_role[]
  )
);

CREATE POLICY business_documents_delete_managers
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'business-documents'
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin']::public.company_role[]
  )
);

COMMIT;
