-- H.O.R.U.S System — Issue #236 / PC-12 refinement
-- Model one active Fleet license aggregate with front/back child files.
-- Existing single-file rows are migrated as legacy "combined" files.

BEGIN;

DROP POLICY IF EXISTS business_documents_delete_unregistered_fleet_license_documents
ON storage.objects;

DROP FUNCTION IF EXISTS public.create_fleet_license_document_atomic(
  uuid, text, uuid, text, text, text, bigint, date
);

DROP FUNCTION IF EXISTS public.replace_fleet_license_document_atomic(
  uuid, text, uuid, uuid, text, text, text, bigint, date
);

CREATE TABLE public.fleet_license_document_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL
    REFERENCES public.companies(id)
    ON DELETE CASCADE,
  license_document_id uuid NOT NULL,
  side text NOT NULL,
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
  replaces_file_id uuid,
  CONSTRAINT fleet_license_document_files_company_id_id_unique
    UNIQUE (company_id, id),
  CONSTRAINT fleet_license_document_files_document_fk
    FOREIGN KEY (company_id, license_document_id)
    REFERENCES public.fleet_license_documents(company_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fleet_license_document_files_replaces_fk
    FOREIGN KEY (company_id, replaces_file_id)
    REFERENCES public.fleet_license_document_files(company_id, id),
  CONSTRAINT fleet_license_document_files_side_check
    CHECK (side IN ('front', 'back', 'combined')),
  CONSTRAINT fleet_license_document_files_original_file_name_check
    CHECK (length(btrim(original_file_name)) BETWEEN 1 AND 255),
  CONSTRAINT fleet_license_document_files_mime_type_check
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
  CONSTRAINT fleet_license_document_files_size_bytes_check
    CHECK (size_bytes > 0 AND size_bytes <= 10485760),
  CONSTRAINT fleet_license_document_files_removed_at_check
    CHECK (removed_at IS NULL OR removed_at >= uploaded_at)
);

CREATE UNIQUE INDEX fleet_license_document_files_storage_reference_unique_idx
  ON public.fleet_license_document_files(storage_reference);

CREATE UNIQUE INDEX fleet_license_document_files_active_side_unique_idx
  ON public.fleet_license_document_files(
    company_id,
    license_document_id,
    side
  )
  WHERE removed_at IS NULL;

CREATE UNIQUE INDEX fleet_license_document_files_replaces_once_idx
  ON public.fleet_license_document_files(company_id, replaces_file_id);

CREATE INDEX fleet_license_document_files_document_idx
  ON public.fleet_license_document_files(company_id, license_document_id);

CREATE INDEX fleet_license_document_files_uploaded_by_idx
  ON public.fleet_license_document_files(uploaded_by)
  WHERE uploaded_by IS NOT NULL;

CREATE INDEX fleet_license_document_files_removed_by_idx
  ON public.fleet_license_document_files(removed_by)
  WHERE removed_by IS NOT NULL;

INSERT INTO public.fleet_license_document_files (
  company_id,
  license_document_id,
  side,
  storage_reference,
  original_file_name,
  mime_type,
  size_bytes,
  uploaded_by,
  uploaded_at,
  removed_by,
  removed_at
)
SELECT
  company_id,
  id,
  'combined',
  storage_reference,
  original_file_name,
  mime_type,
  size_bytes,
  uploaded_by,
  uploaded_at,
  removed_by,
  removed_at
FROM public.fleet_license_documents;

DROP INDEX IF EXISTS public.fleet_license_documents_storage_reference_unique_idx;

ALTER TABLE public.fleet_license_documents
  DROP CONSTRAINT IF EXISTS fleet_license_documents_original_file_name_check,
  DROP CONSTRAINT IF EXISTS fleet_license_documents_mime_type_check,
  DROP CONSTRAINT IF EXISTS fleet_license_documents_size_bytes_check,
  DROP COLUMN storage_reference,
  DROP COLUMN original_file_name,
  DROP COLUMN mime_type,
  DROP COLUMN size_bytes;

ALTER TABLE public.fleet_license_document_files ENABLE ROW LEVEL SECURITY;

REVOKE ALL
ON TABLE public.fleet_license_document_files
FROM anon, authenticated;

GRANT SELECT
ON TABLE public.fleet_license_document_files
TO authenticated;

GRANT ALL
ON TABLE public.fleet_license_document_files
TO service_role;

