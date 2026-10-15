-- Issue #317 R3 Routes: server-authored private route invalidation.
-- No route details, freight rates, notes or audit snapshots leave the server.
BEGIN;

CREATE POLICY horus_routes_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:routes$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']::public.company_role[]
  )
);

-- There is intentionally no INSERT policy for Realtime client messages.
CREATE FUNCTION private.broadcast_routes_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF TG_OP = 'UPDATE' AND
     ROW(
       OLD.loading_location, OLD.unloading_location,
       OLD.governorate_from, OLD.governorate_to,
       OLD.default_freight_price, OLD.notes, OLD.is_active
     ) IS NOT DISTINCT FROM
     ROW(
       NEW.loading_location, NEW.unloading_location,
       NEW.governorate_from, NEW.governorate_to,
       NEW.default_freight_price, NEW.notes, NEW.is_active
     ) THEN
    RETURN NEW;
  END IF;

  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'routes'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':routes',
    true
  );
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.broadcast_routes_invalidation()
FROM PUBLIC, anon, authenticated;

CREATE TRIGGER routes_write_realtime_invalidation
AFTER INSERT OR UPDATE
ON public.routes
FOR EACH ROW EXECUTE FUNCTION private.broadcast_routes_invalidation();

COMMIT;
