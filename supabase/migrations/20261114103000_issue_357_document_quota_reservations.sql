-- H.O.R.U.S #357 — DB-owned business-document quota reservations.
-- Versioned migration draft. DO NOT apply to hosted Development/Production
-- without the separate migration approval and staged client compatibility gate.
BEGIN;

CREATE TABLE private.business_document_upload_reservations (
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  operation_id uuid NOT NULL,
  actor_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bucket_id text NOT NULL CHECK (bucket_id IN ('business-documents', 'driver-documents')),
  storage_reference text NOT NULL,
  replaces_reference text,
  state text NOT NULL DEFAULT 'reserved'
    CHECK (state IN ('reserved', 'committed', 'released', 'expired', 'cleanup_pending', 'cleaned')),
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  expires_at timestamptz NOT NULL,
  committed_at timestamptz,
  released_at timestamptz,
  cleanup_claimed_at timestamptz,
  CONSTRAINT business_document_reservation_pk PRIMARY KEY (company_id, operation_id),
  CONSTRAINT business_document_reservation_object_unique UNIQUE (bucket_id, storage_reference),
  CONSTRAINT business_document_reservation_expiry_check CHECK (expires_at > created_at),
  CONSTRAINT business_document_reservation_committed_check CHECK
    (state <> 'committed' OR committed_at IS NOT NULL)
);

CREATE INDEX business_document_reservations_pending_idx
  ON private.business_document_upload_reservations(company_id, expires_at)
  WHERE state = 'reserved';

CREATE UNIQUE INDEX business_document_reservations_one_live_replacement
  ON private.business_document_upload_reservations(company_id, replaces_reference)
  WHERE state = 'reserved' AND replaces_reference IS NOT NULL;

ALTER TABLE private.business_document_upload_reservations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.business_document_upload_reservations FROM PUBLIC, anon, authenticated;
GRANT ALL ON TABLE private.business_document_upload_reservations TO service_role;

CREATE FUNCTION private.business_document_lease_interval()
RETURNS interval
LANGUAGE sql IMMUTABLE SECURITY INVOKER SET search_path = pg_catalog
AS $$ SELECT interval '30 minutes' $$;
REVOKE ALL ON FUNCTION private.business_document_lease_interval() FROM PUBLIC, anon, authenticated;

CREATE FUNCTION private.company_live_business_documents(p_company_id uuid)
RETURNS bigint
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = pg_catalog
AS $$
  SELECT
    (SELECT count(*) FROM public.trip_documents t
     WHERE t.company_id=p_company_id AND t.removed_at IS NULL)
  + (SELECT count(*) FROM public.fleet_license_document_files f
     JOIN public.fleet_license_documents d
       ON d.company_id=f.company_id AND d.id=f.license_document_id
     WHERE f.company_id=p_company_id
       AND f.removed_at IS NULL AND d.removed_at IS NULL)
  + (SELECT count(*) FROM public.driver_compensation_revisions r
     WHERE r.company_id=p_company_id AND r.contract_document_reference IS NOT NULL)
  + (SELECT coalesce(sum(
      (d.license_image_path IS NOT NULL)::integer
      +(d.license_back_image_path IS NOT NULL)::integer
      +(d.national_id_image_path IS NOT NULL)::integer
      +(d.national_id_back_image_path IS NOT NULL)::integer
    ), 0)::bigint FROM public.drivers d WHERE d.company_id=p_company_id);
$$;
REVOKE ALL ON FUNCTION private.company_live_business_documents(uuid)
  FROM PUBLIC, anon, authenticated;

