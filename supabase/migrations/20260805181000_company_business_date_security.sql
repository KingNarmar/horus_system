-- Company settings writes are RPC-only so role checks and audit cannot be bypassed.
-- The business date is derived from the configured IANA timezone in PostgreSQL.

BEGIN;

REVOKE UPDATE ON TABLE public.companies FROM anon;
REVOKE UPDATE ON TABLE public.companies FROM authenticated;

CREATE OR REPLACE FUNCTION public.get_company_business_date(
  p_company_id uuid
)
RETURNS date
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_business_timezone text;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.is_company_member(p_company_id) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2601',
      MESSAGE = 'company_settings_permission_denied';
  END IF;

  SELECT company_row.business_timezone
  INTO v_business_timezone
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2605',
      MESSAGE = 'company_not_found';
  END IF;

  IF v_business_timezone IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2607',
      MESSAGE = 'company_regional_settings_not_configured';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_timezone_names timezone_entry
    WHERE timezone_entry.name = v_business_timezone
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2604',
      MESSAGE = 'company_business_timezone_invalid';
  END IF;

  RETURN (pg_catalog.now() AT TIME ZONE v_business_timezone)::date;
END;
$$;

COMMENT ON FUNCTION public.get_company_business_date(uuid) IS
  'Returns the current calendar date in the active company IANA timezone.';

REVOKE ALL ON FUNCTION public.get_company_business_date(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_company_business_date(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_company_business_date(uuid)
  TO authenticated;

COMMIT;
