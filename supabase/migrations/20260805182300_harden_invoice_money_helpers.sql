-- Issue #26: make invoice money conversion reject missing freight values
-- explicitly instead of allowing STRICT NULL propagation.

BEGIN;

CREATE OR REPLACE FUNCTION private.invoice_freight_to_minor_units(
  p_amount numeric,
  p_fraction_digits smallint
)
RETURNS bigint
LANGUAGE plpgsql
IMMUTABLE
SET search_path = pg_catalog
AS $$
DECLARE
  v_scaled numeric;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2616',
      MESSAGE = 'invoice_trip_not_billable';
  END IF;

  IF p_fraction_digits IS NULL
     OR p_fraction_digits NOT BETWEEN 0 AND 4 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2621',
      MESSAGE = 'invoice_freight_precision_invalid';
  END IF;

  v_scaled := p_amount * pg_catalog.power(10::numeric, p_fraction_digits);

  IF v_scaled <> pg_catalog.trunc(v_scaled)
     OR v_scaled > 9223372036854775807::numeric THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2621',
      MESSAGE = 'invoice_freight_precision_invalid';
  END IF;

  RETURN v_scaled::bigint;
END;
$$;

REVOKE ALL ON FUNCTION private.invoice_freight_to_minor_units(numeric, smallint)
  FROM PUBLIC;

COMMIT;
