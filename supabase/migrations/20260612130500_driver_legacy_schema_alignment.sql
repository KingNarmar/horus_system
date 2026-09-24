-- Issue #197: restore the historical Driver schema alignment that existed
-- in the live development database but was not represented in migrations.
--
-- The original V1 schema used drivers.name. The Driver feature later adopted
-- drivers.full_name and drivers.license_number while preserving legacy name
-- compatibility. Fresh environments must reproduce that bridge explicitly.

BEGIN;

ALTER TABLE public.drivers
  ADD COLUMN IF NOT EXISTS full_name text,
  ADD COLUMN IF NOT EXISTS license_number text;

UPDATE public.drivers
SET full_name = name
WHERE (full_name IS NULL OR pg_catalog.btrim(full_name) = '')
  AND name IS NOT NULL
  AND pg_catalog.btrim(name) <> '';

UPDATE public.drivers
SET name = full_name
WHERE (name IS NULL OR pg_catalog.btrim(name) = '')
  AND full_name IS NOT NULL
  AND pg_catalog.btrim(full_name) <> '';

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.drivers
    WHERE full_name IS NULL
       OR pg_catalog.btrim(full_name) = ''
       OR name IS NULL
       OR pg_catalog.btrim(name) = ''
  ) THEN
    RAISE EXCEPTION
      'Driver schema alignment stopped: blank legacy/current driver names exist.';
  END IF;
END
$$;

ALTER TABLE public.drivers
  ALTER COLUMN full_name SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS drivers_company_license_number_unique_idx
  ON public.drivers (company_id, license_number)
  WHERE license_number IS NOT NULL;

CREATE OR REPLACE FUNCTION public.sync_driver_name_fields()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  IF NEW.full_name IS NULL OR pg_catalog.btrim(NEW.full_name) = '' THEN
    NEW.full_name := NEW.name;
  END IF;

  IF NEW.name IS NULL OR pg_catalog.btrim(NEW.name) = '' THEN
    NEW.name := NEW.full_name;
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.sync_driver_name_fields()
FROM PUBLIC, anon, authenticated, service_role;

DROP TRIGGER IF EXISTS sync_driver_name_fields_trigger
ON public.drivers;

CREATE TRIGGER sync_driver_name_fields_trigger
BEFORE INSERT OR UPDATE
ON public.drivers
FOR EACH ROW
EXECUTE FUNCTION public.sync_driver_name_fields();

COMMIT;
