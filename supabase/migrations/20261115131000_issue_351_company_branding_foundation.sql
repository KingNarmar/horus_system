-- Issue #351 PR A: private company branding, server-owned profile mutations,
-- and a tracked, quota-exempt upload lifecycle. NO hosted application by this file.
BEGIN;

-- The company-branding bucket is deliberately distinct from the 50-slot
-- business document resource and from the existing driver-images bucket.
INSERT INTO storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
VALUES (
  'company-branding', 'company-branding', false, 2097152,
  ARRAY['image/png', 'image/jpeg', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

DO $assert_branding_bucket$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM storage.buckets b
    WHERE b.id = 'company-branding' AND b.name = 'company-branding'
      AND b.public = false AND b.file_size_limit = 2097152
      AND b.allowed_mime_types @> ARRAY[
        'image/png', 'image/jpeg', 'image/webp'
      ]::text[]
  ) THEN
    RAISE EXCEPTION 'Issue #351: incompatible existing branding bucket';
  END IF;
END;
$assert_branding_bucket$;

-- Only canonical per-tenant, per-upload immutable keys are accepted.
-- No public URL, overwrite path, or arbitrary subdirectory is valid.
CREATE FUNCTION private.company_branding_company_id(p_path text)
RETURNS uuid LANGUAGE sql IMMUTABLE SECURITY INVOKER
SET search_path = pg_catalog
AS $$
  SELECT CASE WHEN p_path ~
    '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/logos/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.](png|jpg|jpeg|webp)$'
    THEN pg_catalog.split_part(p_path, '/', 2)::uuid
    ELSE NULL
  END;
$$;
REVOKE ALL ON FUNCTION private.company_branding_company_id(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.company_branding_company_id(text)
  TO authenticated;

-- Reservation rows are private evidence. An interrupted upload remains
-- discoverable for later compensating cleanup; it is never a document quota.
CREATE TABLE private.company_branding_uploads (
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  operation_id uuid NOT NULL,
  storage_path text NOT NULL UNIQUE,
  actor_user_id uuid NOT NULL,
  state text NOT NULL DEFAULT 'reserved'
    CHECK (state IN ('reserved', 'active', 'retired', 'released')),
  reserved_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  expires_at timestamptz NOT NULL,
  committed_at timestamptz,
  PRIMARY KEY (company_id, operation_id),
  CONSTRAINT company_branding_upload_expiry
    CHECK (expires_at > reserved_at),
  CONSTRAINT company_branding_active_has_commit
    CHECK (state NOT IN ('active', 'retired') OR committed_at IS NOT NULL)
);
CREATE INDEX company_branding_uploads_unfinished
  ON private.company_branding_uploads(expires_at)
  WHERE state = 'reserved';
ALTER TABLE private.company_branding_uploads ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.company_branding_uploads
  FROM PUBLIC, anon, authenticated;

CREATE FUNCTION private.company_branding_upload_is_reserved(p_path text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT auth.uid() IS NOT NULL AND EXISTS (
    SELECT 1 FROM private.company_branding_uploads AS request
    WHERE request.storage_path = p_path
      AND request.company_id = private.company_branding_company_id(p_path)
      AND request.actor_user_id = auth.uid()
      AND request.state = 'reserved'
      AND request.expires_at > pg_catalog.now()
  );
$$;
REVOKE ALL ON FUNCTION private.company_branding_upload_is_reserved(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.company_branding_upload_is_reserved(text)
  TO authenticated;

-- Prevent deletion of the currently selected logo AND of a past invoice's
-- immutable issuer logo. Retired assets without references may be cleaned.
CREATE FUNCTION private.company_branding_logo_is_referenced(p_path text)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.companies AS company_row
    WHERE company_row.logo_url = p_path
  ) OR EXISTS (
    SELECT 1 FROM public.invoices AS invoice_row
    WHERE invoice_row.issuer_logo_path = p_path
      AND invoice_row.issued_at IS NOT NULL
  );
$$;
REVOKE ALL ON FUNCTION private.company_branding_logo_is_referenced(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.company_branding_logo_is_referenced(text)
  TO authenticated;

-- Existing #357 policies are permissive, some match 'other' buckets.
-- RESTRICTIVE gates are mandatory: adding only permissive branding policies
-- would silently allow broad cross-tenant access to a newly created bucket.
CREATE POLICY company_branding_read_member
ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id = 'company-branding'
  AND private.has_company_role(
    private.company_branding_company_id(name),
    ARRAY['owner','admin','operations','accountant','viewer']
      ::public.company_role[]
  )
);
CREATE POLICY company_branding_read_boundary
AS RESTRICTIVE ON storage.objects FOR SELECT TO authenticated
USING (
  bucket_id <> 'company-branding'
  OR private.has_company_role(
    private.company_branding_company_id(name),
    ARRAY['owner','admin','operations','accountant','viewer']
      ::public.company_role[]
  )
);

CREATE POLICY company_branding_insert_manager
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'company-branding'
  AND private.has_company_role(
    private.company_branding_company_id(name),
    ARRAY['owner','admin']::public.company_role[]
  )
  AND private.company_branding_upload_is_reserved(name)
);
CREATE POLICY company_branding_insert_boundary
AS RESTRICTIVE ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id <> 'company-branding'
  OR (
    private.has_company_role(
      private.company_branding_company_id(name),
      ARRAY['owner','admin']::public.company_role[]
    )
    AND private.company_branding_upload_is_reserved(name)
  )
);

-- Object immutability: never overwrite a logo used by an issued invoice.
CREATE POLICY company_branding_no_overwrite
AS RESTRICTIVE ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id <> 'company-branding')
WITH CHECK (bucket_id <> 'company-branding');

