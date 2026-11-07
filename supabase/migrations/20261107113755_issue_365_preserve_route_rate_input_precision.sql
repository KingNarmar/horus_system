-- Issue #365 follow-up: prevent pre-trigger numeric(16,4) input rounding.
-- Keep the original 12-digit integer bound and 4-decimal maximum using
-- explicit DB CHECKs and the existing company-precision guard trigger.
-- Existing Route values are preserved exactly.
BEGIN;

ALTER TABLE public.routes
  ALTER COLUMN default_freight_price TYPE numeric
  USING default_freight_price::numeric;

ALTER TABLE public.routes
  ADD CONSTRAINT routes_default_freight_price_upper_bound_365
  CHECK (
    default_freight_price IS NULL
    OR default_freight_price < 1000000000000::numeric
  );

DO $verify$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_attribute a
    WHERE a.attrelid='public.routes'::regclass
      AND a.attname='default_freight_price'
      AND a.atttypmod = -1
  ) OR NOT EXISTS (
    SELECT 1 FROM pg_constraint c
    WHERE c.conrelid='public.routes'::regclass
      AND c.conname='routes_default_freight_price_upper_bound_365'
  ) OR has_column_privilege(
    'authenticated','public.routes','default_freight_price','UPDATE'
  ) THEN
    RAISE EXCEPTION 'Issue #365: Route price precision follow-up verification failed';
  END IF;
END
$verify$;

COMMIT;
