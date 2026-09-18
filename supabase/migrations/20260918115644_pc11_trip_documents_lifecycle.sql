-- H.O.R.U.S System — Issue #235 / PC-11
-- Evidence-backed Trip documents lifecycle.
--
-- Responsibilities:
-- - company-scoped Trip document metadata with logical removal/replacement
-- - atomic metadata mutations and structured audit writes
-- - evidence invariant for protected Trip statuses
-- - least-privilege Trip mutation grants
-- - Trip-scoped Storage RLS on top of the PC-03 business-documents bucket

BEGIN;

CREATE TABLE public.trip_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL
    REFERENCES public.companies(id)
    ON DELETE CASCADE,
  trip_id uuid NOT NULL,
  document_kind text NOT NULL,
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
  CONSTRAINT trip_documents_company_trip_fk
    FOREIGN KEY (company_id, trip_id)
    REFERENCES public.trips(company_id, id)
    ON DELETE CASCADE,
  CONSTRAINT trip_documents_company_id_id_unique
    UNIQUE (company_id, id),
  CONSTRAINT trip_documents_company_replaces_fk
    FOREIGN KEY (company_id, replaces_document_id)
    REFERENCES public.trip_documents(company_id, id),
  CONSTRAINT trip_documents_kind_check
    CHECK (
      document_kind IN (
        'loading_order',
        'waybill',
        'proof_of_delivery',
        'other'
      )
    ),
  CONSTRAINT trip_documents_original_file_name_check
    CHECK (length(btrim(original_file_name)) BETWEEN 1 AND 255),
  CONSTRAINT trip_documents_mime_type_check
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
  CONSTRAINT trip_documents_size_bytes_check
    CHECK (size_bytes > 0 AND size_bytes <= 10485760),
  CONSTRAINT trip_documents_removed_at_check
    CHECK (removed_at IS NULL OR removed_at >= uploaded_at)
);

CREATE UNIQUE INDEX trip_documents_storage_reference_unique_idx
  ON public.trip_documents(storage_reference);

CREATE UNIQUE INDEX trip_documents_replaces_once_idx
  ON public.trip_documents(replaces_document_id)
  WHERE replaces_document_id IS NOT NULL;

CREATE INDEX trip_documents_active_trip_uploaded_idx
  ON public.trip_documents(company_id, trip_id, uploaded_at DESC)
  WHERE removed_at IS NULL;

CREATE INDEX trip_documents_active_trip_kind_idx
  ON public.trip_documents(company_id, trip_id, document_kind)
  WHERE removed_at IS NULL;

ALTER TABLE public.trip_documents ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.trip_documents FROM anon, authenticated;
GRANT SELECT ON TABLE public.trip_documents TO authenticated;
GRANT ALL ON TABLE public.trip_documents TO service_role;

CREATE POLICY trip_documents_select_authorized
ON public.trip_documents
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

CREATE OR REPLACE FUNCTION private.trip_document_storage_trip_id(
  object_name text
)
RETURNS uuid
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
  SELECT CASE
    WHEN object_name ~ '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/trips/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/(loading-order|waybill|proof-of-delivery|other)/[0-9a-f]{32}\.(pdf|jpg|jpeg|png|webp|heic|heif)$'
      THEN split_part(object_name, '/', 4)::uuid
    ELSE NULL
  END;
$function$;

CREATE OR REPLACE FUNCTION private.trip_document_storage_kind(
  object_name text
)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
  SELECT CASE
    WHEN private.trip_document_storage_trip_id(object_name) IS NULL
      THEN NULL
    ELSE CASE split_part(object_name, '/', 5)
      WHEN 'loading-order' THEN 'loading_order'
      WHEN 'waybill' THEN 'waybill'
      WHEN 'proof-of-delivery' THEN 'proof_of_delivery'
      WHEN 'other' THEN 'other'
      ELSE NULL
    END
  END;
$function$;

REVOKE ALL
ON FUNCTION private.trip_document_storage_trip_id(text)
FROM PUBLIC, anon, authenticated;

REVOKE ALL
ON FUNCTION private.trip_document_storage_kind(text)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION private.trip_document_storage_trip_id(text)
TO authenticated;

GRANT EXECUTE
ON FUNCTION private.trip_document_storage_kind(text)
TO authenticated;

