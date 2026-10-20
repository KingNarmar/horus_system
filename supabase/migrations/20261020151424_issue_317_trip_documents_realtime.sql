-- Issue #317 R3: tenant-private Trip Documents invalidation.
-- Server-owned metadata mutations emit only company/resource reload hints.
-- No document names, references, URLs, content, audit or financial payloads.
BEGIN;

CREATE POLICY horus_trip_documents_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:trip_documents$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']::public.company_role[]
  )
);

-- Clients have no INSERT RLS policy for realtime.messages.
-- Emitting from the metadata table guarantees no premature notification
-- for Storage uploads which fail before their atomic metadata RPC commits.
CREATE FUNCTION private.broadcast_trip_documents_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'trip_documents'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':trip_documents',
    true
  );
  RETURN NEW;
END;
$function$;

REVOKE ALL
ON FUNCTION private.broadcast_trip_documents_invalidation()
FROM PUBLIC, anon, authenticated;

-- Created metadata becomes visible only after the containing RPC commits.
CREATE TRIGGER trip_documents_insert_realtime_invalidation
AFTER INSERT ON public.trip_documents
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_trip_documents_invalidation();

-- Replace soft-removes the old row and inserts the new row in one atomic
-- RPC, so clients may see two hints; they coalesce the authoritative read.
CREATE TRIGGER trip_documents_remove_realtime_invalidation
AFTER UPDATE OF removed_at ON public.trip_documents
FOR EACH ROW
WHEN (OLD.removed_at IS NULL AND NEW.removed_at IS NOT NULL)
EXECUTE FUNCTION private.broadcast_trip_documents_invalidation();

COMMIT;
