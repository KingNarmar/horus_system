-- H.O.R.U.S System — Issue #268
-- Keep Trip reference exhaustion inside the typed server-owned generation path
-- instead of allowing the sequence table CHECK constraint to surface first.

BEGIN;

CREATE OR REPLACE FUNCTION private.next_trip_number(
  p_company_id uuid
)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_business_timezone text;
  v_trip_year integer;
  v_sequence_value bigint;
BEGIN
  SELECT company_row.business_timezone
  INTO v_business_timezone
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND
     OR v_business_timezone IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM pg_catalog.pg_timezone_names timezone_entry
       WHERE timezone_entry.name = v_business_timezone
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3427',
      MESSAGE = 'trip_reference_generation_failed';
  END IF;

  v_trip_year := pg_catalog.date_part(
    'year',
    pg_catalog.now() AT TIME ZONE v_business_timezone
  )::integer;

  INSERT INTO public.trip_sequences AS sequence_row (
    company_id,
    trip_year,
    last_value,
    updated_at
  )
  VALUES (
    p_company_id,
    v_trip_year,
    1,
    pg_catalog.now()
  )
  ON CONFLICT (company_id, trip_year) DO UPDATE
  SET
    last_value = sequence_row.last_value + 1,
    updated_at = pg_catalog.now()
  WHERE sequence_row.last_value < 999999
  RETURNING last_value INTO v_sequence_value;

  IF v_sequence_value IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3427',
      MESSAGE = 'trip_reference_generation_failed';
  END IF;

  RETURN
    'TRP-'
    || v_trip_year::text
    || '-'
    || pg_catalog.lpad(v_sequence_value::text, 6, '0');
END;
$$;

REVOKE ALL ON FUNCTION private.next_trip_number(uuid)
FROM PUBLIC, anon, authenticated;

COMMIT;
