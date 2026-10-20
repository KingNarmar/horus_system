-- Issue #327 — independent finance-only default freight rate mutation for Routes.
-- Keep Operations route management separate from Accountant pricing.
-- Built-in Route realtime + server audit triggers remain authoritative.
BEGIN;

CREATE OR REPLACE FUNCTION private.enforce_route_freight_write_access()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_accountant boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE'
     AND NEW.company_id IS DISTINCT FROM OLD.company_id THEN
    RAISE EXCEPTION USING
      ERRCODE='P3410', MESSAGE='routes_management_permission_denied';
  END IF;

  v_accountant := private.has_company_role(
    NEW.company_id,
    ARRAY['accountant']::public.company_role[]
  );

  IF v_accountant THEN
    -- A finance actor can change only the rate, with server-owned update
    -- metadata. Comparing all other fields is future-safe if schema grows.
    IF TG_OP <> 'UPDATE'
       OR NEW.default_freight_price IS NOT DISTINCT FROM OLD.default_freight_price
       OR NEW.updated_by IS DISTINCT FROM auth.uid()
       OR (pg_catalog.to_jsonb(NEW) - ARRAY[
             'default_freight_price','updated_by','updated_at'
           ]::text[])
          IS DISTINCT FROM
          (pg_catalog.to_jsonb(OLD) - ARRAY[
             'default_freight_price','updated_by','updated_at'
           ]::text[]) THEN
      RAISE EXCEPTION USING
        ERRCODE='P3431', MESSAGE='route_default_freight_permission_denied';
    END IF;
    RETURN NEW;
  END IF;

  IF NOT private.has_company_role(
    NEW.company_id,
    ARRAY['owner','admin','operations']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE='P3410', MESSAGE='routes_management_permission_denied';
  END IF;

  IF private.has_company_role(
    NEW.company_id,
    ARRAY['operations']::public.company_role[]
  ) THEN
    IF TG_OP='INSERT' THEN
      IF NEW.default_freight_price IS NOT NULL THEN
        RAISE EXCEPTION USING
          ERRCODE='P3431', MESSAGE='route_default_freight_permission_denied';
      END IF;
    ELSIF NEW.default_freight_price IS DISTINCT FROM OLD.default_freight_price THEN
      IF NEW.default_freight_price IS NOT NULL THEN
        RAISE EXCEPTION USING
          ERRCODE='P3431', MESSAGE='route_default_freight_permission_denied';
      END IF;
      NEW.default_freight_price := OLD.default_freight_price;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_route_freight_write_access()
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.set_route_default_freight_rate_atomic(
  p_company_id uuid,
  p_route_id uuid,
  p_default_freight_rate text,
  p_expected_updated_at timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_route public.routes%ROWTYPE;
  v_digits integer;
  v_rate numeric;
  v_projection jsonb;
BEGIN
  IF auth.uid() IS NULL OR NOT private.has_company_role(
    p_company_id,
    ARRAY['owner','admin','accountant']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE='P3431', MESSAGE='route_default_freight_permission_denied';
  END IF;

  SELECT r.* INTO v_route
  FROM public.routes r
  WHERE r.company_id=p_company_id AND r.id=p_route_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE='P3442', MESSAGE='route_not_found';
  END IF;

  IF p_expected_updated_at IS NULL
     OR v_route.updated_at IS DISTINCT FROM p_expected_updated_at THEN
    RAISE EXCEPTION USING
      ERRCODE='P3440', MESSAGE='route_stale_financial_snapshot';
  END IF;

  SELECT c.base_currency_fraction_digits INTO v_digits
  FROM public.companies c WHERE c.id=p_company_id AND c.is_active=true;
  IF v_digits IS NULL OR v_digits NOT BETWEEN 0 AND 4 THEN
    RAISE EXCEPTION USING
      ERRCODE='P3441', MESSAGE='route_financial_currency_invalid';
  END IF;

  IF p_default_freight_rate IS NULL
     OR pg_catalog.btrim(p_default_freight_rate)
       !~ '^[0-9]{1,12}([.][0-9]{1,4})?$' THEN
    RAISE EXCEPTION USING
      ERRCODE='P3441', MESSAGE='route_default_rate_invalid';
  END IF;

  v_rate := p_default_freight_rate::numeric;
  IF v_rate < 0 OR v_rate >= 1000000000000::numeric
     OR v_rate IS DISTINCT FROM pg_catalog.round(v_rate,v_digits) THEN
    RAISE EXCEPTION USING
      ERRCODE='P3441', MESSAGE='route_default_rate_invalid';
  END IF;

  IF v_rate IS DISTINCT FROM v_route.default_freight_price THEN
    UPDATE public.routes SET
      default_freight_price=v_rate,
      updated_by=auth.uid()
    WHERE company_id=p_company_id AND id=p_route_id;
    -- The existing Route audit + R3 invalidation triggers execute once.
  END IF;

  SELECT r.value INTO v_projection
  FROM public.get_authorized_route_records(p_company_id,p_route_id,false)
    AS r(value);

  IF v_projection IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P3442',MESSAGE='route_not_found';
  END IF;
  RETURN v_projection;
END;
$function$;

REVOKE ALL ON FUNCTION public.set_route_default_freight_rate_atomic(
  uuid,uuid,text,timestamptz
) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.set_route_default_freight_rate_atomic(
  uuid,uuid,text,timestamptz
) TO authenticated;

COMMIT;
