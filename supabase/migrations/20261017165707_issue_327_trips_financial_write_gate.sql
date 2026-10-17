-- Issue #327 — server-owned Trip financial write authorization.
-- Read exposure is fixed separately, coordinated with Flutter and finance RPCs.
BEGIN;

CREATE OR REPLACE FUNCTION private.enforce_trip_financial_write_access()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_operations boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF NOT private.has_company_role(
    NEW.company_id,
    ARRAY['owner','admin','operations','accountant']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3410',
      MESSAGE = 'trip_management_permission_denied';
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.company_id IS DISTINCT FROM OLD.company_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3410',
      MESSAGE = 'trip_management_permission_denied';
  END IF;

  v_operations := private.has_company_role(
    NEW.company_id,
    ARRAY['operations']::public.company_role[]
  );

  IF v_operations THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.agreed_freight_rate_per_ton IS NOT NULL
         OR NEW.freight_price IS NOT NULL
         OR NEW.total_expenses IS DISTINCT FROM 0::numeric THEN
        RAISE EXCEPTION USING
          ERRCODE = 'P3431',
          MESSAGE = 'trip_financial_terms_permission_denied';
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      IF (OLD.agreed_freight_rate_per_ton IS NOT NULL
          OR OLD.freight_price IS NOT NULL)
         AND NEW.quantity_tons IS DISTINCT FROM OLD.quantity_tons THEN
        RAISE EXCEPTION USING
          ERRCODE = 'P3432',
          MESSAGE = 'trip_priced_quantity_requires_finance_authorization';
      END IF;

      IF (NEW.agreed_freight_rate_per_ton IS NOT NULL
          AND NEW.agreed_freight_rate_per_ton IS DISTINCT FROM OLD.agreed_freight_rate_per_ton)
         OR (NEW.freight_price IS NOT NULL
          AND NEW.freight_price IS DISTINCT FROM OLD.freight_price)
         OR NEW.total_expenses IS DISTINCT FROM OLD.total_expenses
             AND NEW.total_expenses IS NOT NULL THEN
        RAISE EXCEPTION USING
          ERRCODE = 'P3431',
          MESSAGE = 'trip_financial_terms_permission_denied';
      END IF;

      NEW.agreed_freight_rate_per_ton := OLD.agreed_freight_rate_per_ton;
      NEW.freight_price := OLD.freight_price;
      NEW.total_expenses := OLD.total_expenses;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_trip_financial_write_access()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trips_financial_write_gate ON public.trips;
CREATE TRIGGER trips_financial_write_gate
BEFORE INSERT OR UPDATE ON public.trips
FOR EACH ROW
EXECUTE FUNCTION private.enforce_trip_financial_write_access();

COMMIT;
