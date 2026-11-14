-- H.O.R.U.S #357 — daily orphan cleanup instead of a 15-minute tick.
-- The existing service, conditional work predicate and Vault authentication
-- remain unchanged. This migration updates the schedule of ONE known job.
-- A disposable replay has no configured hosted job, so it is a safe no-op.
BEGIN;

DO $reschedule_daily_cleanup$
DECLARE
  v_job cron.job%ROWTYPE;
BEGIN
  SELECT *
  INTO v_job
  FROM cron.job
  WHERE jobname = 'horus-business-document-cleanup';

  IF NOT FOUND OR NOT v_job.active THEN
    -- Never create or reactivate an environment-specific scheduled job.
    RETURN;
  END IF;

  IF v_job.username IS DISTINCT FROM 'postgres'
    OR v_job.schedule NOT IN ('*/15 * * * *', '10 2 * * *')
    OR v_job.command NOT LIKE
      '%WHERE private.business_document_cleanup_has_work();%'
    OR v_job.command NOT LIKE '%net.http_post(%'
    OR v_job.command NOT LIKE '%vault.decrypted_secrets%'
  THEN
    RAISE EXCEPTION 'issue_357_cleanup_job_contract_changed';
  END IF;

  -- pg_cron uses GMT/UTC in the hosted environment. 02:10 GMT = 06:10
  -- Dubai time. Keep the existing command, job ID, owner and active flag.
  PERFORM cron.alter_job(
    job_id := v_job.jobid,
    schedule := '10 2 * * *'
  );
END;
$reschedule_daily_cleanup$;

COMMIT;
