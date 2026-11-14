"""Issue #357: disposable-only regression of daily cleanup cron rescheduling.

Runs only against the local Supabase CLI Docker database. The fixture's job
command is a harmless SQL SELECT; no real Edge request or secret is used.
"""
from pathlib import Path

from verify_issue_365_local_http import check, local_stack, psql


JOB_NAME = "horus-business-document-cleanup"
OLD_SCHEDULE = "*/15 * * * *"
DAILY_SCHEDULE = "10 2 * * *"


def main():
    _, _, _, db = local_stack()
    migration = (Path(__file__).resolve().parents[2]
                 / "supabase/migrations"
                 / "20261114190000_issue_357_daily_document_cleanup.sql")
    content = migration.read_text(encoding="utf-8")

    check("local replay does not create a hosted cleanup job",
          psql(db, "SELECT count(*) FROM cron.job "
                   "WHERE jobname='" + JOB_NAME + "';") == "0")

    # Simulates the shape of the guarded job with a harmless command; the
    # comment satisfies the expected shape without actually calling HTTP.
    command = ("SELECT 1 WHERE private.business_document_cleanup_has_work();"
               " -- net.http_post( vault.decrypted_secrets")
    job_id = psql(
        db, "SELECT cron.schedule('" + JOB_NAME + "','"
        + OLD_SCHEDULE + "',$safe_job$" + command + "$safe_job$);"
    )
    check("disposable guarded job created", job_id.isdigit())

    try:
        original_command = psql(
            db, "SELECT command FROM cron.job WHERE jobid=" + job_id + ";"
        )
        psql(db, content)

        check("daily migration changes only the cadence",
              psql(db, "SELECT schedule FROM cron.job WHERE jobid="
                   + job_id + ";") == DAILY_SCHEDULE)
        check("daily migration preserves the command and credentials handling",
              psql(db, "SELECT command FROM cron.job WHERE jobid="
                   + job_id + ";") == original_command)
        check("daily migration preserves job identity and owner",
              psql(db, "SELECT count(*) FROM cron.job WHERE jobid="
                   + job_id + " AND jobname='" + JOB_NAME
                   + "' AND username='postgres' AND active;") == "1")

        psql(db, content)
        check("daily migration may be safely replayed",
              psql(db, "SELECT schedule FROM cron.job WHERE jobid="
                   + job_id + ";") == DAILY_SCHEDULE)

        psql(db, "SELECT cron.alter_job(job_id:=" + job_id
             + ",schedule:='" + OLD_SCHEDULE + "',active:=false);")
        psql(db, content)
        check("disabled jobs are not reactivated or rescheduled",
              psql(db, "SELECT count(*) FROM cron.job WHERE jobid="
                   + job_id + " AND NOT active AND schedule='"
                   + OLD_SCHEDULE + "';") == "1")
    finally:
        psql(db, "SELECT cron.unschedule('" + JOB_NAME + "');")

    psql(db, content)
    check("no job is created without environment configuration",
          psql(db, "SELECT count(*) FROM cron.job WHERE jobname='"
               + JOB_NAME + "';") == "0")
    print("PASS Issue #357 daily cleanup schedule migration", flush=True)


if __name__ == "__main__":
    main()
