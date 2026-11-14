-- H.O.R.U.S #357 — protected document commit, restore and object retention.
-- Requires the preceding #357 reservation migration. Hosted rollout needs
-- separate owner approval; deploy only alongside compatible Flutter clients.
BEGIN;

-- Common metadata boundary: the INSERT/UPDATE must consume the exact actor-
-- owned, unexpired reservation and prove that the uploaded object exists.
-- Both transitions are in the metadata transaction; PostgreSQL rolls the
-- reservation back if the owning feature's audit/metadata mutation fails.
CREATE FUNCTION private.consume_business_document_reservation(
  p_company_id uuid,
  p_bucket_id text,
  p_storage_reference text,
  p_expected_replacement text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE
  v_record private.business_document_upload_reservations%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR p_company_id IS NULL
     OR p_storage_reference IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2873',
      MESSAGE='document_upload_reservation_required';
  END IF;

  -- The pending slot is already counted; its transition to live metadata
  -- occurs atomically without locking the company row again.
  -- Avoid lock inversion with feature RPCs that first lock Trip/Fleet rows.
  SELECT r.* INTO v_record
  FROM private.business_document_upload_reservations r
  WHERE r.company_id=p_company_id
    AND r.bucket_id=p_bucket_id
    AND r.storage_reference=p_storage_reference
    AND r.actor_user_id=auth.uid()
    AND r.state='reserved'
    AND r.expires_at>pg_catalog.now()
  FOR UPDATE;

  IF NOT FOUND OR v_record.replaces_reference
      IS DISTINCT FROM p_expected_replacement
     OR NOT private.business_document_upload_target_allowed(
       p_company_id,p_bucket_id,p_storage_reference)
     OR NOT EXISTS (
       SELECT 1 FROM storage.objects o
       WHERE o.bucket_id=p_bucket_id
         AND o.name=p_storage_reference
     ) THEN
    RAISE EXCEPTION USING ERRCODE='P2873',
      MESSAGE='document_upload_reservation_required';
  END IF;

  UPDATE private.business_document_upload_reservations r
  SET state='committed', committed_at=pg_catalog.now()
  WHERE r.company_id=p_company_id AND r.operation_id=v_record.operation_id;
END;
$$;

CREATE FUNCTION private.guard_trip_document_quota_commit()
RETURNS trigger
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE v_old_reference text;
BEGIN
  IF private.trip_document_storage_trip_id(NEW.storage_reference)
       IS DISTINCT FROM NEW.trip_id
     OR private.trip_document_storage_kind(NEW.storage_reference)
       IS DISTINCT FROM NEW.document_kind THEN
    RAISE EXCEPTION USING ERRCODE='P2873',
      MESSAGE='document_upload_reservation_required';
  END IF;
  IF NEW.replaces_document_id IS NOT NULL THEN
    SELECT d.storage_reference INTO v_old_reference
    FROM public.trip_documents d
    WHERE d.company_id=NEW.company_id
      AND d.trip_id=NEW.trip_id AND d.id=NEW.replaces_document_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE='P2873',
        MESSAGE='document_upload_reservation_required';
    END IF;
  END IF;
  PERFORM private.consume_business_document_reservation(
    NEW.company_id,'business-documents',
    NEW.storage_reference,v_old_reference);
  RETURN NEW;
END;
$$;

CREATE TRIGGER trip_documents_00_quota_commit
  BEFORE INSERT ON public.trip_documents
  FOR EACH ROW EXECUTE FUNCTION private.guard_trip_document_quota_commit();

CREATE FUNCTION private.guard_fleet_document_quota_commit()
RETURNS trigger
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE v_old_reference text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.fleet_license_documents d
    WHERE d.company_id=NEW.company_id
      AND d.id=NEW.license_document_id
      AND (
        (d.tractor_head_id IS NOT NULL
          AND d.tractor_head_id=private.fleet_license_document_storage_asset_id(NEW.storage_reference)
          AND private.fleet_license_document_storage_asset_type(NEW.storage_reference)='tractor_head')
        OR (d.trailer_id IS NOT NULL
          AND d.trailer_id=private.fleet_license_document_storage_asset_id(NEW.storage_reference)
          AND private.fleet_license_document_storage_asset_type(NEW.storage_reference)='trailer')
      )
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2873',
      MESSAGE='document_upload_reservation_required';
  END IF;
  IF NEW.replaces_file_id IS NOT NULL THEN
    SELECT f.storage_reference INTO v_old_reference
    FROM public.fleet_license_document_files f
    WHERE f.company_id=NEW.company_id
      AND f.license_document_id=NEW.license_document_id
      AND f.id=NEW.replaces_file_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE='P2873',
        MESSAGE='document_upload_reservation_required';
    END IF;
  END IF;
  PERFORM private.consume_business_document_reservation(
    NEW.company_id,'business-documents',
    NEW.storage_reference,v_old_reference);
  RETURN NEW;
END;
$$;

CREATE TRIGGER fleet_license_document_files_00_quota_commit
  BEFORE INSERT ON public.fleet_license_document_files
  FOR EACH ROW EXECUTE FUNCTION private.guard_fleet_document_quota_commit();

-- Driver image paths are part of the record's identity: an upload reserved
-- for Driver A or a licence-front cannot be attached to Driver B or an ID
-- field, even when both records belong to the same company.
CREATE FUNCTION private.consume_driver_identity_reservation(
  p_company_id uuid, p_driver_id uuid, p_folder text,
  p_reference text, p_old_reference text
)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $driver_identity_guard$
BEGIN
  IF p_reference IS NULL OR p_driver_id IS NULL
     OR private.driver_document_company_id(p_reference)
       IS DISTINCT FROM p_company_id
     OR private.business_document_upload_kind('driver-documents',p_reference)
       IS DISTINCT FROM 'driver_identity'
     OR pg_catalog.split_part(p_reference,'/',4)
       IS DISTINCT FROM p_driver_id::text
     OR pg_catalog.split_part(p_reference,'/',5)
       IS DISTINCT FROM p_folder THEN
    RAISE EXCEPTION USING ERRCODE='P2873',
      MESSAGE='document_upload_reservation_required';
  END IF;
  PERFORM private.consume_business_document_reservation(
    p_company_id,'driver-documents',p_reference,p_old_reference);
END;
$driver_identity_guard$;

CREATE FUNCTION private.guard_driver_identity_quota_commit()
RETURNS trigger
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
BEGIN
  -- Do not dereference OLD in INSERT triggers; old paths exist only on UPDATE.
  IF TG_OP = 'INSERT' THEN
    IF NEW.license_image_path IS NOT NULL THEN
      PERFORM private.consume_driver_identity_reservation(
        NEW.company_id,NEW.id,'license-front',NEW.license_image_path,NULL);
    END IF;
    IF NEW.license_back_image_path IS NOT NULL THEN
      PERFORM private.consume_driver_identity_reservation(
        NEW.company_id,NEW.id,'license-back',NEW.license_back_image_path,NULL);
    END IF;
    IF NEW.national_id_image_path IS NOT NULL THEN
      PERFORM private.consume_driver_identity_reservation(
        NEW.company_id,NEW.id,'national-id-front',NEW.national_id_image_path,NULL);
    END IF;
    IF NEW.national_id_back_image_path IS NOT NULL THEN
      PERFORM private.consume_driver_identity_reservation(
        NEW.company_id,NEW.id,'national-id-back',NEW.national_id_back_image_path,NULL);
    END IF;
  ELSE
    IF NEW.license_image_path IS DISTINCT FROM OLD.license_image_path
       AND NEW.license_image_path IS NOT NULL THEN
      PERFORM private.consume_driver_identity_reservation(
        NEW.company_id,NEW.id,'license-front',NEW.license_image_path,
        OLD.license_image_path);
    END IF;
    IF NEW.license_back_image_path IS DISTINCT FROM OLD.license_back_image_path
       AND NEW.license_back_image_path IS NOT NULL THEN
      PERFORM private.consume_driver_identity_reservation(
        NEW.company_id,NEW.id,'license-back',NEW.license_back_image_path,
        OLD.license_back_image_path);
    END IF;
    IF NEW.national_id_image_path IS DISTINCT FROM OLD.national_id_image_path
       AND NEW.national_id_image_path IS NOT NULL THEN
      PERFORM private.consume_driver_identity_reservation(
        NEW.company_id,NEW.id,'national-id-front',NEW.national_id_image_path,
        OLD.national_id_image_path);
    END IF;
    IF NEW.national_id_back_image_path IS DISTINCT FROM OLD.national_id_back_image_path
       AND NEW.national_id_back_image_path IS NOT NULL THEN
      PERFORM private.consume_driver_identity_reservation(
        NEW.company_id,NEW.id,'national-id-back',NEW.national_id_back_image_path,
        OLD.national_id_back_image_path);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER drivers_00_document_quota_commit
  BEFORE INSERT OR UPDATE OF
    license_image_path,license_back_image_path,
    national_id_image_path,national_id_back_image_path
  ON public.drivers
  FOR EACH ROW EXECUTE FUNCTION private.guard_driver_identity_quota_commit();

CREATE FUNCTION private.guard_driver_contract_quota_commit()
RETURNS trigger
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.contract_document_reference IS NOT NULL THEN
      PERFORM private.consume_business_document_reservation(
        NEW.company_id,'business-documents',NEW.contract_document_reference,NULL);
    END IF;
  ELSIF NEW.contract_document_reference IS DISTINCT FROM OLD.contract_document_reference
      AND NEW.contract_document_reference IS NOT NULL THEN
    -- Existing immutable compensation contracts cannot be replaced.
    PERFORM private.consume_business_document_reservation(
      NEW.company_id,'business-documents',NEW.contract_document_reference,NULL);
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER driver_compensation_revisions_00_document_quota_commit
  BEFORE INSERT OR UPDATE OF contract_document_reference
  ON public.driver_compensation_revisions
  FOR EACH ROW EXECUTE FUNCTION private.guard_driver_contract_quota_commit();

-- Historic removals remain readable/retained. A future restore RPC (or trusted
-- administrative restore) must acquire fresh capacity before reactivating.
CREATE FUNCTION private.guard_business_document_restore()
RETURNS trigger
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE v_additional integer := 0;
BEGIN
  IF OLD.removed_at IS NOT NULL AND NEW.removed_at IS NULL THEN
    IF TG_TABLE_NAME='trip_documents' THEN
      v_additional := 1;
    ELSIF TG_TABLE_NAME='fleet_license_documents' THEN
      SELECT count(*)::integer INTO v_additional
      FROM public.fleet_license_document_files f
      WHERE f.company_id=NEW.company_id
        AND f.license_document_id=NEW.id AND f.removed_at IS NULL;
    ELSIF TG_TABLE_NAME='fleet_license_document_files' THEN
      IF EXISTS (
        SELECT 1 FROM public.fleet_license_documents d
        WHERE d.company_id=NEW.company_id
          AND d.id=NEW.license_document_id AND d.removed_at IS NULL
      ) THEN v_additional := 1; END IF;
    END IF;
    IF v_additional>0 THEN
      PERFORM private.assert_company_quota_capacity(
        NEW.company_id,'business_documents',v_additional);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trip_documents_00_quota_restore
  BEFORE UPDATE OF removed_at ON public.trip_documents
  FOR EACH ROW EXECUTE FUNCTION private.guard_business_document_restore();

CREATE TRIGGER fleet_license_documents_00_quota_restore
  BEFORE UPDATE OF removed_at ON public.fleet_license_documents
  FOR EACH ROW EXECUTE FUNCTION private.guard_business_document_restore();

CREATE TRIGGER fleet_license_document_files_00_quota_restore
  BEFORE UPDATE OF removed_at ON public.fleet_license_document_files
  FOR EACH ROW EXECUTE FUNCTION private.guard_business_document_restore();

-- RLS DELETE guard applies to every authenticated Storage delete, including
-- previously broad manager policies. A historic or currently referenced file
-- must NEVER be removable through a direct Storage REST call.
CREATE FUNCTION private.business_document_object_unreferenced(
  p_bucket_id text, p_path text
)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
  SELECT
    NOT EXISTS (
      SELECT 1 FROM public.trip_documents d
      WHERE p_bucket_id='business-documents' AND d.storage_reference=p_path
    ) AND NOT EXISTS (
      SELECT 1 FROM public.fleet_license_document_files f
      WHERE p_bucket_id='business-documents' AND f.storage_reference=p_path
    ) AND NOT EXISTS (
      SELECT 1 FROM public.driver_compensation_revisions r
      WHERE p_bucket_id='business-documents'
        AND r.contract_document_reference=p_path
    ) AND NOT EXISTS (
      SELECT 1 FROM public.drivers d
      WHERE p_bucket_id='driver-documents'
        AND p_path IN (
          d.profile_image_path,d.license_image_path,d.license_back_image_path,
          d.national_id_image_path,d.national_id_back_image_path)
    );
$$;

REVOKE ALL ON FUNCTION private.business_document_object_unreferenced(text,text)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.business_document_object_unreferenced(text,text)
  TO authenticated;

CREATE POLICY business_documents_referenced_object_delete_guard
  ON storage.objects AS RESTRICTIVE FOR DELETE TO authenticated
  USING (
    bucket_id NOT IN ('business-documents','driver-documents')
    OR private.business_document_object_unreferenced(bucket_id,name)
  );

-- A cleanup worker must use the protected service-role-only API and Storage
-- remove(); deleting rows from storage.objects in SQL would leak bytes.
-- Grace ensures an upload/metadata network timeout cannot race a sweeper.
CREATE FUNCTION private.business_document_cleanup_grace()
RETURNS interval
LANGUAGE sql IMMUTABLE SECURITY INVOKER SET search_path=pg_catalog
AS $$ SELECT interval '10 minutes' $$;
REVOKE ALL ON FUNCTION private.business_document_cleanup_grace()
  FROM PUBLIC,anon,authenticated;

CREATE FUNCTION public.claim_business_document_cleanup(p_batch_limit integer DEFAULT 25)
RETURNS TABLE (
  company_id uuid,
  operation_id uuid,
  bucket_id text,
  storage_reference text
)
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
BEGIN
  IF p_batch_limit IS NULL OR p_batch_limit NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION USING ERRCODE='P2871',
      MESSAGE='document_cleanup_invalid_batch';
  END IF;
  RETURN QUERY
  WITH available AS (
    SELECT r.company_id,r.operation_id
    FROM private.business_document_upload_reservations r
    WHERE (
      (r.state='reserved'
        AND r.expires_at <
          pg_catalog.now()-private.business_document_cleanup_grace())
      OR (r.state='released'
        AND r.released_at <
          pg_catalog.now()-private.business_document_cleanup_grace())
      OR (r.state='expired'
        AND r.expires_at <
          pg_catalog.now()-private.business_document_cleanup_grace())
      OR (r.state='cleanup_pending'
        AND r.cleanup_claimed_at <
          pg_catalog.now()-private.business_document_lease_interval())
    )
    AND private.business_document_object_unreferenced(
      r.bucket_id,r.storage_reference)
    ORDER BY r.created_at
    LIMIT p_batch_limit
    FOR UPDATE SKIP LOCKED
  )
  UPDATE private.business_document_upload_reservations r
  SET state='cleanup_pending',cleanup_claimed_at=pg_catalog.now()
  FROM available a
  WHERE r.company_id=a.company_id AND r.operation_id=a.operation_id
  RETURNING r.company_id,r.operation_id,r.bucket_id,r.storage_reference;
END;
$$;

CREATE FUNCTION public.complete_business_document_cleanup(
  p_company_id uuid,
  p_operation_id uuid
)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE v_record private.business_document_upload_reservations%ROWTYPE;
BEGIN
  SELECT * INTO v_record
  FROM private.business_document_upload_reservations r
  WHERE r.company_id=p_company_id AND r.operation_id=p_operation_id
  FOR UPDATE;
  IF NOT FOUND OR v_record.state<>'cleanup_pending' THEN
    RAISE EXCEPTION USING ERRCODE='P2874',
      MESSAGE='document_cleanup_claim_required';
  END IF;
  IF NOT private.business_document_object_unreferenced(
       v_record.bucket_id,v_record.storage_reference)
     OR EXISTS (
       SELECT 1 FROM storage.objects o
       WHERE o.bucket_id=v_record.bucket_id
         AND o.name=v_record.storage_reference
     ) THEN
    RAISE EXCEPTION USING ERRCODE='P2874',
      MESSAGE='document_cleanup_not_complete';
  END IF;
  UPDATE private.business_document_upload_reservations r
  SET state='cleaned'
  WHERE r.company_id=p_company_id AND r.operation_id=p_operation_id;
END;
$$;

REVOKE ALL ON FUNCTION private.consume_business_document_reservation(uuid,text,text,text)
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.consume_driver_identity_reservation(uuid,uuid,text,text,text)
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.guard_trip_document_quota_commit()
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.guard_fleet_document_quota_commit()
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.guard_driver_identity_quota_commit()
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.guard_driver_contract_quota_commit()
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.guard_business_document_restore()
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.claim_business_document_cleanup(integer)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.claim_business_document_cleanup(integer)
  TO service_role;
REVOKE ALL ON FUNCTION public.complete_business_document_cleanup(uuid,uuid)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.complete_business_document_cleanup(uuid,uuid)
  TO service_role;


-- Enable strict Storage writes only after all metadata guards are installed.
-- Restrictive gate is ANDed with existing scope/role INSERT policies. This
-- does not accidentally OR a broad reservation permission into Storage RLS.
CREATE POLICY business_document_reservation_insert_gate
  ON storage.objects AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id NOT IN ('business-documents','driver-documents')
    OR private.business_document_upload_is_reserved(bucket_id,name)
    OR (bucket_id='driver-documents'
        AND private.business_document_upload_kind(bucket_id,name)='profile')
  );

-- Never permit in-place overwrite of signed business evidence or ID images.
-- The Flutter uploader must use unique immutable object keys (upsert:false).
CREATE POLICY business_document_no_overwrite_gate
  ON storage.objects AS RESTRICTIVE FOR UPDATE TO authenticated
  USING (bucket_id NOT IN ('business-documents','driver-documents'))
  WITH CHECK (bucket_id NOT IN ('business-documents','driver-documents'));

COMMIT;