CREATE OR REPLACE FUNCTION private.trip_document_storage_matches(
  p_company_id uuid,
  p_trip_id uuid,
  p_document_kind text,
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
    AND private.trip_document_storage_trip_id(p_storage_reference) = p_trip_id
    AND private.trip_document_storage_kind(p_storage_reference) = p_document_kind
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
ON FUNCTION private.trip_document_storage_matches(
  uuid,
  uuid,
  text,
  text,
  text,
  bigint
)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.trip_has_required_evidence(
  p_company_id uuid,
  p_trip_id uuid,
  p_excluding_document_id uuid DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.trip_documents document_row
    WHERE document_row.company_id = p_company_id
      AND document_row.trip_id = p_trip_id
      AND document_row.removed_at IS NULL
      AND document_row.document_kind IN ('waybill', 'proof_of_delivery')
      AND (
        p_excluding_document_id IS NULL
        OR document_row.id <> p_excluding_document_id
      )
  );
$function$;

REVOKE ALL
ON FUNCTION private.trip_has_required_evidence(uuid, uuid, uuid)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.enforce_trip_evidence_status_invariant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  IF NEW.status IN (
       'documents_received'::public.trip_status,
       'invoiced'::public.trip_status,
       'paid'::public.trip_status
     )
     AND (
       TG_OP = 'INSERT'
       OR NEW.status IS DISTINCT FROM OLD.status
     )
     AND NOT private.trip_has_required_evidence(NEW.company_id, NEW.id) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3424',
      MESSAGE = 'trip_document_required_evidence';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL
ON FUNCTION private.enforce_trip_evidence_status_invariant()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trips_evidence_status_invariant
ON public.trips;

CREATE TRIGGER trips_evidence_status_invariant
BEFORE INSERT OR UPDATE OF status
ON public.trips
FOR EACH ROW
EXECUTE FUNCTION private.enforce_trip_evidence_status_invariant();

CREATE OR REPLACE FUNCTION public.create_trip_document_atomic(
  p_company_id uuid,
  p_trip_id uuid,
  p_document_kind text,
  p_storage_reference text,
  p_original_file_name text,
  p_mime_type text,
  p_size_bytes bigint
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_trip public.trips%ROWTYPE;
  v_document public.trip_documents%ROWTYPE;
  v_snapshot jsonb;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3420',
      MESSAGE = 'trip_document_permission_denied';
  END IF;

  SELECT trip_row.*
  INTO v_trip
  FROM public.trips trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3421',
      MESSAGE = 'trip_document_trip_not_found';
  END IF;

  IF p_document_kind NOT IN (
       'loading_order',
       'waybill',
       'proof_of_delivery',
       'other'
     )
     OR length(btrim(p_original_file_name)) NOT BETWEEN 1 AND 255
     OR p_mime_type NOT IN (
       'application/pdf',
       'image/jpeg',
       'image/png',
       'image/webp',
       'image/heic',
       'image/heif'
     )
     OR p_size_bytes <= 0
     OR p_size_bytes > 10485760 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3425',
      MESSAGE = 'trip_document_invalid_storage_reference';
  END IF;

  IF NOT private.trip_document_storage_matches(
    p_company_id,
    p_trip_id,
    p_document_kind,
    p_storage_reference,
    p_mime_type,
    p_size_bytes
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3425',
      MESSAGE = 'trip_document_invalid_storage_reference';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.trip_documents document_row
    WHERE document_row.storage_reference = p_storage_reference
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3425',
      MESSAGE = 'trip_document_invalid_storage_reference';
  END IF;

  IF (
    SELECT count(*)
    FROM public.trip_documents document_row
    WHERE document_row.company_id = p_company_id
      AND document_row.trip_id = p_trip_id
      AND document_row.removed_at IS NULL
  ) >= 10 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3423',
      MESSAGE = 'trip_document_max_active';
  END IF;

  INSERT INTO public.trip_documents (
    company_id,
    trip_id,
    document_kind,
    storage_reference,
    original_file_name,
    mime_type,
    size_bytes,
    uploaded_by
  )
  VALUES (
    p_company_id,
    p_trip_id,
    p_document_kind,
    p_storage_reference,
    btrim(p_original_file_name),
    p_mime_type,
    p_size_bytes,
    v_actor_user_id
  )
  RETURNING *
  INTO v_document;

  v_snapshot := private.trip_snapshot_json(p_company_id, p_trip_id);

  PERFORM private.write_audit_event(
    p_company_id,
    'trips',
    'trip',
    p_trip_id::text,
    private.trip_entity_display_name(v_snapshot),
    'updated',
    'trip_document_uploaded',
    NULL,
    pg_catalog.jsonb_build_object(
      'document_id', v_document.id,
      'document_kind', v_document.document_kind,
      'original_file_name', v_document.original_file_name,
      'mime_type', v_document.mime_type,
      'size_bytes', v_document.size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'document_id', v_document.id,
      'document_kind', v_document.document_kind,
      'original_file_name', v_document.original_file_name
    )
  );

  RETURN to_jsonb(v_document);
END;
$function$;

CREATE OR REPLACE FUNCTION public.replace_trip_document_atomic(
  p_company_id uuid,
  p_trip_id uuid,
  p_document_id uuid,
  p_storage_reference text,
  p_original_file_name text,
  p_mime_type text,
  p_size_bytes bigint
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_trip public.trips%ROWTYPE;
  v_old_document public.trip_documents%ROWTYPE;
  v_new_document public.trip_documents%ROWTYPE;
  v_snapshot jsonb;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3420',
      MESSAGE = 'trip_document_permission_denied';
  END IF;

  SELECT trip_row.*
  INTO v_trip
  FROM public.trips trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3421',
      MESSAGE = 'trip_document_trip_not_found';
  END IF;

  SELECT document_row.*
  INTO v_old_document
  FROM public.trip_documents document_row
  WHERE document_row.company_id = p_company_id
    AND document_row.trip_id = p_trip_id
    AND document_row.id = p_document_id
    AND document_row.removed_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3422',
      MESSAGE = 'trip_document_not_found';
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
     OR NOT private.trip_document_storage_matches(
       p_company_id,
       p_trip_id,
       v_old_document.document_kind,
       p_storage_reference,
       p_mime_type,
       p_size_bytes
     )
     OR EXISTS (
       SELECT 1
       FROM public.trip_documents document_row
       WHERE document_row.storage_reference = p_storage_reference
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3425',
      MESSAGE = 'trip_document_invalid_storage_reference';
  END IF;

  UPDATE public.trip_documents
  SET
    removed_by = v_actor_user_id,
    removed_at = now()
  WHERE company_id = p_company_id
    AND trip_id = p_trip_id
    AND id = p_document_id;

  INSERT INTO public.trip_documents (
    company_id,
    trip_id,
    document_kind,
    storage_reference,
    original_file_name,
    mime_type,
    size_bytes,
    uploaded_by,
    replaces_document_id
  )
  VALUES (
    p_company_id,
    p_trip_id,
    v_old_document.document_kind,
    p_storage_reference,
    btrim(p_original_file_name),
    p_mime_type,
    p_size_bytes,
    v_actor_user_id,
    v_old_document.id
  )
  RETURNING *
  INTO v_new_document;

  v_snapshot := private.trip_snapshot_json(p_company_id, p_trip_id);

  PERFORM private.write_audit_event(
    p_company_id,
    'trips',
    'trip',
    p_trip_id::text,
    private.trip_entity_display_name(v_snapshot),
    'updated',
    'trip_document_replaced',
    pg_catalog.jsonb_build_object(
      'document_id', v_old_document.id,
      'document_kind', v_old_document.document_kind,
      'original_file_name', v_old_document.original_file_name,
      'mime_type', v_old_document.mime_type,
      'size_bytes', v_old_document.size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'document_id', v_new_document.id,
      'document_kind', v_new_document.document_kind,
      'original_file_name', v_new_document.original_file_name,
      'mime_type', v_new_document.mime_type,
      'size_bytes', v_new_document.size_bytes
    ),
    pg_catalog.jsonb_build_object(
      'document_id', v_new_document.id,
      'replaces_document_id', v_old_document.id,
      'document_kind', v_new_document.document_kind,
      'original_file_name', v_new_document.original_file_name
    )
  );

  RETURN to_jsonb(v_new_document);
END;
$function$;

CREATE OR REPLACE FUNCTION public.remove_trip_document_atomic(
  p_company_id uuid,
  p_trip_id uuid,
  p_document_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_trip public.trips%ROWTYPE;
  v_document public.trip_documents%ROWTYPE;
  v_snapshot jsonb;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3420',
      MESSAGE = 'trip_document_permission_denied';
  END IF;

  SELECT trip_row.*
  INTO v_trip
  FROM public.trips trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3421',
      MESSAGE = 'trip_document_trip_not_found';
  END IF;

  SELECT document_row.*
  INTO v_document
  FROM public.trip_documents document_row
  WHERE document_row.company_id = p_company_id
    AND document_row.trip_id = p_trip_id
    AND document_row.id = p_document_id
    AND document_row.removed_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3422',
      MESSAGE = 'trip_document_not_found';
  END IF;

  IF v_trip.status IN (
       'documents_received'::public.trip_status,
       'invoiced'::public.trip_status,
       'paid'::public.trip_status
     )
     AND v_document.document_kind IN ('waybill', 'proof_of_delivery')
     AND NOT private.trip_has_required_evidence(
       p_company_id,
       p_trip_id,
       p_document_id
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3424',
      MESSAGE = 'trip_document_required_evidence';
  END IF;

  UPDATE public.trip_documents
  SET
    removed_by = v_actor_user_id,
    removed_at = now()
  WHERE company_id = p_company_id
    AND trip_id = p_trip_id
    AND id = p_document_id;

  v_snapshot := private.trip_snapshot_json(p_company_id, p_trip_id);

  PERFORM private.write_audit_event(
    p_company_id,
    'trips',
    'trip',
    p_trip_id::text,
    private.trip_entity_display_name(v_snapshot),
    'updated',
    'trip_document_removed',
    pg_catalog.jsonb_build_object(
      'document_id', v_document.id,
      'document_kind', v_document.document_kind,
      'original_file_name', v_document.original_file_name,
      'mime_type', v_document.mime_type,
      'size_bytes', v_document.size_bytes
    ),
    pg_catalog.jsonb_build_object('removed', true),
    pg_catalog.jsonb_build_object(
      'document_id', v_document.id,
      'document_kind', v_document.document_kind,
      'original_file_name', v_document.original_file_name
    )
  );
END;
$function$;

REVOKE ALL
ON FUNCTION public.create_trip_document_atomic(
  uuid,
  uuid,
  text,
  text,
  text,
  text,
  bigint
)
FROM PUBLIC, anon, authenticated;

REVOKE ALL
ON FUNCTION public.replace_trip_document_atomic(
  uuid,
  uuid,
  uuid,
  text,
  text,
  text,
  bigint
)
FROM PUBLIC, anon, authenticated;

REVOKE ALL
ON FUNCTION public.remove_trip_document_atomic(uuid, uuid, uuid)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.create_trip_document_atomic(
  uuid,
  uuid,
  text,
  text,
  text,
  text,
  bigint
)
TO authenticated;

GRANT EXECUTE
ON FUNCTION public.replace_trip_document_atomic(
  uuid,
  uuid,
  uuid,
  text,
  text,
  text,
  bigint
)
TO authenticated;

GRANT EXECUTE
ON FUNCTION public.remove_trip_document_atomic(uuid, uuid, uuid)
TO authenticated;

CREATE OR REPLACE FUNCTION public.update_trip_status_atomic(
  p_company_id uuid,
  p_trip_id uuid,
  p_new_status public.trip_status,
  p_notes text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor jsonb;
  v_old_status public.trip_status;
  v_old_audit jsonb;
  v_snapshot jsonb;
  v_new_audit jsonb;
  v_notes text := NULLIF(pg_catalog.btrim(p_notes), '');
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3411',
      MESSAGE = 'trip_status_permission_denied';
  END IF;

  v_actor := private.trip_current_actor_json(p_company_id);
  IF v_actor IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3411',
      MESSAGE = 'trip_status_permission_denied';
  END IF;

  SELECT trip_row.status
  INTO v_old_status
  FROM public.trips trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3412',
      MESSAGE = 'trip_not_found';
  END IF;

  IF NOT (
    v_old_status = p_new_status
    OR (
      v_old_status = 'created'::public.trip_status
      AND p_new_status IN (
        'assigned'::public.trip_status,
        'cancelled'::public.trip_status
      )
    )
    OR (
      v_old_status = 'assigned'::public.trip_status
      AND p_new_status IN (
        'loaded'::public.trip_status,
        'cancelled'::public.trip_status
      )
    )
    OR (
      v_old_status = 'loaded'::public.trip_status
      AND p_new_status IN (
        'on_road'::public.trip_status,
        'cancelled'::public.trip_status
      )
    )
    OR (
      v_old_status = 'on_road'::public.trip_status
      AND p_new_status IN (
        'arrived'::public.trip_status,
        'cancelled'::public.trip_status
      )
    )
    OR (
      v_old_status = 'arrived'::public.trip_status
      AND p_new_status IN (
        'delivered'::public.trip_status,
        'cancelled'::public.trip_status
      )
    )
    OR (
      v_old_status = 'delivered'::public.trip_status
      AND p_new_status = 'documents_received'::public.trip_status
    )
    OR (
      v_old_status = 'documents_received'::public.trip_status
      AND p_new_status = 'invoiced'::public.trip_status
    )
    OR (
      v_old_status = 'invoiced'::public.trip_status
      AND p_new_status = 'paid'::public.trip_status
    )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3426',
      MESSAGE = 'trip_status_transition_invalid';
  END IF;

  v_old_audit := private.trip_audit_values(p_company_id, p_trip_id);

  UPDATE public.trips
  SET
    status = p_new_status,
    updated_by = v_actor_user_id
  WHERE company_id = p_company_id
    AND id = p_trip_id;

  INSERT INTO public.trip_status_history (
    company_id,
    trip_id,
    old_status,
    new_status,
    changed_by,
    changed_by_name,
    changed_by_role,
    notes
  )
  VALUES (
    p_company_id,
    p_trip_id,
    v_old_status,
    p_new_status,
    v_actor_user_id,
    v_actor ->> 'display_name',
    v_actor ->> 'role',
    v_notes
  );

  v_snapshot := private.trip_snapshot_json(p_company_id, p_trip_id);
  v_new_audit := private.trip_audit_values(p_company_id, p_trip_id);

  PERFORM private.write_audit_event(
    p_company_id,
    'trips',
    'trip',
    p_trip_id::text,
    private.trip_entity_display_name(v_snapshot),
    'status_changed',
    'trip_status_changed',
    v_old_audit,
    v_new_audit,
    pg_catalog.jsonb_build_object(
      'old_status', v_old_status::text,
      'new_status', p_new_status::text,
      'notes', v_notes
    )
  );

  RETURN v_snapshot;
END;
$function$;

REVOKE ALL
ON FUNCTION public.update_trip_status_atomic(
  uuid,
  uuid,
  public.trip_status,
  text
)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.update_trip_status_atomic(
  uuid,
  uuid,
  public.trip_status,
  text
)
TO authenticated;

REVOKE INSERT, UPDATE ON TABLE public.trips FROM authenticated;
REVOKE INSERT ON TABLE public.trip_status_history FROM authenticated;

DROP POLICY IF EXISTS business_documents_insert_managers
ON storage.objects;

DROP POLICY IF EXISTS business_documents_delete_managers
ON storage.objects;

DROP POLICY IF EXISTS business_documents_select_trip_documents
ON storage.objects;

DROP POLICY IF EXISTS business_documents_insert_trip_documents
ON storage.objects;

DROP POLICY IF EXISTS business_documents_delete_unregistered_trip_documents
ON storage.objects;

CREATE POLICY business_documents_insert_managers
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'business-documents'
  AND private.trip_document_storage_trip_id(name) IS NULL
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
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin']::public.company_role[]
  )
);

CREATE POLICY business_documents_select_trip_documents
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'business-documents'
  AND private.trip_document_storage_trip_id(name) IS NOT NULL
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
  AND EXISTS (
    SELECT 1
    FROM public.trips trip_row
    WHERE trip_row.company_id = private.business_document_company_id(name)
      AND trip_row.id = private.trip_document_storage_trip_id(name)
  )
);

CREATE POLICY business_documents_insert_trip_documents
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'business-documents'
  AND private.trip_document_storage_trip_id(name) IS NOT NULL
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin', 'operations']::public.company_role[]
  )
  AND EXISTS (
    SELECT 1
    FROM public.trips trip_row
    WHERE trip_row.company_id = private.business_document_company_id(name)
      AND trip_row.id = private.trip_document_storage_trip_id(name)
  )
);

CREATE POLICY business_documents_delete_unregistered_trip_documents
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'business-documents'
  AND private.trip_document_storage_trip_id(name) IS NOT NULL
  AND private.has_company_role(
    private.business_document_company_id(name),
    ARRAY['owner', 'admin', 'operations']::public.company_role[]
  )
  AND EXISTS (
    SELECT 1
    FROM public.trips trip_row
    WHERE trip_row.company_id = private.business_document_company_id(name)
      AND trip_row.id = private.trip_document_storage_trip_id(name)
  )
  AND NOT EXISTS (
    SELECT 1
    FROM public.trip_documents document_row
    WHERE document_row.company_id =
      private.business_document_company_id(name)
      AND document_row.storage_reference = name
  )
);

COMMIT;
