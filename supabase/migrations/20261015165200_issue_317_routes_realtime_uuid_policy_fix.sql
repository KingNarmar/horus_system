-- Issue #317 R3 Routes: repair private topic UUID shape (5 UUID groups).
-- The prior migration was applied; keep its history immutable.
BEGIN;

DROP POLICY IF EXISTS horus_routes_realtime_receive
ON realtime.messages;

CREATE POLICY horus_routes_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:routes$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']::public.company_role[]
  )
);

COMMIT;