-- Preserve the existing #356 counters, with the extra document resource.
CREATE OR REPLACE FUNCTION private.company_quota_used(
  p_company_id uuid, p_resource text
)
RETURNS bigint
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = pg_catalog
AS $$
DECLARE v_used bigint;
BEGIN
  IF p_resource = 'company_users' THEN
    SELECT
      (SELECT count(*) FROM public.company_users member
       WHERE member.company_id=p_company_id AND member.is_active=true)
      +
      (SELECT count(*) FROM public.company_invitations invitation
       WHERE invitation.company_id=p_company_id
         AND invitation.status='pending'::public.company_invitation_status
         AND GREATEST(invitation.expires_at,
           COALESCE(invitation.pending_token_expires_at, invitation.expires_at))
           > pg_catalog.now()
         AND NOT EXISTS (
           SELECT 1 FROM public.company_users active_member
           JOIN auth.users account ON account.id=active_member.user_id
           WHERE active_member.company_id=p_company_id
             AND active_member.is_active=true
             AND pg_catalog.lower(pg_catalog.btrim(account.email)) =
               invitation.email_normalized
         ))
      INTO v_used;
  ELSIF p_resource = 'combined_vehicles' THEN
    SELECT
      (SELECT count(*) FROM public.tractor_heads
       WHERE company_id=p_company_id AND is_active=true)
      +
      (SELECT count(*) FROM public.trailers
       WHERE company_id=p_company_id AND is_active=true)
      INTO v_used;
  ELSIF p_resource IN ('customers','drivers','routes') THEN
    IF p_resource='customers' THEN
      SELECT count(*) INTO v_used FROM public.customers
      WHERE company_id=p_company_id AND is_active=true;
    ELSIF p_resource='drivers' THEN
      SELECT count(*) INTO v_used FROM public.drivers
      WHERE company_id=p_company_id AND is_active=true;
    ELSE
      SELECT count(*) INTO v_used FROM public.routes
      WHERE company_id=p_company_id AND is_active=true;
    END IF;
  ELSIF p_resource IN ('lifetime_trips','lifetime_invoices') THEN
    SELECT counter.used INTO v_used
      FROM private.company_lifetime_usage_counters counter
      WHERE counter.company_id=p_company_id AND counter.resource=p_resource;
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE='P2862',
        MESSAGE='quota_lifetime_counter_missing';
    END IF;
  ELSIF p_resource='business_documents' THEN
    v_used := private.company_live_business_documents(p_company_id);
  ELSE
    RAISE EXCEPTION USING ERRCODE='P2862', MESSAGE='quota_unsupported_resource';
  END IF;
  RETURN v_used;
END;
$$;

CREATE OR REPLACE FUNCTION private.assert_company_quota_capacity(
  p_company_id uuid, p_resource text, p_additional integer
)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = pg_catalog
AS $$
DECLARE
  v_entitlement jsonb;
  v_limit_text text;
  v_limit bigint;
  v_used bigint;
