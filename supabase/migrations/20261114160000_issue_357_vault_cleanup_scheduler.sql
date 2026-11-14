-- H.O.R.U.S #357: Vault-authenticated Development cleanup scheduler.
-- No credentials are committed. The 256-bit invocation token is generated
-- inside Postgres and is never returned to the caller or stored in cron.job.
-- Operator can set horus.cleanup.url in the SAME deployment transaction
-- (public project-specific URL only) to enable the environment's schedule.
-- Without this setting, e.g. disposable replay, no schedule is activated.
BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_net;

DO $setup_vault$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.secrets
    WHERE name = 'horus_business_document_cleanup_token'
  ) THEN
    PERFORM vault.create_secret(
      pg_catalog.encode(extensions.gen_random_bytes(32), 'hex'),
      'horus_business_document_cleanup_token',
      'H.O.R.U.S #357 private scheduled cleanup invocation token'
    );
  END IF;
END;
$setup_vault$;

-- The Edge runtime receives a trusted service-role client injected by
-- Supabase. Callers do NOT receive the role key: this RPC returns only a
-- boolean comparison of the supplied invocation token to the Vault secret.
CREATE FUNCTION public.authorize_business_document_cleanup(
  p_supplied_token text
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $authorize_cleanup$
DECLARE
  v_stored text;
BEGIN
  IF p_supplied_token IS NULL OR
     p_supplied_token !~ '^[0-9a-f]{64}$'
  THEN
    RETURN false;
  END IF;

  SELECT s.decrypted_secret INTO v_stored
  FROM vault.decrypted_secrets s
  WHERE s.name = 'horus_business_document_cleanup_token';

  RETURN v_stored IS NOT NULL AND
    extensions.digest(p_supplied_token, 'sha256') =
    extensions.digest(v_stored, 'sha256');
END;
$authorize_cleanup$;

REVOKE ALL ON FUNCTION public.authorize_business_document_cleanup(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.authorize_business_document_cleanup(text)
  TO service_role;

-- The project endpoint is deployment configuration and must NEVER be
-- hardcoded to Development in a migration that can later reach Production.
-- Only an explicitly configured environment activates the schedule.
DO $configure_schedule$
DECLARE
  v_url text := NULLIF(pg_catalog.current_setting('horus.cleanup.url', true), '');
BEGIN
  IF v_url IS NOT NULL THEN
    IF v_url !~
      '^https://[a-z0-9]{20}[.]supabase[.]co/functions/v1/business-document-cleanup$'
    THEN
      RAISE EXCEPTION
        'issue_357_cleanup_invalid_project_endpoint';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM vault.secrets
      WHERE name = 'horus_business_document_cleanup_endpoint'
    ) THEN
      PERFORM vault.create_secret(
        v_url,
        'horus_business_document_cleanup_endpoint',
        'H.O.R.U.S #357 environment-specific cleanup function URL'
      );
    ELSE
      IF NOT EXISTS (
        SELECT 1 FROM vault.decrypted_secrets
        WHERE name = 'horus_business_document_cleanup_endpoint'
          AND decrypted_secret = v_url
      ) THEN
        RAISE EXCEPTION
          'issue_357_cleanup_endpoint_change_requires_review';
      END IF;
    END IF;

    PERFORM cron.schedule(
      'horus-business-document-cleanup',
      '*/15 * * * *',
      $scheduled_http$
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
      );
      $scheduled_http$
    );
  END IF;
END;
$configure_schedule$;

COMMIT;
