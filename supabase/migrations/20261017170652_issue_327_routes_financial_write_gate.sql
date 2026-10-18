-- #327: enforce financial field ownership on Route creates and updates.
-- Verified from the already-applied Development schema; no Production change.
BEGIN;

CREATE OR REPLACE FUNCTION private.enforce_route_freight_write_access()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.company_id IS DISTINCT FROM OLD.company_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3410', MESSAGE = 'routes_management_permission_denied';
  END IF;

  IF NOT private.has_company_role(
    NEW.company_id,
    ARRAY['owner','admin','operations']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3410', MESSAGE = 'routes_management_permission_denied';
  END IF;

  IF private.has_company_role(
    NEW.company_id,
    ARRAY['operations']::public.company_role[]
  ) THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.default_freight_price IS NOT NULL THEN
        RAISE EXCEPTION USING
          ERRCODE = 'P3431',
          MESSAGE = 'route_default_freight_permission_denied';
      END IF;
    ELSIF NEW.default_freight_price IS DISTINCT FROM OLD.default_freight_price THEN
      IF NEW.default_freight_price IS NOT NULL THEN
        RAISE EXCEPTION USING
          ERRCODE = 'P3431',
          MESSAGE = 'route_default_freight_permission_denied';
      END IF;
      NEW.default_freight_price := OLD.default_freight_price;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_route_freight_write_access()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS routes_financial_write_gate ON public.routes;
CREATE TRIGGER routes_financial_write_gate
BEFORE INSERT OR UPDATE ON public.routes
FOR EACH ROW EXECUTE FUNCTION private.enforce_route_freight_write_access();

COMMIT;