BEGIN
  IF p_company_id IS NULL OR p_additional IS NULL OR p_additional <= 0 THEN
    RAISE EXCEPTION USING ERRCODE='P2862', MESSAGE='quota_invalid_request';
  END IF;
  IF p_resource IS NULL OR p_resource NOT IN (
    'company_users','combined_vehicles','customers','drivers','routes',
    'lifetime_trips','lifetime_invoices','business_documents'
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2862', MESSAGE='quota_unsupported_resource';
  END IF;

  -- Same lock as #32/#355/#356: all quota producers must serialize here.
  PERFORM 1 FROM public.companies c WHERE c.id=p_company_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2861', MESSAGE='quota_entitlement_unavailable';
  END IF;
  v_entitlement := private.resolve_company_effective_entitlement(p_company_id);
  IF v_entitlement->>'status' IS DISTINCT FROM 'active' THEN
    RAISE EXCEPTION USING ERRCODE='P2861', MESSAGE='quota_entitlement_unavailable';
  END IF;
  v_limit_text := v_entitlement->'limits'->>p_resource;
  IF v_limit_text IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2862', MESSAGE='quota_policy_invalid';
  END IF;
  IF v_limit_text='unlimited' THEN RETURN; END IF;
  IF v_limit_text !~ '^(0|[1-9][0-9]*)$' THEN
    RAISE EXCEPTION USING ERRCODE='P2862', MESSAGE='quota_policy_invalid';
  END IF;
  v_limit := v_limit_text::bigint;
  v_used := private.company_quota_used(p_company_id,p_resource);
  IF p_resource='business_documents' THEN
    -- Only NEW live slots consume capacity, not replacements.
    SELECT v_used + count(*) INTO v_used
    FROM private.business_document_upload_reservations r
    WHERE r.company_id=p_company_id
      AND r.state='reserved'
      AND r.expires_at>pg_catalog.now()
      AND r.replaces_reference IS NULL;
  END IF;
  IF v_used+p_additional > v_limit THEN
    RAISE EXCEPTION USING ERRCODE='P2860',
      MESSAGE=CASE p_resource
        WHEN 'company_users' THEN 'quota_company_users_reached'
        WHEN 'combined_vehicles' THEN 'quota_combined_vehicles_reached'
        WHEN 'customers' THEN 'quota_customers_reached'
        WHEN 'drivers' THEN 'quota_drivers_reached'
        WHEN 'routes' THEN 'quota_routes_reached'
        WHEN 'lifetime_trips' THEN 'quota_lifetime_trips_reached'
        WHEN 'lifetime_invoices' THEN 'quota_lifetime_invoices_reached'
        WHEN 'business_documents' THEN 'quota_business_documents_reached'
      END;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_company_quota_usage(p_company_id uuid)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE v_entitlement jsonb;
BEGIN
  IF auth.uid() IS NULL OR p_company_id IS NULL
     OR NOT private.has_company_role(p_company_id,
       ARRAY['owner','admin']::public.company_role[]) THEN
    RAISE EXCEPTION USING ERRCODE='P2863', MESSAGE='quota_permission_denied';
  END IF;
  v_entitlement := private.resolve_company_effective_entitlement(p_company_id);
  RETURN pg_catalog.jsonb_build_object(
    'entitlement', v_entitlement,
    'usage', pg_catalog.jsonb_build_object(
      'company_users',private.company_quota_used(p_company_id,'company_users'),
      'combined_vehicles',private.company_quota_used(p_company_id,'combined_vehicles'),
      'customers',private.company_quota_used(p_company_id,'customers'),
      'drivers',private.company_quota_used(p_company_id,'drivers'),
      'routes',private.company_quota_used(p_company_id,'routes'),
      'lifetime_trips',private.company_quota_used(p_company_id,'lifetime_trips'),
      'lifetime_invoices',private.company_quota_used(p_company_id,'lifetime_invoices'),
      'business_documents',private.company_quota_used(p_company_id,'business_documents')
    )
  );
END;
$$;

-- Classify only known, strongly typed paths. Do not turn the bucket into a
-- generic document API or permit arbitrary prefix reservations.
CREATE FUNCTION private.business_document_upload_kind(p_bucket text, p_path text)
RETURNS text LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
BEGIN
  IF p_bucket='business-documents' THEN
    IF private.trip_document_storage_trip_id(p_path) IS NOT NULL THEN
      RETURN 'trip';
    ELSIF private.fleet_license_document_storage_asset_type(p_path) IS NOT NULL THEN
      RETURN 'fleet';
    ELSIF p_path ~
      '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/driver-compensation/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/employment-contract/[0-9a-f]{32}\.(pdf|jpg|jpeg|png|webp|heic|heif)$' THEN
      RETURN 'contract';
    END IF;
  ELSIF p_bucket='driver-documents' THEN
    IF p_path ~
      '^companies/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/drivers/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/(profile|license-front|license-back|national-id-front|national-id-back)/[0-9]+\.(jpg|jpeg|png|webp|heic|heif)$' THEN
      IF pg_catalog.split_part(p_path,'/',5)='profile' THEN
        RETURN 'profile';
      END IF;
      RETURN 'driver_identity';
    END IF;
  END IF;
  RETURN NULL;
END;
$$;

CREATE FUNCTION private.business_document_upload_target_allowed(
  p_company_id uuid, p_bucket text, p_path text
)
RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE
  v_kind text := private.business_document_upload_kind(p_bucket,p_path);
  v_entity_id uuid;
  v_asset_type text;
BEGIN
  IF auth.uid() IS NULL OR p_company_id IS NULL
     OR (CASE p_bucket
       WHEN 'driver-documents' THEN private.driver_document_company_id(p_path)
       ELSE private.business_document_company_id(p_path)
     END) IS DISTINCT FROM p_company_id
     OR v_kind IS NULL THEN
    RETURN false;
  END IF;
  v_entity_id := pg_catalog.split_part(p_path,'/',4)::uuid;

  IF v_kind='trip' THEN
    RETURN private.has_company_role(p_company_id,
       ARRAY['owner','admin','operations']::public.company_role[])
       AND EXISTS (SELECT 1 FROM public.trips t
           WHERE t.company_id=p_company_id AND t.id=v_entity_id);
  ELSIF v_kind='fleet' THEN
    IF NOT private.has_company_role(p_company_id,
       ARRAY['owner','admin','operations']::public.company_role[]) THEN
      RETURN false;
    END IF;
    v_asset_type := private.fleet_license_document_storage_asset_type(p_path);
    IF v_asset_type='tractor_head' THEN
      RETURN EXISTS (SELECT 1 FROM public.tractor_heads t
        WHERE t.company_id=p_company_id AND t.id=v_entity_id);
    ELSIF v_asset_type='trailer' THEN
      RETURN EXISTS (SELECT 1 FROM public.trailers t
        WHERE t.company_id=p_company_id AND t.id=v_entity_id);
    END IF;
    RETURN false;
  ELSIF v_kind='contract' THEN
    RETURN private.has_company_role(p_company_id,
       ARRAY['owner','admin']::public.company_role[])
      AND NOT EXISTS (SELECT 1 FROM public.driver_compensation_revisions r
        WHERE r.id=v_entity_id AND (
          r.company_id<>p_company_id OR r.contract_document_reference IS NOT NULL));
  ELSIF v_kind='driver_identity' THEN
    RETURN private.has_company_role(p_company_id,
       ARRAY['owner','admin','operations']::public.company_role[])
      AND NOT EXISTS (SELECT 1 FROM public.drivers d
        WHERE d.id=v_entity_id AND d.company_id<>p_company_id);
  END IF;
  RETURN false;
END;
$$;

CREATE FUNCTION private.business_document_replacement_allowed(
  p_company_id uuid, p_bucket text, p_new_path text, p_old_path text
)
RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE
  v_kind text := private.business_document_upload_kind(p_bucket,p_new_path);
  v_entity_id uuid;
  v_folder text := pg_catalog.split_part(p_new_path,'/',5);
  v_asset_type text;
BEGIN
  IF p_old_path IS NULL THEN RETURN true; END IF;
  IF v_kind IS NULL THEN RETURN false; END IF;
  v_entity_id := pg_catalog.split_part(p_new_path,'/',4)::uuid;
  IF v_kind='trip' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.trip_documents d
      WHERE d.company_id=p_company_id AND d.trip_id=v_entity_id
        AND d.storage_reference=p_old_path AND d.removed_at IS NULL
        AND d.document_kind=private.trip_document_storage_kind(p_new_path)
    );
  ELSIF v_kind='fleet' THEN
    v_asset_type := private.fleet_license_document_storage_asset_type(p_new_path);
    RETURN EXISTS (
      SELECT 1 FROM public.fleet_license_document_files f
      JOIN public.fleet_license_documents d
        ON d.id=f.license_document_id AND d.company_id=f.company_id
      WHERE f.company_id=p_company_id
        AND f.storage_reference=p_old_path AND f.removed_at IS NULL
        AND d.removed_at IS NULL
        AND (
          (v_asset_type='tractor_head' AND d.tractor_head_id=v_entity_id) OR
          (v_asset_type='trailer' AND d.trailer_id=v_entity_id)
        )
    );
  ELSIF v_kind='driver_identity' THEN
    RETURN EXISTS (
      SELECT 1 FROM public.drivers d
      WHERE d.company_id=p_company_id AND d.id=v_entity_id
        AND CASE v_folder
          WHEN 'license-front' THEN d.license_image_path
          WHEN 'license-back' THEN d.license_back_image_path
          WHEN 'national-id-front' THEN d.national_id_image_path
          WHEN 'national-id-back' THEN d.national_id_back_image_path
        END = p_old_path
    );
  END IF;
  RETURN false;
