-- H.O.R.U.S #357 — keep the approved daily cleanup cadence at midnight Dubai.
-- 00:00 Asia/Dubai (UTC+04:00 year-round) = 20:00 UTC of the prior day.
-- Only reschedule the existing authenticated, due-work-gated job.
-- In disposable migration replays without a hosted job this is a no-op.
BEGIN;

DO $reschedule_midnight_dubai_cleanup$
DECLARE
  v_job cron.job%ROWTYPE;
BEGIN
  SELECT * INTO v_job
  FROM cron.job
  WHERE jobname = 'horus-business-document-cleanup';

  IF NOT FOUND OR NOT v_job.active THEN
    -- Never create or activate a missing or paused hosted job.
    RETURN;
  END IF;

  IF v_job.username IS DISTINCT FROM 'postgres'
    OR v_job.schedule NOT IN ('10 2 * * *', '0 20 * * *')
    OR pg_catalog.current_setting('cron.timezone', true) IS DISTINCT FROM 'GMT'
    OR v_job.command NOT LIKE '%WHERE private.business_document_cleanup_has_work();%'
    OR v_job.command NOT LIKE '%net.http_post(%'
    OR v_job.command NOT LIKE '%vault.decrypted_secrets%'
  THEN
    RAISE EXCEPTION 'issue_357_midnight_cleanup_job_contract_changed';
  END IF;

  -- Preserve job ID, command, Vault authentication, owner and active state.
  PERFORM cron.alter_job(job_id := v_job.jobid, schedule := '0 20 * * *');
END;
$reschedule_midnight_dubai_cleanup$;

COMMIT;