CREATE POLICY company_branding_delete_unreferenced
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'company-branding'
  AND private.has_company_role(
    private.company_branding_company_id(name),
    ARRAY['owner','admin']::public.company_role[]
  )
  AND NOT private.company_branding_logo_is_referenced(name)
);
CREATE POLICY company_branding_delete_boundary
AS RESTRICTIVE ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id <> 'company-branding'
  OR (
    private.has_company_role(
      private.company_branding_company_id(name),
      ARRAY['owner','admin']::public.company_role[]
    )
    AND NOT private.company_branding_logo_is_referenced(name)
  )
);

-- Stage a specific upload before any Storage bytes are accepted.
CREATE FUNCTION public.reserve_company_branding_upload(
  p_company_id uuid, p_operation_id uuid, p_storage_path text
)
RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_existing private.company_branding_uploads%ROWTYPE;
BEGIN
  IF v_actor IS NULL OR NOT private.has_company_role(
    p_company_id, ARRAY['owner','admin']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3510',
      MESSAGE = 'company_branding_permission_denied';
  END IF;
  IF p_operation_id IS NULL OR p_storage_path IS NULL
    OR private.company_branding_company_id(p_storage_path)
      IS DISTINCT FROM p_company_id
  THEN
    RAISE EXCEPTION USING ERRCODE = 'P3511',
      MESSAGE = 'company_branding_upload_invalid';
  END IF;

  PERFORM 1 FROM public.companies
  WHERE id = p_company_id AND is_active FOR SHARE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P3513',
      MESSAGE = 'company_branding_company_unavailable';
  END IF;

  SELECT * INTO v_existing
  FROM private.company_branding_uploads
  WHERE company_id = p_company_id AND operation_id = p_operation_id
  FOR UPDATE;
  IF FOUND THEN
    IF v_existing.storage_path IS DISTINCT FROM p_storage_path
      OR v_existing.actor_user_id IS DISTINCT FROM v_actor
      OR v_existing.state <> 'reserved'
      OR v_existing.expires_at <= pg_catalog.now()
    THEN
      RAISE EXCEPTION USING ERRCODE = 'P3512',
        MESSAGE = 'company_branding_upload_conflict';
    END IF;
    RETURN; -- Same actor, same payload, same still-valid lease.
  END IF;

  IF EXISTS (
    SELECT 1 FROM storage.objects AS object_row
    WHERE object_row.bucket_id = 'company-branding'
      AND object_row.name = p_storage_path
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3512',
      MESSAGE = 'company_branding_upload_conflict';
  END IF;

  INSERT INTO private.company_branding_uploads(
    company_id, operation_id, storage_path, actor_user_id, expires_at
  )
  VALUES (
    p_company_id, p_operation_id, p_storage_path, v_actor,
    pg_catalog.now() + interval '30 minutes'
  );
END;
$$;
REVOKE ALL ON FUNCTION public.reserve_company_branding_upload(
  uuid, uuid, text
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_company_branding_upload(
  uuid, uuid, text
) TO authenticated;

-- Call only after Storage deletion/compensation when an upload fails.
CREATE FUNCTION public.release_company_branding_upload(
  p_company_id uuid, p_operation_id uuid
)
RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE v_actor uuid := auth.uid();
BEGIN
  IF v_actor IS NULL OR NOT private.has_company_role(
    p_company_id, ARRAY['owner','admin']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3510',
      MESSAGE = 'company_branding_permission_denied';
  END IF;
  UPDATE private.company_branding_uploads
  SET state = 'released'
  WHERE company_id = p_company_id AND operation_id = p_operation_id
    AND actor_user_id = v_actor AND state = 'reserved'
    AND NOT EXISTS (
      SELECT 1 FROM storage.objects object_row
      WHERE object_row.bucket_id = 'company-branding'
        AND object_row.name = storage_path
    );
END;
$$;
REVOKE ALL ON FUNCTION public.release_company_branding_upload(
  uuid, uuid
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.release_company_branding_upload(
  uuid, uuid
) TO authenticated;

-- One RPC owns profile edits. No general UPDATE grant for companies.
CREATE FUNCTION public.update_company_brand_profile(
  p_company_id uuid, p_expected_updated_at timestamptz,
  p_name text, p_business_type text, p_phone text, p_email text,
  p_country text, p_city text, p_address text,
  p_tax_registration_number text
)
RETURNS public.companies LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_before public.companies%ROWTYPE;
  v_after public.companies%ROWTYPE;
  v_name text := pg_catalog.nullif(pg_catalog.btrim(p_name), '');
  v_business_type text := pg_catalog.nullif(pg_catalog.btrim(p_business_type), '');
  v_phone text := pg_catalog.nullif(pg_catalog.btrim(p_phone), '');
  v_email text := pg_catalog.nullif(pg_catalog.btrim(p_email), '');
  v_country text := pg_catalog.nullif(pg_catalog.btrim(p_country), '');
  v_city text := pg_catalog.nullif(pg_catalog.btrim(p_city), '');
  v_address text := pg_catalog.nullif(pg_catalog.btrim(p_address), '');
  v_tax text := pg_catalog.nullif(pg_catalog.btrim(p_tax_registration_number), '');
BEGIN
  IF v_actor IS NULL OR NOT private.has_company_role(
    p_company_id, ARRAY['owner','admin']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3510',
      MESSAGE = 'company_branding_permission_denied';
  END IF;
  IF v_name IS NULL OR pg_catalog.length(v_name) > 200
    OR pg_catalog.length(pg_catalog.coalesce(v_business_type, '')) > 120
    OR pg_catalog.length(pg_catalog.coalesce(v_phone, '')) > 80
    OR pg_catalog.length(pg_catalog.coalesce(v_email, '')) > 254
    OR pg_catalog.length(pg_catalog.coalesce(v_country, '')) > 120
    OR pg_catalog.length(pg_catalog.coalesce(v_city, '')) > 120
    OR pg_catalog.length(pg_catalog.coalesce(v_address, '')) > 500
    OR pg_catalog.length(pg_catalog.coalesce(v_tax, '')) > 120
  THEN
    RAISE EXCEPTION USING ERRCODE = 'P3511',
      MESSAGE = 'company_branding_profile_invalid';
  END IF;

  SELECT * INTO v_before FROM public.companies
  WHERE id = p_company_id AND is_active FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P3513',
      MESSAGE = 'company_branding_company_unavailable';
  END IF;
  IF p_expected_updated_at IS NULL
     OR v_before.updated_at IS DISTINCT FROM p_expected_updated_at
  THEN
    RAISE EXCEPTION USING ERRCODE = 'P3512',
      MESSAGE = 'company_branding_profile_conflict';
  END IF;

  IF ROW(v_before.name, v_before.business_type, v_before.phone,
         v_before.email, v_before.country, v_before.city,
         v_before.address, v_before.tax_registration_number)
     IS NOT DISTINCT FROM
     ROW(v_name, v_business_type, v_phone, v_email, v_country, v_city,
         v_address, v_tax)
  THEN
    RETURN v_before;
  END IF;

  UPDATE public.companies
  SET name = v_name, business_type = v_business_type, phone = v_phone,
      email = v_email, country = v_country, city = v_city,
      address = v_address, tax_registration_number = v_tax,
      updated_by = v_actor
  WHERE id = p_company_id RETURNING * INTO v_after;

  PERFORM private.write_audit_event(
    p_company_id, 'companies', 'company', p_company_id::text,
    v_after.name, 'updated', 'company_brand_profile_updated',
    pg_catalog.jsonb_build_object(
      'name', v_before.name, 'business_type', v_before.business_type,
      'phone', v_before.phone, 'email', v_before.email,
      'country', v_before.country, 'city', v_before.city,
      'address', v_before.address,
      'tax_registration_number', v_before.tax_registration_number
    ),
    pg_catalog.jsonb_build_object(
      'name', v_after.name, 'business_type', v_after.business_type,
      'phone', v_after.phone, 'email', v_after.email,
      'country', v_after.country, 'city', v_after.city,
      'address', v_after.address,
      'tax_registration_number', v_after.tax_registration_number
    )
  );
  RETURN v_after;
END;
$$;
REVOKE ALL ON FUNCTION public.update_company_brand_profile(
  uuid, timestamptz, text, text, text, text, text, text, text, text
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_company_brand_profile(
  uuid, timestamptz, text, text, text, text, text, text, text, text
) TO authenticated;

-- Switching a logo must never overwrite old bytes or delete issued history.
-- No state mutation occurs unless the referenced Storage object exists and
-- belongs to the current authenticated uploader's reserved operation.
CREATE FUNCTION public.set_company_brand_logo(
  p_company_id uuid, p_expected_logo_path text, p_new_logo_path text
)
RETURNS public.companies LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_before public.companies%ROWTYPE;
  v_after public.companies%ROWTYPE;
  v_reservation private.company_branding_uploads%ROWTYPE;
BEGIN
  IF v_actor IS NULL OR NOT private.has_company_role(
    p_company_id, ARRAY['owner','admin']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3510',
      MESSAGE = 'company_branding_permission_denied';
  END IF;
  SELECT * INTO v_before FROM public.companies
  WHERE id = p_company_id AND is_active FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P3513',
      MESSAGE = 'company_branding_company_unavailable';
  END IF;
  IF v_before.logo_url IS DISTINCT FROM p_expected_logo_path THEN
    RAISE EXCEPTION USING ERRCODE = 'P3512',
      MESSAGE = 'company_branding_logo_conflict';
  END IF;
  IF v_before.logo_url IS NOT DISTINCT FROM p_new_logo_path THEN
    RETURN v_before;
  END IF;

  IF p_new_logo_path IS NOT NULL THEN
    IF private.company_branding_company_id(p_new_logo_path)
      IS DISTINCT FROM p_company_id
    THEN
      RAISE EXCEPTION USING ERRCODE = 'P3511',
        MESSAGE = 'company_branding_upload_invalid';
    END IF;
    SELECT * INTO v_reservation
    FROM private.company_branding_uploads AS request
    WHERE request.company_id = p_company_id
      AND request.storage_path = p_new_logo_path
      AND request.actor_user_id = v_actor
      AND request.state = 'reserved'
      AND request.expires_at > pg_catalog.now()
    FOR UPDATE;
    IF NOT FOUND OR NOT EXISTS (
      SELECT 1 FROM storage.objects AS object_row
      WHERE object_row.bucket_id = 'company-branding'
        AND object_row.name = p_new_logo_path
        AND object_row.owner_id = v_actor::text
    ) THEN
      RAISE EXCEPTION USING ERRCODE = 'P3511',
        MESSAGE = 'company_branding_upload_unavailable';
    END IF;
  END IF;

  UPDATE public.companies
  SET logo_url = p_new_logo_path, updated_by = v_actor
  WHERE id = p_company_id RETURNING * INTO v_after;

  IF p_new_logo_path IS NOT NULL THEN
    UPDATE private.company_branding_uploads
    SET state = 'active', committed_at = pg_catalog.now()
    WHERE company_id = p_company_id
      AND storage_path = p_new_logo_path;
  END IF;
  UPDATE private.company_branding_uploads
  SET state = 'retired'
  WHERE company_id = p_company_id
    AND storage_path = v_before.logo_url
    AND state = 'active';

  PERFORM private.write_audit_event(
    p_company_id, 'companies', 'company', p_company_id::text,
    v_after.name, 'updated', 'company_brand_logo_changed',
    pg_catalog.jsonb_build_object('logo_path', v_before.logo_url),
    pg_catalog.jsonb_build_object('logo_path', v_after.logo_url)
  );
  RETURN v_after;
END;
$$;
REVOKE ALL ON FUNCTION public.set_company_brand_logo(
  uuid, text, text
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_company_brand_logo(
  uuid, text, text
) TO authenticated;

-- Keep protected fields unreachable by general company UPDATE grants.
REVOKE INSERT, UPDATE, DELETE ON TABLE public.companies
  FROM anon, authenticated;

COMMENT ON TABLE private.company_branding_uploads
  IS 'Private #351 branding upload ledger; logos are NOT business-document quota slots. Reserved/retired bytes require a Storage API cleanup worker, never direct storage metadata deletion.';

COMMIT;