END;
$$;

-- The stable reservation ID is client-generated; retry with the same ID and
-- payload returns the original lease, never an extra charged slot.
CREATE FUNCTION public.reserve_business_document_upload(
  p_company_id uuid,
  p_operation_id uuid,
  p_bucket_id text,
  p_storage_reference text,
  p_replaces_reference text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_current private.business_document_upload_reservations%ROWTYPE;
  v_now timestamptz := pg_catalog.now();
BEGIN
  IF v_actor IS NULL OR p_operation_id IS NULL OR p_company_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501',
      MESSAGE='document_upload_permission_denied';
  END IF;
  PERFORM 1 FROM public.companies c WHERE c.id=p_company_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2861',
      MESSAGE='quota_entitlement_unavailable';
  END IF;
  SELECT * INTO v_current
  FROM private.business_document_upload_reservations r
  WHERE r.company_id=p_company_id AND r.operation_id=p_operation_id
  FOR UPDATE;
  IF FOUND THEN
    IF v_current.actor_user_id IS DISTINCT FROM v_actor
       OR v_current.bucket_id IS DISTINCT FROM p_bucket_id
       OR v_current.storage_reference IS DISTINCT FROM p_storage_reference
       OR v_current.replaces_reference IS DISTINCT FROM p_replaces_reference THEN
      RAISE EXCEPTION USING ERRCODE='P2872',
        MESSAGE='document_upload_idempotency_conflict';
    END IF;
    IF v_current.state='reserved' AND v_current.expires_at>v_now THEN
      RETURN pg_catalog.jsonb_build_object(
        'operation_id',p_operation_id,'state','reserved',
        'expires_at',v_current.expires_at);
    END IF;
    IF v_current.state='committed' THEN
      RETURN pg_catalog.jsonb_build_object(
        'operation_id',p_operation_id,'state','committed',
        'expires_at',v_current.expires_at);
    END IF;
    RAISE EXCEPTION USING ERRCODE='P2874',
      MESSAGE='document_upload_reservation_expired';
  END IF;

  IF NOT private.business_document_upload_target_allowed(
      p_company_id,p_bucket_id,p_storage_reference)
     OR private.business_document_upload_kind(p_bucket_id,p_storage_reference)='profile'
     OR NOT private.business_document_replacement_allowed(
       p_company_id,p_bucket_id,p_storage_reference,p_replaces_reference)
  THEN
    RAISE EXCEPTION USING ERRCODE='P2871',
      MESSAGE='document_upload_invalid_target';
  END IF;
  -- Never allow an already-existing object to be bound to a new reservation.
  IF EXISTS (SELECT 1 FROM storage.objects o
    WHERE o.bucket_id=p_bucket_id AND o.name=p_storage_reference) THEN
    RAISE EXCEPTION USING ERRCODE='P2872',
      MESSAGE='document_upload_idempotency_conflict';
  END IF;

  UPDATE private.business_document_upload_reservations
     SET state='expired'
   WHERE company_id=p_company_id AND state='reserved' AND expires_at<=v_now;

  IF p_replaces_reference IS NULL THEN
    PERFORM private.assert_company_quota_capacity(
      p_company_id,'business_documents',1);
  ELSIF EXISTS (
    SELECT 1 FROM private.business_document_upload_reservations r
    WHERE r.company_id=p_company_id
      AND r.replaces_reference=p_replaces_reference
      AND r.state='reserved' AND r.expires_at>v_now
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2872',
      MESSAGE='document_upload_replacement_pending';
  END IF;

  INSERT INTO private.business_document_upload_reservations (
    company_id,operation_id,actor_user_id,bucket_id,
    storage_reference,replaces_reference,expires_at
  ) VALUES (
    p_company_id,p_operation_id,v_actor,p_bucket_id,
    p_storage_reference,p_replaces_reference,
    v_now+private.business_document_lease_interval()
  );
  RETURN pg_catalog.jsonb_build_object(
    'operation_id',p_operation_id,'state','reserved',
    'expires_at',v_now+private.business_document_lease_interval());
END;
$$;

CREATE FUNCTION public.release_business_document_upload(
  p_company_id uuid, p_operation_id uuid
)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
BEGIN
  IF auth.uid() IS NULL OR p_company_id IS NULL OR p_operation_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501',
      MESSAGE='document_upload_permission_denied';
  END IF;
  PERFORM 1 FROM public.companies c WHERE c.id=p_company_id FOR UPDATE;
  UPDATE private.business_document_upload_reservations r
    SET state='released', released_at=pg_catalog.now()
  WHERE r.company_id=p_company_id AND r.operation_id=p_operation_id
    AND r.actor_user_id=auth.uid()
    AND r.state='reserved';
  -- Committed reservations are deliberately immutable: a late network failure
  -- must never uncommit a successfully persisted business document.
END;
$$;

CREATE FUNCTION private.business_document_upload_is_reserved(
  p_bucket_id text, p_storage_reference text
)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
  SELECT auth.uid() IS NOT NULL AND EXISTS (
    SELECT 1 FROM private.business_document_upload_reservations r
    WHERE r.bucket_id=p_bucket_id
      AND r.storage_reference=p_storage_reference
      AND r.actor_user_id=auth.uid()
      AND r.state='reserved' AND r.expires_at>pg_catalog.now()
  );
$$;

REVOKE ALL ON FUNCTION private.business_document_upload_kind(text,text)
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.business_document_upload_target_allowed(uuid,text,text)
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.business_document_replacement_allowed(uuid,text,text,text)
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.reserve_business_document_upload(uuid,uuid,text,text,text)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.reserve_business_document_upload(uuid,uuid,text,text,text)
  TO authenticated;
REVOKE ALL ON FUNCTION public.release_business_document_upload(uuid,uuid)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.release_business_document_upload(uuid,uuid)
  TO authenticated;
REVOKE ALL ON FUNCTION private.business_document_upload_is_reserved(text,text)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.business_document_upload_is_reserved(text,text)
  TO authenticated;

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


-- Compensation paths carry no operation ID. Release by exact actor-owned
-- object reference so feature-level error compensation immediately frees a
-- pending slot, without touching a committed reservation.
CREATE FUNCTION public.release_business_document_upload_by_reference(
  p_company_id uuid, p_storage_reference text
)
RETURNS void
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $
BEGIN
  IF auth.uid() IS NULL OR p_company_id IS NULL OR p_storage_reference IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501',
      MESSAGE='document_upload_permission_denied';
  END IF;
  PERFORM 1 FROM public.companies c WHERE c.id=p_company_id FOR UPDATE;
  UPDATE private.business_document_upload_reservations r
    SET state='released',released_at=pg_catalog.now()
  WHERE r.company_id=p_company_id AND r.storage_reference=p_storage_reference
    AND r.actor_user_id=auth.uid() AND r.state='reserved';
END;
$;
REVOKE ALL ON FUNCTION public.release_business_document_upload_by_reference(uuid,text)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.release_business_document_upload_by_reference(uuid,text)
  TO authenticated;

COMMIT;