CREATE POLICY fleet_license_document_files_select_authorized
ON public.fleet_license_document_files
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

CREATE OR REPLACE FUNCTION public.create_fleet_license_document_atomic(
  p_company_id uuid,
  p_asset_type text,
  p_asset_id uuid,
  p_file_side text,
  p_storage_reference text,
  p_original_file_name text,
  p_mime_type text,
  p_size_bytes bigint,
  p_license_expiry_date date DEFAULT NULL
)
RETURNS uuid
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
  v_replaces_document_id uuid;
  v_document_id uuid;
  v_file_id uuid;
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

  IF p_file_side NOT IN ('front', 'back', 'combined') THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3438',
      MESSAGE = 'fleet_license_document_file_side_invalid';
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
       FROM public.fleet_license_document_files file_row
       WHERE file_row.storage_reference = p_storage_reference
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3434',
      MESSAGE = 'fleet_license_document_invalid_storage_reference';
  END IF;

  SELECT document_row.id
  INTO v_replaces_document_id
  FROM public.fleet_license_documents document_row
  WHERE document_row.company_id = p_company_id
    AND document_row.removed_at IS NOT NULL
    AND (
      (v_tractor_head_id IS NOT NULL
        AND document_row.tractor_head_id = v_tractor_head_id)
      OR
      (v_trailer_id IS NOT NULL
        AND document_row.trailer_id = v_trailer_id)
    )
  ORDER BY document_row.removed_at DESC, document_row.uploaded_at DESC
  LIMIT 1;

  INSERT INTO public.fleet_license_documents (
    company_id,
    tractor_head_id,
    trailer_id,
    uploaded_by,
    replaces_document_id
  )
  VALUES (
    p_company_id,
    v_tractor_head_id,
    v_trailer_id,
    v_actor_user_id,
    v_replaces_document_id
  )
  RETURNING id
  INTO v_document_id;

  INSERT INTO public.fleet_license_document_files (
    company_id,
    license_document_id,
    side,
    storage_reference,
    original_file_name,
    mime_type,
    size_bytes,
    uploaded_by
  )
  VALUES (
    p_company_id,
    v_document_id,
    p_file_side,
    p_storage_reference,
    btrim(p_original_file_name),
    p_mime_type,
    p_size_bytes,
    v_actor_user_id
  )
  RETURNING id
  INTO v_file_id;

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
      'license_document_side', p_file_side,
      'license_document_file_name', btrim(p_original_file_name),
      'license_document_mime_type', p_mime_type,
      'license_document_size_bytes', p_size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'document_id', v_document_id,
      'file_id', v_file_id,
      'asset_type', p_asset_type,
      'asset_id', p_asset_id
    )
  );

  RETURN v_document_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.add_fleet_license_document_file_atomic(
  p_company_id uuid,
  p_asset_type text,
  p_asset_id uuid,
  p_document_id uuid,
  p_file_side text,
  p_storage_reference text,
  p_original_file_name text,
  p_mime_type text,
  p_size_bytes bigint,
  p_license_expiry_date date DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_plate_number text;
  v_old_expiry date;
  v_new_expiry date;
  v_file_id uuid;
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

  IF p_file_side NOT IN ('front', 'back') THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3438',
      MESSAGE = 'fleet_license_document_file_side_invalid';
  END IF;

  IF p_asset_type = 'tractor_head' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_old_expiry
    FROM public.tractor_heads asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;
  ELSIF p_asset_type = 'trailer' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_old_expiry
    FROM public.trailers asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;
  ELSE
    RAISE EXCEPTION USING
      ERRCODE = 'P3435',
      MESSAGE = 'fleet_license_document_asset_type_invalid';
  END IF;

  IF v_plate_number IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3431',
      MESSAGE = 'fleet_license_document_asset_not_found';
  END IF;

  PERFORM 1
  FROM public.fleet_license_documents document_row
  WHERE document_row.company_id = p_company_id
    AND document_row.id = p_document_id
    AND document_row.removed_at IS NULL
    AND (
      (p_asset_type = 'tractor_head'
        AND document_row.tractor_head_id = p_asset_id)
      OR
      (p_asset_type = 'trailer'
        AND document_row.trailer_id = p_asset_id)
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3432',
      MESSAGE = 'fleet_license_document_not_found';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.fleet_license_document_files file_row
    WHERE file_row.company_id = p_company_id
      AND file_row.license_document_id = p_document_id
      AND file_row.removed_at IS NULL
      AND file_row.side IN ('combined', p_file_side)
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3436',
      MESSAGE = 'fleet_license_document_file_side_conflict';
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
       FROM public.fleet_license_document_files file_row
       WHERE file_row.storage_reference = p_storage_reference
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3434',
      MESSAGE = 'fleet_license_document_invalid_storage_reference';
  END IF;

  INSERT INTO public.fleet_license_document_files (
    company_id,
    license_document_id,
    side,
    storage_reference,
    original_file_name,
    mime_type,
    size_bytes,
    uploaded_by
  )
  VALUES (
    p_company_id,
    p_document_id,
    p_file_side,
    p_storage_reference,
    btrim(p_original_file_name),
    p_mime_type,
    p_size_bytes,
    v_actor_user_id
  )
  RETURNING id
  INTO v_file_id;

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
    'fleet_license_document_file_added',
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_old_expiry
    ),
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_new_expiry,
      'license_document_side', p_file_side,
      'license_document_file_name', btrim(p_original_file_name),
      'license_document_mime_type', p_mime_type,
      'license_document_size_bytes', p_size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'document_id', p_document_id,
      'file_id', v_file_id,
      'asset_type', p_asset_type,
      'asset_id', p_asset_id
    )
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.replace_fleet_license_document_file_atomic(
  p_company_id uuid,
  p_asset_type text,
  p_asset_id uuid,
  p_document_id uuid,
  p_file_id uuid,
  p_file_side text,
  p_storage_reference text,
  p_original_file_name text,
  p_mime_type text,
  p_size_bytes bigint,
  p_license_expiry_date date DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_plate_number text;
  v_old_expiry date;
  v_new_expiry date;
  v_old_file public.fleet_license_document_files%ROWTYPE;
  v_new_file_id uuid;
  v_removed_at timestamptz := now();
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

  IF p_file_side NOT IN ('front', 'back', 'combined') THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3438',
      MESSAGE = 'fleet_license_document_file_side_invalid';
  END IF;

  IF p_asset_type = 'tractor_head' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_old_expiry
    FROM public.tractor_heads asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;
  ELSIF p_asset_type = 'trailer' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_old_expiry
    FROM public.trailers asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;
  ELSE
    RAISE EXCEPTION USING
      ERRCODE = 'P3435',
      MESSAGE = 'fleet_license_document_asset_type_invalid';
  END IF;

  IF v_plate_number IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3431',
      MESSAGE = 'fleet_license_document_asset_not_found';
  END IF;

  PERFORM 1
  FROM public.fleet_license_documents document_row
  WHERE document_row.company_id = p_company_id
    AND document_row.id = p_document_id
    AND document_row.removed_at IS NULL
    AND (
      (p_asset_type = 'tractor_head'
        AND document_row.tractor_head_id = p_asset_id)
      OR
      (p_asset_type = 'trailer'
        AND document_row.trailer_id = p_asset_id)
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3432',
      MESSAGE = 'fleet_license_document_not_found';
  END IF;

  SELECT file_row.*
  INTO v_old_file
  FROM public.fleet_license_document_files file_row
  WHERE file_row.company_id = p_company_id
    AND file_row.license_document_id = p_document_id
    AND file_row.id = p_file_id
    AND file_row.side = p_file_side
    AND file_row.removed_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3437',
      MESSAGE = 'fleet_license_document_file_not_found';
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
       FROM public.fleet_license_document_files file_row
       WHERE file_row.storage_reference = p_storage_reference
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3434',
      MESSAGE = 'fleet_license_document_invalid_storage_reference';
  END IF;

  UPDATE public.fleet_license_document_files
  SET
    removed_by = v_actor_user_id,
    removed_at = v_removed_at
  WHERE company_id = p_company_id
    AND id = p_file_id;

  INSERT INTO public.fleet_license_document_files (
    company_id,
    license_document_id,
    side,
    storage_reference,
    original_file_name,
    mime_type,
    size_bytes,
    uploaded_by,
    replaces_file_id
  )
  VALUES (
    p_company_id,
    p_document_id,
    p_file_side,
    p_storage_reference,
    btrim(p_original_file_name),
    p_mime_type,
    p_size_bytes,
    v_actor_user_id,
    p_file_id
  )
  RETURNING id
  INTO v_new_file_id;

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
    'fleet_license_document_file_replaced',
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_old_expiry,
      'license_document_side', v_old_file.side,
      'license_document_file_name', v_old_file.original_file_name,
      'license_document_mime_type', v_old_file.mime_type,
      'license_document_size_bytes', v_old_file.size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_new_expiry,
      'license_document_side', p_file_side,
      'license_document_file_name', btrim(p_original_file_name),
      'license_document_mime_type', p_mime_type,
      'license_document_size_bytes', p_size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'document_id', p_document_id,
      'file_id', v_new_file_id,
      'replaces_file_id', p_file_id,
      'asset_type', p_asset_type,
      'asset_id', p_asset_id
    )
  );
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
  v_removed_at timestamptz := now();
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
  ELSIF p_asset_type = 'trailer' THEN
    SELECT asset.plate_number, asset.license_expiry_date
    INTO v_plate_number, v_license_expiry
    FROM public.trailers asset
    WHERE asset.company_id = p_company_id
      AND asset.id = p_asset_id
    FOR UPDATE;
  ELSE
    RAISE EXCEPTION USING
      ERRCODE = 'P3435',
      MESSAGE = 'fleet_license_document_asset_type_invalid';
  END IF;

  IF v_plate_number IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3431',
      MESSAGE = 'fleet_license_document_asset_not_found';
  END IF;

  PERFORM 1
  FROM public.fleet_license_documents document_row
  WHERE document_row.company_id = p_company_id
    AND document_row.id = p_document_id
    AND document_row.removed_at IS NULL
    AND (
      (p_asset_type = 'tractor_head'
        AND document_row.tractor_head_id = p_asset_id)
      OR
      (p_asset_type = 'trailer'
        AND document_row.trailer_id = p_asset_id)
    )
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3432',
      MESSAGE = 'fleet_license_document_not_found';
  END IF;

  UPDATE public.fleet_license_document_files
  SET
    removed_by = v_actor_user_id,
    removed_at = v_removed_at
  WHERE company_id = p_company_id
    AND license_document_id = p_document_id
    AND removed_at IS NULL;

  UPDATE public.fleet_license_documents
  SET
    removed_by = v_actor_user_id,
    removed_at = v_removed_at
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
      'license_expiry_date', v_license_expiry
    ),
    pg_catalog.jsonb_build_object(
      'license_expiry_date', v_license_expiry,
      'license_document_removed', true
    ),
    pg_catalog.jsonb_build_object(
      'document_id', p_document_id,
      'asset_type', p_asset_type,
      'asset_id', p_asset_id
    )
  );
