-- Issue #351 PR A: audited company profile and logo selection commands.
-- Depends on the #351 immutable invoice and private branding migrations.
BEGIN;

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
  v_name text := NULLIF(pg_catalog.btrim(p_name), '');
  v_business_type text := NULLIF(pg_catalog.btrim(p_business_type), '');
  v_phone text := NULLIF(pg_catalog.btrim(p_phone), '');
  v_email text := NULLIF(pg_catalog.btrim(p_email), '');
  v_country text := NULLIF(pg_catalog.btrim(p_country), '');
  v_city text := NULLIF(pg_catalog.btrim(p_city), '');
  v_address text := NULLIF(pg_catalog.btrim(p_address), '');
  v_tax text := NULLIF(pg_catalog.btrim(p_tax_registration_number), '');
BEGIN
  IF v_actor IS NULL OR NOT private.has_company_role(
    p_company_id, ARRAY['owner','admin']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3510',
      MESSAGE = 'company_branding_permission_denied';
  END IF;
  IF v_name IS NULL OR pg_catalog.length(v_name) > 200
    OR pg_catalog.length(COALESCE(v_business_type, '')) > 120
    OR pg_catalog.length(COALESCE(v_phone, '')) > 80
    OR pg_catalog.length(COALESCE(v_email, '')) > 254
    OR pg_catalog.length(COALESCE(v_country, '')) > 120
    OR pg_catalog.length(COALESCE(v_city, '')) > 120
    OR pg_catalog.length(COALESCE(v_address, '')) > 500
    OR pg_catalog.length(COALESCE(v_tax, '')) > 120
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
