-- Issue #317: correct complete UUID validation in Fleet license topic.
-- The original version omitted the final 4-character UUID group.
BEGIN;

ALTER POLICY horus_fleet_license_documents_realtime_receive
ON realtime.messages
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:fleet_license_documents$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']::public.company_role[]
  )
);

COMMIT;