END;
$function$;

REVOKE ALL
ON FUNCTION public.create_fleet_license_document_atomic(
  uuid, text, uuid, text, text, text, text, bigint, date
)
FROM PUBLIC, anon, authenticated;

REVOKE ALL
ON FUNCTION public.add_fleet_license_document_file_atomic(
  uuid, text, uuid, uuid, text, text, text, text, bigint, date
)
FROM PUBLIC, anon, authenticated;

REVOKE ALL
ON FUNCTION public.replace_fleet_license_document_file_atomic(
  uuid, text, uuid, uuid, uuid, text, text, text, text, bigint, date
)
FROM PUBLIC, anon, authenticated;

REVOKE ALL
ON FUNCTION public.remove_fleet_license_document_atomic(
  uuid, text, uuid, uuid
)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.create_fleet_license_document_atomic(
  uuid, text, uuid, text, text, text, text, bigint, date
)
TO authenticated;

GRANT EXECUTE
ON FUNCTION public.add_fleet_license_document_file_atomic(
  uuid, text, uuid, uuid, text, text, text, text, bigint, date
)
TO authenticated;

GRANT EXECUTE
ON FUNCTION public.replace_fleet_license_document_file_atomic(
  uuid, text, uuid, uuid, uuid, text, text, text, text, bigint, date
)
TO authenticated;

GRANT EXECUTE
ON FUNCTION public.remove_fleet_license_document_atomic(
  uuid, text, uuid, uuid
)
TO authenticated;

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
    FROM public.fleet_license_document_files file_row
    WHERE file_row.company_id =
      private.business_document_company_id(name)
      AND file_row.storage_reference = name
  )
);

COMMIT;
