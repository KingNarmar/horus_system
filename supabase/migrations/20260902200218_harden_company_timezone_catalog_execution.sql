-- H.O.R.U.S System — Issue #37 Company timezone catalog hardening
-- The PostgreSQL timezone catalog is readable by authenticated users without
-- elevated privileges, so keep this read-only RPC SECURITY INVOKER.

BEGIN;

ALTER FUNCTION public.list_company_timezones()
  SECURITY INVOKER;

COMMIT;
