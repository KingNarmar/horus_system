-- H.O.R.U.S System — Issue #236 / PC-12
-- Secure Fleet license-document lifecycle for Tractor Heads and Trailers.
--
-- Responsibilities:
-- - company-scoped Fleet license document metadata with logical remove/replace
-- - one-active-license-document invariant per Fleet asset
-- - optional exact Business Date license-expiry update during create/replace
-- - atomic audit writes for document mutations
-- - Fleet-scoped Storage RLS on top of the PC-03 business-documents bucket
-- - align base Fleet SELECT RLS with Domain roles (driver denied)

BEGIN;

CREATE TABLE public.fleet_license_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL
    REFERENCES public.companies(id)
    ON DELETE CASCADE,
  tractor_head_id uuid,
  trailer_id uuid,
  storage_reference text NOT NULL,
  original_file_name text NOT NULL,
  mime_type text NOT NULL,
  size_bytes bigint NOT NULL,
  uploaded_by uuid
    REFERENCES auth.users(id)
    ON DELETE SET NULL,
  uploaded_at timestamptz NOT NULL DEFAULT now(),
  removed_by uuid
    REFERENCES auth.users(id)
    ON DELETE SET NULL,
  removed_at timestamptz,
  replaces_document_id uuid,
  CONSTRAINT fleet_license_documents_exactly_one_asset_check
    CHECK (
      (tractor_head_id IS NOT NULL AND trailer_id IS NULL)
      OR
      (tractor_head_id IS NULL AND trailer_id IS NOT NULL)
    ),
  CONSTRAINT fleet_license_documents_company_tractor_fk
    FOREIGN KEY (company_id, tractor_head_id)
    REFERENCES public.tractor_heads(company_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fleet_license_documents_company_trailer_fk
    FOREIGN KEY (company_id, trailer_id)
    REFERENCES public.trailers(company_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fleet_license_documents_company_id_id_unique
    UNIQUE (company_id, id),
  CONSTRAINT fleet_license_documents_company_replaces_fk
    FOREIGN KEY (company_id, replaces_document_id)
    REFERENCES public.fleet_license_documents(company_id, id),
  CONSTRAINT fleet_license_documents_original_file_name_check
    CHECK (length(btrim(original_file_name)) BETWEEN 1 AND 255),
  CONSTRAINT fleet_license_documents_mime_type_check
    CHECK (
      mime_type IN (
        'application/pdf',
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
        'image/heif'
      )
    ),
  CONSTRAINT fleet_license_documents_size_bytes_check
    CHECK (size_bytes > 0 AND size_bytes <= 10485760),
  CONSTRAINT fleet_license_documents_removed_at_check
    CHECK (removed_at IS NULL OR removed_at >= uploaded_at)
);

CREATE UNIQUE INDEX fleet_license_documents_storage_reference_unique_idx
  ON public.fleet_license_documents(storage_reference);

CREATE UNIQUE INDEX fleet_license_documents_replaces_once_idx
  ON public.fleet_license_documents(replaces_document_id)
  WHERE replaces_document_id IS NOT NULL;

CREATE UNIQUE INDEX fleet_license_documents_active_tractor_idx
  ON public.fleet_license_documents(company_id, tractor_head_id)
  WHERE removed_at IS NULL AND tractor_head_id IS NOT NULL;

CREATE UNIQUE INDEX fleet_license_documents_active_trailer_idx
  ON public.fleet_license_documents(company_id, trailer_id)
  WHERE removed_at IS NULL AND trailer_id IS NOT NULL;

CREATE INDEX fleet_license_documents_uploaded_by_idx
  ON public.fleet_license_documents(uploaded_by)
  WHERE uploaded_by IS NOT NULL;

CREATE INDEX fleet_license_documents_removed_by_idx
  ON public.fleet_license_documents(removed_by)
  WHERE removed_by IS NOT NULL;

ALTER TABLE public.fleet_license_documents ENABLE ROW LEVEL SECURITY;

REVOKE ALL
ON TABLE public.fleet_license_documents
FROM anon, authenticated;

GRANT SELECT
ON TABLE public.fleet_license_documents
TO authenticated;

GRANT ALL
ON TABLE public.fleet_license_documents
TO service_role;

CREATE POLICY fleet_license_documents_select_authorized
ON public.fleet_license_documents
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

DROP POLICY IF EXISTS tractor_heads_select_members
ON public.tractor_heads;

CREATE POLICY tractor_heads_select_authorized
ON public.tractor_heads
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

DROP POLICY IF EXISTS trailers_select_members
ON public.trailers;

CREATE POLICY trailers_select_authorized
ON public.trailers
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

CREATE OR REPLACE FUNCTION private.fleet_license_document_storage_asset_type(
  object_name text
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
  SELECT CASE
    WHEN object_name ~ '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/tractor-heads/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/license/[0-9a-f]{32}\.(pdf|jpg|jpeg|png|webp|heic|heif)$'
      THEN 'tractor_head'
    WHEN object_name ~ '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/trailers/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/license/[0-9a-f]{32}\.(pdf|jpg|jpeg|png|webp|heic|heif)$'
      THEN 'trailer'
    ELSE NULL
  END;
$function$;

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
    WHEN private.fleet_license_document_storage_asset_type(object_name)
      IS NOT NULL
      THEN split_part(object_name, '/', 4)::uuid
    ELSE NULL
  END;
$function$;

REVOKE ALL
ON FUNCTION private.fleet_license_document_storage_asset_type(text)
FROM PUBLIC, anon, authenticated;

REVOKE ALL
ON FUNCTION private.fleet_license_document_storage_asset_id(text)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION private.fleet_license_document_storage_asset_type(text)
TO authenticated;

GRANT EXECUTE
ON FUNCTION private.fleet_license_document_storage_asset_id(text)
TO authenticated;

CREATE OR REPLACE FUNCTION private.fleet_license_document_storage_matches(
  p_company_id uuid,
  p_asset_type text,
  p_asset_id uuid,
  p_storage_reference text,
  p_mime_type text,
  p_size_bytes bigint
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
  SELECT
    private.business_document_company_id(p_storage_reference) = p_company_id
    AND private.fleet_license_document_storage_asset_type(
      p_storage_reference
    ) = p_asset_type
    AND private.fleet_license_document_storage_asset_id(
      p_storage_reference
    ) = p_asset_id
    AND EXISTS (
      SELECT 1
      FROM storage.objects object_row
      WHERE object_row.bucket_id = 'business-documents'
        AND object_row.name = p_storage_reference
        AND (object_row.metadata ->> 'size') ~ '^[0-9]+$'
        AND (object_row.metadata ->> 'size')::bigint = p_size_bytes
        AND lower(COALESCE(object_row.metadata ->> 'mimetype', ''))
          = lower(p_mime_type)
    );
$function$;

REVOKE ALL
ON FUNCTION private.fleet_license_document_storage_matches(
  uuid,
  text,
  uuid,
  text,
  text,
  bigint
)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.create_fleet_license_document_atomic(
  p_company_id uuid,
  p_asset_type text,
  p_asset_id uuid,
  p_storage_reference text,
  p_original_file_name text,
  p_mime_type text,
  p_size_bytes bigint,
  p_license_expiry_date date DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_plate_number text;
  v_old_expiry date;
  v_new_expiry date;
  v_tractor_head_id uuid;
  v_trailer_id uuid;
  v_document public.fleet_license_documents%ROWTYPE;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3430',
      MESSAGE = 'fleet_license_document_permission_denied';
  END IF;

  IF p_asset_type = 'tractor_head' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_old_expiry
    FROM public.tractor_heads asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P3431',
        MESSAGE = 'fleet_license_document_asset_not_found';
    END IF;

    v_tractor_head_id := p_asset_id;
  ELSIF p_asset_type = 'trailer' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_old_expiry
    FROM public.trailers asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P3431',
        MESSAGE = 'fleet_license_document_asset_not_found';
    END IF;

    v_trailer_id := p_asset_id;
  ELSE
    RAISE EXCEPTION USING
      ERRCODE = 'P3435',
      MESSAGE = 'fleet_license_document_asset_type_invalid';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.fleet_license_documents document_row
    WHERE document_row.company_id = p_company_id
      AND document_row.removed_at IS NULL
      AND (
        (v_tractor_head_id IS NOT NULL
          AND document_row.tractor_head_id = v_tractor_head_id)
        OR
        (v_trailer_id IS NOT NULL
          AND document_row.trailer_id = v_trailer_id)
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3433',
      MESSAGE = 'fleet_license_document_active_exists';
  END IF;

  IF length(btrim(p_original_file_name)) NOT BETWEEN 1 AND 255
     OR p_mime_type NOT IN (
       'application/pdf',
       'image/jpeg',
       'image/png',
       'image/webp',
       'image/heic',
       'image/heif'
     )
     OR p_size_bytes <= 0
     OR p_size_bytes > 10485760
     OR NOT private.fleet_license_document_storage_matches(
       p_company_id,
       p_asset_type,
       p_asset_id,
       p_storage_reference,
       p_mime_type,
       p_size_bytes
     )
     OR EXISTS (
       SELECT 1
       FROM public.fleet_license_documents document_row
       WHERE document_row.storage_reference = p_storage_reference
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3434',
      MESSAGE = 'fleet_license_document_invalid_storage_reference';
  END IF;

  INSERT INTO public.fleet_license_documents (
    company_id,
    tractor_head_id,
    trailer_id,
    storage_reference,
    original_file_name,
    mime_type,
    size_bytes,
    uploaded_by
  )
  VALUES (
    p_company_id,
    v_tractor_head_id,
    v_trailer_id,
    p_storage_reference,
    btrim(p_original_file_name),
    p_mime_type,
    p_size_bytes,
    v_actor_user_id
  )
  RETURNING *
  INTO v_document;

  v_new_expiry := COALESCE(p_license_expiry_date, v_old_expiry);

  IF p_license_expiry_date IS NOT NULL THEN
    IF p_asset_type = 'tractor_head' THEN
      UPDATE public.tractor_heads
      SET
        license_expiry_date = p_license_expiry_date,
        updated_by = v_actor_user_id,
        updated_at = now()
      WHERE company_id = p_company_id
        AND id = p_asset_id;
    ELSE
      UPDATE public.trailers
      SET
        license_expiry_date = p_license_expiry_date,
        updated_by = v_actor_user_id,
        updated_at = now()
      WHERE company_id = p_company_id
        AND id = p_asset_id;
    END IF;
  END IF;

  PERFORM private.write_audit_event(
    p_company_id,
    'fleet',
    p_asset_type,
    p_asset_id::text,
    v_plate_number,
    'updated',
    'fleet_license_document_uploaded',
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_old_expiry
    ),
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_new_expiry,
      'license_document_file_name', v_document.original_file_name,
      'license_document_mime_type', v_document.mime_type,
      'license_document_size_bytes', v_document.size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'document_id', v_document.id,
      'asset_type', p_asset_type,
      'asset_id', p_asset_id,
      'original_file_name', v_document.original_file_name
    )
  );

  RETURN to_jsonb(v_document);
END;
$function$;

CREATE OR REPLACE FUNCTION public.replace_fleet_license_document_atomic(
  p_company_id uuid,
  p_asset_type text,
  p_asset_id uuid,
  p_document_id uuid,
  p_storage_reference text,
  p_original_file_name text,
  p_mime_type text,
  p_size_bytes bigint,
  p_license_expiry_date date DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_plate_number text;
  v_old_expiry date;
  v_new_expiry date;
  v_tractor_head_id uuid;
  v_trailer_id uuid;
  v_old_document public.fleet_license_documents%ROWTYPE;
  v_new_document public.fleet_license_documents%ROWTYPE;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3430',
      MESSAGE = 'fleet_license_document_permission_denied';
  END IF;

  IF p_asset_type = 'tractor_head' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_old_expiry
    FROM public.tractor_heads asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P3431',
        MESSAGE = 'fleet_license_document_asset_not_found';
    END IF;

    v_tractor_head_id := p_asset_id;
  ELSIF p_asset_type = 'trailer' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_old_expiry
    FROM public.trailers asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P3431',
        MESSAGE = 'fleet_license_document_asset_not_found';
    END IF;

    v_trailer_id := p_asset_id;
  ELSE
    RAISE EXCEPTION USING
      ERRCODE = 'P3435',
      MESSAGE = 'fleet_license_document_asset_type_invalid';
  END IF;

  SELECT document_row.*
  INTO v_old_document
  FROM public.fleet_license_documents document_row
  WHERE document_row.company_id = p_company_id
    AND document_row.id = p_document_id
    AND document_row.removed_at IS NULL
    AND (
      (v_tractor_head_id IS NOT NULL
        AND document_row.tractor_head_id = v_tractor_head_id)
      OR
      (v_trailer_id IS NOT NULL
        AND document_row.trailer_id = v_trailer_id)
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3432',
      MESSAGE = 'fleet_license_document_not_found';
  END IF;

  IF length(btrim(p_original_file_name)) NOT BETWEEN 1 AND 255
     OR p_mime_type NOT IN (
       'application/pdf',
       'image/jpeg',
       'image/png',
       'image/webp',
       'image/heic',
       'image/heif'
     )
     OR p_size_bytes <= 0
     OR p_size_bytes > 10485760
     OR NOT private.fleet_license_document_storage_matches(
       p_company_id,
       p_asset_type,
       p_asset_id,
       p_storage_reference,
       p_mime_type,
       p_size_bytes
     )
     OR EXISTS (
       SELECT 1
       FROM public.fleet_license_documents document_row
       WHERE document_row.storage_reference = p_storage_reference
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3434',
      MESSAGE = 'fleet_license_document_invalid_storage_reference';
  END IF;

  UPDATE public.fleet_license_documents
  SET
    removed_by = v_actor_user_id,
    removed_at = now()
  WHERE company_id = p_company_id
    AND id = p_document_id;

  INSERT INTO public.fleet_license_documents (
    company_id,
    tractor_head_id,
    trailer_id,
    storage_reference,
    original_file_name,
    mime_type,
    size_bytes,
    uploaded_by,
    replaces_document_id
  )
  VALUES (
    p_company_id,
    v_tractor_head_id,
    v_trailer_id,
    p_storage_reference,
    btrim(p_original_file_name),
    p_mime_type,
    p_size_bytes,
    v_actor_user_id,
    v_old_document.id
  )
  RETURNING *
  INTO v_new_document;

  v_new_expiry := COALESCE(p_license_expiry_date, v_old_expiry);

  IF p_license_expiry_date IS NOT NULL THEN
    IF p_asset_type = 'tractor_head' THEN
      UPDATE public.tractor_heads
      SET
        license_expiry_date = p_license_expiry_date,
        updated_by = v_actor_user_id,
        updated_at = now()
      WHERE company_id = p_company_id
        AND id = p_asset_id;
    ELSE
      UPDATE public.trailers
      SET
        license_expiry_date = p_license_expiry_date,
        updated_by = v_actor_user_id,
        updated_at = now()
      WHERE company_id = p_company_id
        AND id = p_asset_id;
    END IF;
  END IF;

  PERFORM private.write_audit_event(
    p_company_id,
    'fleet',
    p_asset_type,
    p_asset_id::text,
    v_plate_number,
    'updated',
    'fleet_license_document_replaced',
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_old_expiry,
      'license_document_file_name', v_old_document.original_file_name,
      'license_document_mime_type', v_old_document.mime_type,
      'license_document_size_bytes', v_old_document.size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_new_expiry,
      'license_document_file_name', v_new_document.original_file_name,
      'license_document_mime_type', v_new_document.mime_type,
      'license_document_size_bytes', v_new_document.size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'document_id', v_new_document.id,
      'replaces_document_id', v_old_document.id,
      'asset_type', p_asset_type,
      'asset_id', p_asset_id,
      'original_file_name', v_new_document.original_file_name
    )
  );

  RETURN to_jsonb(v_new_document);
END;
$function$;

CREATE OR REPLACE FUNCTION public.remove_fleet_license_document_atomic(
  p_company_id uuid,
  p_asset_type text,
  p_asset_id uuid,
  p_document_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_plate_number text;
  v_license_expiry date;
  v_tractor_head_id uuid;
  v_trailer_id uuid;
  v_document public.fleet_license_documents%ROWTYPE;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3430',
      MESSAGE = 'fleet_license_document_permission_denied';
  END IF;

  IF p_asset_type = 'tractor_head' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_license_expiry
    FROM public.tractor_heads asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P3431',
        MESSAGE = 'fleet_license_document_asset_not_found';
    END IF;

    v_tractor_head_id := p_asset_id;
  ELSIF p_asset_type = 'trailer' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_license_expiry
    FROM public.trailers asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P3431',
        MESSAGE = 'fleet_license_document_asset_not_found';
    END IF;

    v_trailer_id := p_asset_id;
  ELSE
    RAISE EXCEPTION USING
      ERRCODE = 'P3435',
      MESSAGE = 'fleet_license_document_asset_type_invalid';
  END IF;

  SELECT document_row.*
  INTO v_document
  FROM public.fleet_license_documents document_row
  WHERE document_row.company_id = p_company_id
    AND document_row.id = p_document_id
    AND document_row.removed_at IS NULL
    AND (
      (v_tractor_head_id IS NOT NULL
        AND document_row.tractor_head_id = v_tractor_head_id)
      OR
      (v_trailer_id IS NOT NULL
        AND document_row.trailer_id = v_trailer_id)
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3432',
      MESSAGE = 'fleet_license_document_not_found';
  END IF;

  UPDATE public.fleet_license_documents
  SET
    removed_by = v_actor_user_id,
    removed_at = now()
  WHERE company_id = p_company_id
    AND id = p_document_id;

  PERFORM private.write_audit_event(
    p_company_id,
    'fleet',
    p_asset_type,
    p_asset_id::text,
    v_plate_number,
    'updated',
    'fleet_license_document_removed',
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_license_expiry,
      'license_document_file_name', v_document.original_file_name,
      'license_document_mime_type', v_document.mime_type,
      'license_document_size_bytes', v_document.size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_license_expiry,
      'license_document_removed', true
    ),
    pg_catalog.jsonb_build_object(
      'document_id', v_document.id,
      'asset_type', p_asset_type,
      'asset_id', p_asset_id,
      'original_file_name', v_document.original_file_name
    )
  );
END;
$function$;

REVOKE ALL
ON FUNCTION public.create_fleet_license_document_atomic(
  uuid,
  text,
  uuid,
  text,
  text,
  text,
  bigint,
  date
)
FROM PUBLIC, anon, authenticated;

REVOKE ALL
ON FUNCTION public.replace_fleet_license_document_atomic(
  uuid,
  text,
  uuid,
  uuid,
  text,
  text,
  text,
  bigint,
  date
)
FROM PUBLIC, anon, authenticated;

REVOKE ALL
ON FUNCTION public.remove_fleet_license_document_atomic(
  uuid,
  text,
  uuid,
  uuid
)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.create_fleet_license_document_atomic(
  uuid,
  text,
  uuid,
  text,
  text,
  text,
  bigint,
  date
)
TO authenticated;

GRANT EXECUTE
ON FUNCTION public.replace_fleet_license_document_atomic(
  uuid,
  text,
  uuid,
  uuid,
  text,
  text,
  text,
  bigint,
  date
)
TO authenticated;

GRANT EXECUTE
ON FUNCTION public.remove_fleet_license_document_atomic(
  uuid,
  text,
  uuid,
  uuid
)
TO authenticated;

DROP POLICY IF EXISTS business_documents_insert_managers
ON storage.objects;

DROP POLICY IF EXISTS business_documents_delete_managers
ON storage.objects;

DROP POLICY IF EXISTS business_documents_select_fleet_license_documents
ON storage.objects;

DROP POLICY IF EXISTS business_documents_insert_fleet_license_documents
ON storage.objects;

DROP POLICY IF EXISTS business_documents_delete_unregistered_fleet_license_documents
ON storage.objects;

CREATE POLICY business_documents_insert_managers
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'business-documents'
  AND private.trip_document_storage_trip_id(name) IS NULL
  AND private.fleet_license_document_storage_asset_type(name) IS NULL
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
  AND private.trip_document_storage_trip_id(name) IS NULL
  AND private.fleet_license_document_storage_asset_type(name) IS NULL
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin']::public.company_role[]
  )
);

CREATE POLICY business_documents_select_fleet_license_documents
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'business-documents'
  AND private.fleet_license_document_storage_asset_type(name) IS NOT NULL
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
  AND (
    (
      private.fleet_license_document_storage_asset_type(name) = 'tractor_head'
      AND EXISTS (
        SELECT 1
        FROM public.tractor_heads asset
        WHERE asset.company_id =
          private.business_document_company_id(name)
          AND asset.id =
            private.fleet_license_document_storage_asset_id(name)
      )
    )
    OR
    (
      private.fleet_license_document_storage_asset_type(name) = 'trailer'
      AND EXISTS (
        SELECT 1
        FROM public.trailers asset
        WHERE asset.company_id =
          private.business_document_company_id(name)
          AND asset.id =
            private.fleet_license_document_storage_asset_id(name)
      )
    )
  )
);

CREATE POLICY business_documents_insert_fleet_license_documents
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'business-documents'
  AND private.fleet_license_document_storage_asset_type(name) IS NOT NULL
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin', 'operations']::public.company_role[]
  )
  AND (
    (
      private.fleet_license_document_storage_asset_type(name) = 'tractor_head'
      AND EXISTS (
        SELECT 1
        FROM public.tractor_heads asset
        WHERE asset.company_id =
          private.business_document_company_id(name)
          AND asset.id =
            private.fleet_license_document_storage_asset_id(name)
      )
    )
    OR
    (
      private.fleet_license_document_storage_asset_type(name) = 'trailer'
      AND EXISTS (
        SELECT 1
        FROM public.trailers asset
        WHERE asset.company_id =
          private.business_document_company_id(name)
          AND asset.id =
            private.fleet_license_document_storage_asset_id(name)
      )
    )
  )
);

CREATE POLICY business_documents_delete_unregistered_fleet_license_documents
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'business-documents'
  AND private.fleet_license_document_storage_asset_type(name) IS NOT NULL
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin', 'operations']::public.company_role[]
  )
  AND (
    (
      private.fleet_license_document_storage_asset_type(name) = 'tractor_head'
      AND EXISTS (
        SELECT 1
        FROM public.tractor_heads asset
        WHERE asset.company_id =
          private.business_document_company_id(name)
          AND asset.id =
            private.fleet_license_document_storage_asset_id(name)
      )
    )
    OR
    (
      private.fleet_license_document_storage_asset_type(name) = 'trailer'
      AND EXISTS (
        SELECT 1
        FROM public.trailers asset
        WHERE asset.company_id =
          private.business_document_company_id(name)
          AND asset.id =
            private.fleet_license_document_storage_asset_id(name)
      )
    )
  )
  AND NOT EXISTS (
    SELECT 1
    FROM public.fleet_license_documents document_row
    WHERE document_row.company_id =
      private.business_document_company_id(name)
      AND document_row.storage_reference = name
  )
);

COMMIT;
