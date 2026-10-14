-- Issue #317 R3: private tenant-scoped, server-authored Drivers reload hints.
-- Never send personally identifiable Driver fields, documents, or compensation.
BEGIN;

DROP POLICY IF EXISTS horus_drivers_realtime_receive
ON realtime.messages;

CREATE POLICY horus_drivers_realtime_receive
ON realtime.messages
FOR SELECT
TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:drivers$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']::public.company_role[]
  )
);

-- No policy for client INSERT on realtime.messages.
CREATE OR REPLACE FUNCTION private.broadcast_driver_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'drivers'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':drivers',
    true
  );
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.broadcast_driver_invalidation()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS drivers_write_realtime_invalidation
ON public.drivers;

CREATE TRIGGER drivers_write_realtime_invalidation
AFTER INSERT OR UPDATE
ON public.drivers
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_driver_invalidation();

COMMIT;
