-- Issue #317 R3 Fleet Assets: server-owned private invalidation for
-- both tractor heads and trailers. Never include plates, notes or license data.
BEGIN;

DROP POLICY IF EXISTS horus_fleet_realtime_receive
ON realtime.messages;

CREATE POLICY horus_fleet_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:fleet$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']::public.company_role[]
  )
);

-- RLS intentionally provides no client INSERT permission on realtime.messages.
CREATE OR REPLACE FUNCTION private.broadcast_fleet_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'fleet'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':fleet',
    true
  );
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.broadcast_fleet_invalidation()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS tractor_heads_write_realtime_invalidation
ON public.tractor_heads;

CREATE TRIGGER tractor_heads_write_realtime_invalidation
AFTER INSERT OR UPDATE
ON public.tractor_heads
FOR EACH ROW EXECUTE FUNCTION private.broadcast_fleet_invalidation();

DROP TRIGGER IF EXISTS trailers_write_realtime_invalidation
ON public.trailers;

CREATE TRIGGER trailers_write_realtime_invalidation
AFTER INSERT OR UPDATE
ON public.trailers
FOR EACH ROW EXECUTE FUNCTION private.broadcast_fleet_invalidation();

COMMIT;
