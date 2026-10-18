-- #327 — Dedicated finance-only Trip rate mutation, no operational field writes.
-- The full UPDATE, audit and response are one transaction in SECURITY DEFINER.
-- Pricing an invoiced Trip or overwriting a stale snapshot is forbidden.
BEGIN;

CREATE OR REPLACE FUNCTION public.set_trip_freight_rate_atomic(
  p_company_id uuid,
  p_trip_id uuid,
  p_agreed_freight_rate_per_ton text,
  p_expected_updated_at timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_trip public.trips%ROWTYPE;
  v_fraction_digits smallint;
  v_rate numeric;
  v_amount numeric;
  v_old_audit jsonb;
  v_new_audit jsonb;
  v_snapshot jsonb;
BEGIN
  IF auth.uid() IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner','admin','accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE='P3431', MESSAGE='trip_financial_terms_permission_denied';
  END IF;

  IF p_trip_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P3412', MESSAGE='trip_not_found';
  END IF;

  SELECT trip.* INTO v_trip
  FROM public.trips AS trip
  WHERE trip.company_id=p_company_id AND trip.id=p_trip_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P3412', MESSAGE='trip_not_found';
  END IF;

  IF p_expected_updated_at IS NULL OR
     v_trip.updated_at IS DISTINCT FROM p_expected_updated_at THEN
    RAISE EXCEPTION USING ERRCODE='P3414', MESSAGE='trip_stale_snapshot';
  END IF;

  IF v_trip.invoice_id IS NOT NULL THEN
    RAISE EXCEPTION USING ERRCODE='P3436', MESSAGE='trip_invoiced_financial_terms_locked';
  END IF;

  IF v_trip.quantity_tons IS NULL OR v_trip.quantity_tons <= 0 THEN
    RAISE EXCEPTION USING ERRCODE='P3437', MESSAGE='trip_quantity_required_for_pricing';
  END IF;

  SELECT c.base_currency_fraction_digits INTO v_fraction_digits
  FROM public.companies AS c
  WHERE c.id=p_company_id AND c.is_active=true;
  IF v_fraction_digits IS NULL OR v_fraction_digits NOT BETWEEN 0 AND 4 THEN
    RAISE EXCEPTION USING
      ERRCODE='P3435', MESSAGE='trip_financial_currency_configuration_invalid';
  END IF;

  IF p_agreed_freight_rate_per_ton IS NULL
     OR pg_catalog.btrim(p_agreed_freight_rate_per_ton)
        !~ '^[0-9]{1,12}(\.[0-9]{1,4})?$' THEN
    RAISE EXCEPTION USING ERRCODE='P3435', MESSAGE='trip_financial_rate_invalid';
  END IF;

  v_rate:=p_agreed_freight_rate_per_ton::numeric;
  IF v_rate < 0 OR v_rate >= 1000000000000::numeric OR
     v_rate IS DISTINCT FROM round(v_rate,v_fraction_digits) THEN
    RAISE EXCEPTION USING ERRCODE='P3435', MESSAGE='trip_financial_rate_invalid';
  END IF;

  v_amount:=round(v_trip.quantity_tons*v_rate,v_fraction_digits);
  IF v_amount < 0 OR v_amount >= 1000000000000::numeric THEN
    RAISE EXCEPTION USING ERRCODE='P3435', MESSAGE='trip_financial_amount_out_of_range';
  END IF;

  v_old_audit:=private.trip_audit_values(p_company_id,p_trip_id);

  UPDATE public.trips
  SET agreed_freight_rate_per_ton=v_rate,
      freight_price=v_amount,
      updated_by=auth.uid()
  WHERE company_id=p_company_id AND id=p_trip_id;

  v_new_audit:=private.trip_audit_values(p_company_id,p_trip_id);
  v_snapshot:=private.trip_snapshot_json(p_company_id,p_trip_id);

  PERFORM private.write_audit_event(
    p_company_id,'trips','trip',p_trip_id::text,
    private.trip_entity_display_name(v_snapshot),
    'updated','trip_updated',
    v_old_audit,v_new_audit,
    pg_catalog.jsonb_build_object(
      'financial_terms_changed',true,
      'fields',pg_catalog.jsonb_build_array(
        'agreed_freight_rate_per_ton','commercial_amount'
      )
    )
  );

  RETURN v_snapshot;
END;
$function$;

REVOKE ALL ON FUNCTION public.set_trip_freight_rate_atomic(
  uuid,uuid,text,timestamptz
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.set_trip_freight_rate_atomic(
  uuid,uuid,text,timestamptz
) TO authenticated;

COMMIT;
