-- #351: close private branding Storage orphan lifecycle by reusing #357 Cron
-- and Vault-authenticated cleanup service. Source-only; do not apply hosted.
BEGIN;

-- Preserve prior role grants and existing logo upload semantics. Only
-- retirement/cleanup state is added; never consume business-document quota.
ALTER TABLE private.company_branding_uploads
  ADD COLUMN retired_at timestamptz,
  ADD COLUMN cleanup_claimed_at timestamptz,
  ADD COLUMN cleaned_at timestamptz,
  ADD COLUMN cleanup_attempts integer NOT NULL DEFAULT 0
    CHECK (cleanup_attempts >= 0),
  ADD COLUMN last_cleanup_error_code text;

-- Existing retired assets start their grace period at rollout, not before
-- the operator approved this lifecycle. Never remove them in a migration.
UPDATE private.company_branding_uploads
SET retired_at = pg_catalog.now()
WHERE state = 'retired' AND retired_at IS NULL;

ALTER TABLE private.company_branding_uploads
  DROP CONSTRAINT company_branding_uploads_state_check,
  ADD CONSTRAINT company_branding_uploads_state_check
    CHECK (state IN (
      'reserved','active','retired','released','cleanup_pending','cleaned'
    )),
  ADD CONSTRAINT company_branding_retired_at_check
    CHECK (state <> 'retired' OR retired_at IS NOT NULL),
  ADD CONSTRAINT company_branding_cleanup_claim_check
    CHECK (state <> 'cleanup_pending' OR cleanup_claimed_at IS NOT NULL),
  ADD CONSTRAINT company_branding_cleanup_complete_check
    CHECK (state <> 'cleaned' OR cleaned_at IS NOT NULL);

CREATE FUNCTION private.company_branding_timestamp_retirement()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER
SET search_path = pg_catalog
AS $$
BEGIN
  IF NEW.state = 'retired' AND OLD.state IS DISTINCT FROM NEW.state THEN
    NEW.retired_at := pg_catalog.now();
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION private.company_branding_timestamp_retirement()
  FROM PUBLIC, anon, authenticated;
CREATE TRIGGER company_branding_timestamp_retirement
  BEFORE UPDATE OF state ON private.company_branding_uploads
  FOR EACH ROW EXECUTE FUNCTION private.company_branding_timestamp_retirement();

-- Keep the grace and lease rules identical to the approved #357 scheduler.
-- The state/expiry predicates are indexed, not a full scan of every tenant.
CREATE INDEX company_branding_cleanup_reserved_due
  ON private.company_branding_uploads(expires_at)
  WHERE state = 'reserved';
CREATE INDEX company_branding_cleanup_retired_due
  ON private.company_branding_uploads(retired_at)
  WHERE state = 'retired';
CREATE INDEX company_branding_cleanup_retry_due
  ON private.company_branding_uploads(cleanup_claimed_at)
  WHERE state = 'cleanup_pending';

CREATE FUNCTION private.company_branding_cleanup_has_work()
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = pg_catalog
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM private.company_branding_uploads AS r
    WHERE (
      (r.state = 'reserved' AND r.expires_at <
        pg_catalog.now() - private.business_document_cleanup_grace())
      OR (r.state = 'retired' AND r.retired_at <
        pg_catalog.now() - private.business_document_cleanup_grace())
      OR (r.state = 'cleanup_pending' AND r.cleanup_claimed_at <
        pg_catalog.now() - private.business_document_lease_interval())
    )
    AND private.company_branding_company_id(r.storage_path) = r.company_id
    AND NOT private.company_branding_logo_is_referenced(r.storage_path)
  );
$$;
REVOKE ALL ON FUNCTION private.company_branding_cleanup_has_work()
  FROM PUBLIC, anon, authenticated;

-- The existing #357 cron command stays unchanged, including its identity,
-- UTC schedule, Vault token and endpoint. It now wakes for either backlog.
CREATE OR REPLACE FUNCTION private.business_document_cleanup_has_work()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog
AS $has_work$
  SELECT EXISTS (
    SELECT 1
    FROM private.business_document_upload_reservations AS r
    WHERE (
      (r.state = 'reserved'
        AND r.expires_at <
          pg_catalog.now() - private.business_document_cleanup_grace())
      OR (r.state = 'released'
        AND r.released_at <
          pg_catalog.now() - private.business_document_cleanup_grace())
      OR (r.state = 'expired'
        AND r.expires_at <
          pg_catalog.now() - private.business_document_cleanup_grace())
      OR (r.state = 'cleanup_pending'
        AND r.cleanup_claimed_at <
          pg_catalog.now() - private.business_document_lease_interval())
    )
    AND private.business_document_object_unreferenced(
      r.bucket_id, r.storage_reference
    )
  ) OR private.company_branding_cleanup_has_work();
$has_work$;

