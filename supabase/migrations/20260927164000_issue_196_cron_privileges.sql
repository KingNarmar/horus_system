-- H.O.R.U.S System — Issue #196 cron execution privileges
-- Supabase Cron installation contract requires postgres access to its schema.

BEGIN;

GRANT USAGE ON SCHEMA cron TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA cron TO postgres;

COMMIT;
