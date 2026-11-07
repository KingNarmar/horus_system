-- Issue #365: server-authoritative Route rate updates and currency precision.
-- Owner/admin/accountant price changes must use the existing version-checked RPC.
-- Existing prices are not changed or backfilled by this migration.
BEGIN;

-- Authenticated is a shared PostgREST SQL role. Its old table-wide UPDATE
-- privilege permitted direct rate writes without RPC version/precision checks.
REVOKE UPDATE ON TABLE public.routes FROM PUBLIC, anon, authenticated;
REVOKE UPDATE (default_freight_price) ON TABLE public.routes
  FROM PUBLIC, anon, authenticated;
GRANT UPDATE (
  loading_location, unloading_location, governorate_from,
  governorate_to, notes, is_active, updated_at, updated_by
) ON TABLE public.routes TO authenticated;

-- Keep Route creation pricing as well as financial RPC writes within the
-- company's configured currency precision. Operational-only edits of legacy
-- Routes are not blocked if an unchanged historical rate has more decimals.
CREATE OR REPLACE FUNCTION private.enforce_route_currency_precision()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_digits smallint;
BEGIN
  IF NEW.default_freight_price IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE'
     AND NEW.default_freight_price IS NOT DISTINCT FROM OLD.default_freight_price THEN
    RETURN NEW;
  END IF;

  SELECT company.base_currency_fraction_digits INTO v_digits
  FROM public.companies AS company
  WHERE company.id = NEW.company_id
    AND company.is_active = true;

  IF v_digits IS NULL
     OR v_digits NOT BETWEEN 0 AND 4
     OR NEW.default_freight_price < 0
     OR NEW.default_freight_price >= 1000000000000::numeric
     OR NEW.default_freight_price IS DISTINCT FROM
       pg_catalog.round(NEW.default_freight_price, v_digits) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3441',
      MESSAGE = 'route_default_rate_invalid';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_route_currency_precision()
  FROM PUBLIC, anon, authenticated;

CREATE TRIGGER routes_verify_freight_precision
BEFORE INSERT OR UPDATE ON public.routes
FOR EACH ROW EXECUTE FUNCTION private.enforce_route_currency_precision();

DO $verify$
BEGIN
  IF has_table_privilege('authenticated', 'public.routes', 'UPDATE')
     OR has_column_privilege(
       'authenticated', 'public.routes', 'default_freight_price', 'UPDATE'
     )
     OR NOT has_column_privilege(
       'authenticated', 'public.routes', 'loading_location', 'UPDATE'
     )
     OR NOT has_column_privilege(
       'authenticated', 'public.routes', 'notes', 'UPDATE'
     ) THEN
    RAISE EXCEPTION 'Issue #365: Route UPDATE privilege boundary is invalid';
  END IF;
END;
$verify$;

COMMIT;