-- Only the privileged cleanup worker can claim. READ access to the private
-- reservation ledger is NOT granted to the app or an authenticated user.
CREATE FUNCTION public.claim_company_branding_cleanup(
  p_batch_limit integer DEFAULT 25
)
RETURNS TABLE (
  company_id uuid,
  operation_id uuid,
  bucket_id text,
  storage_reference text
)
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = pg_catalog
AS $$
BEGIN
  IF p_batch_limit IS NULL OR p_batch_limit NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION USING ERRCODE = 'P3514',
      MESSAGE = 'company_branding_cleanup_invalid_batch';
  END IF;

  RETURN QUERY
  WITH eligible AS (
    SELECT r.company_id, r.operation_id
    FROM private.company_branding_uploads AS r
    WHERE (
      (r.state = 'reserved' AND r.expires_at <
        pg_catalog.now() - private.business_document_cleanup_grace())
      OR (r.state = 'retired' AND r.retired_at <
        pg_catalog.now() - private.business_document_cleanup_grace())
      OR (r.state = 'cleanup_pending' AND r.cleanup_claimed_at <
        pg_catalog.now() - private.business_document_lease_interval())
    )
    AND private.company_branding_company_id(r.storage_path) = r.company_id
    AND NOT private.company_branding_logo_is_referenced(r.storage_path)
    ORDER BY r.reserved_at, r.operation_id
    LIMIT p_batch_limit
    FOR UPDATE SKIP LOCKED
  )
  UPDATE private.company_branding_uploads AS r
  SET state = 'cleanup_pending',
      cleanup_claimed_at = pg_catalog.now(),
      cleanup_attempts = r.cleanup_attempts + 1,
      last_cleanup_error_code = NULL
  FROM eligible AS e
  WHERE r.company_id = e.company_id
    AND r.operation_id = e.operation_id
  RETURNING r.company_id, r.operation_id, 'company-branding'::text,
            r.storage_path;
END;
$$;
REVOKE ALL ON FUNCTION public.claim_company_branding_cleanup(integer)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_company_branding_cleanup(integer)
  TO service_role;

-- A final reference and lease recheck immediately precedes Storage remove().
-- This does not bypass company-role RLS for normal users.
CREATE FUNCTION public.verify_company_branding_cleanup_lease(
  p_company_id uuid, p_operation_id uuid
)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM private.company_branding_uploads r
    WHERE r.company_id = p_company_id
      AND r.operation_id = p_operation_id
      AND r.state = 'cleanup_pending'
      AND r.cleanup_claimed_at IS NOT NULL
      AND private.company_branding_company_id(r.storage_path) = r.company_id
      AND NOT private.company_branding_logo_is_referenced(r.storage_path)
  );
$$;
REVOKE ALL ON FUNCTION public.verify_company_branding_cleanup_lease(uuid,uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_company_branding_cleanup_lease(uuid,uuid)
  TO service_role;

-- A temporary Storage failure is durable operational evidence; never mark an
-- unverified deletion as cleaned. Retry is leased by the existing #357 tick.
CREATE FUNCTION public.defer_company_branding_cleanup(
  p_company_id uuid, p_operation_id uuid, p_error_code text
)
RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
  IF p_error_code NOT IN (
    'preflight_failed','storage_remove_failed','cleanup_complete_failed'
  ) OR p_error_code IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P3514',
      MESSAGE = 'company_branding_cleanup_invalid_error_code';
  END IF;
  UPDATE private.company_branding_uploads r
  SET last_cleanup_error_code = p_error_code
  WHERE r.company_id = p_company_id AND r.operation_id = p_operation_id
    AND r.state = 'cleanup_pending';
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P3514',
      MESSAGE = 'company_branding_cleanup_claim_required';
  END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.defer_company_branding_cleanup(uuid,uuid,text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.defer_company_branding_cleanup(uuid,uuid,text)
  TO service_role;

-- Idempotent retries are safe: the finalizer checks the Storage metadata is
-- gone and that neither an active company nor a historical invoice refers
-- to the immutable object before closing its tracked lifetime.
CREATE FUNCTION public.complete_company_branding_cleanup(
  p_company_id uuid, p_operation_id uuid
)
RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_record private.company_branding_uploads%ROWTYPE;
BEGIN
  SELECT * INTO v_record
  FROM private.company_branding_uploads AS r
  WHERE r.company_id = p_company_id AND r.operation_id = p_operation_id
  FOR UPDATE;

  IF NOT FOUND OR v_record.state <> 'cleanup_pending'
    OR private.company_branding_company_id(v_record.storage_path)
       IS DISTINCT FROM v_record.company_id
    OR private.company_branding_logo_is_referenced(v_record.storage_path)
    OR EXISTS (
      SELECT 1 FROM storage.objects AS o
      WHERE o.bucket_id = 'company-branding'
        AND o.name = v_record.storage_path
    )
  THEN
    RAISE EXCEPTION USING ERRCODE = 'P3514',
      MESSAGE = 'company_branding_cleanup_not_complete';
  END IF;

  UPDATE private.company_branding_uploads AS r
  SET state = 'cleaned', cleaned_at = pg_catalog.now(),
      last_cleanup_error_code = NULL
  WHERE r.company_id = p_company_id AND r.operation_id = p_operation_id;
END;
$$;
REVOKE ALL ON FUNCTION public.complete_company_branding_cleanup(uuid,uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_company_branding_cleanup(uuid,uuid)
  TO service_role;

COMMENT ON COLUMN private.company_branding_uploads.cleanup_attempts
  IS 'Company-scoped, retry-safe cleanup attempt count. Operational audit evidence; no application access.';
COMMENT ON COLUMN private.company_branding_uploads.last_cleanup_error_code
  IS 'Structured non-sensitive cleanup outcome, never a raw Storage response.';
COMMENT ON COLUMN private.company_branding_uploads.cleaned_at
  IS 'Storage API deletion verified and object unreferenced at cleanup completion.';

COMMIT;
