-- H.O.R.U.S System — Issue #268
-- Tighten canonical Trip reference and sequence invariants.

BEGIN;

ALTER TABLE public.trip_sequences
  DROP CONSTRAINT IF EXISTS trip_sequences_value_check;

ALTER TABLE public.trip_sequences
  ADD CONSTRAINT trip_sequences_value_check
  CHECK (last_value BETWEEN 0 AND 999999);

ALTER TABLE public.trips
  DROP CONSTRAINT IF EXISTS trips_trip_number_format_check;

ALTER TABLE public.trips
  ADD CONSTRAINT trips_trip_number_format_check
  CHECK (
    trip_number ~ '^TRP-[0-9]{4}-[0-9]{6}$'
    AND pg_catalog.substr(trip_number, 5, 4)::integer BETWEEN 2000 AND 9999
    AND pg_catalog.right(trip_number, 6)::integer BETWEEN 1 AND 999999
  );

COMMIT;
