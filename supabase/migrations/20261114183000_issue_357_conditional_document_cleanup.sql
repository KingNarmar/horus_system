-- H.O.R.U.S #357 — skip the cleanup HTTP request when there is no work.
-- A 15-minute Cron tick still runs one local, bounded EXISTS query. The
-- Edge Function is called only if the existing cleanup claimant could
-- process at least one unreferenced, expired/released/retryable reservation.
-- Secrets remain in Vault and are never embedded in this migration or job.
-- Local replay without an active environment-bound job is a safe no-op.
BEGIN;

-- Keep the idle existence check proportional to outstanding work, not to
-- permanently retained committed/cleaned history as the SaaS grows.
CREATE INDEX business_document_cleanup_work_state_idx
  ON private.business_document_upload_reservations (state)
  WHERE state IN ('reserved', 'released', 'expired', 'cleanup_pending');

CREATE FUNCTION private.business_document_cleanup_has_work()
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
  );
$has_work$;

-- Called only by the postgres-owned Cron job; not by apps or tenants.
REVOKE ALL ON FUNCTION private.business_document_cleanup_has_work()
  FROM PUBLIC, anon, authenticated;

DO $schedule_only_existing$
BEGIN
  -- No hosted endpoint/secret is available in a disposable migration replay.
  -- Never create a new hosted job implicitly or reactivate a paused job.
  IF EXISTS (
    SELECT 1
    FROM cron.job
    WHERE jobname = 'horus-business-document-cleanup'
      AND active
      AND username = 'postgres'
  ) THEN
    IF NOT EXISTS (
      SELECT 1
      FROM vault.secrets
      WHERE name = 'horus_business_document_cleanup_token'
    ) OR NOT EXISTS (
      SELECT 1
      FROM vault.secrets
      WHERE name = 'horus_business_document_cleanup_endpoint'
    ) THEN
      RAISE EXCEPTION
        'issue_357_cleanup_vault_configuration_missing';
    END IF;

    -- Updating the job with its existing name preserves its cadence and
    -- replaces only the HTTP-on-every-tick behavior. Endpoint and token are
    -- resolved from Vault only if the predicate is true.
    PERFORM cron.schedule(
      'horus-business-document-cleanup',
      '*/15 * * * *',
      $conditional_http$
      SELECT net.http_post(
        url := (
          SELECT decrypted_secret
          FROM vault.decrypted_secrets
          WHERE name = 'horus_business_document_cleanup_endpoint'
        ),
        headers := pg_catalog.jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            SELECT decrypted_secret
            FROM vault.decrypted_secrets
            WHERE name = 'horus_business_document_cleanup_token'
          )
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 15000
      )
      WHERE private.business_document_cleanup_has_work();
      $conditional_http$
    );
  END IF;
END;
$schedule_only_existing$;

COMMIT;
