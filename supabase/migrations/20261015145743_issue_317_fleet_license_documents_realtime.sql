-- Issue #317 R3: server-authored Fleet License Documents invalidation.
-- Only file registrations and logical document removal emit notifications.
-- Never publish storage references, filenames, signed URLs or audit snapshots.
BEGIN;

CREATE POLICY horus_fleet_license_documents_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:fleet_license_documents$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'operations', 'accountant', 'viewer']::public.company_role[]
  )
);

-- No client INSERT policy is granted for realtime.messages.
CREATE FUNCTION private.broadcast_fleet_license_documents_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'fleet_license_documents'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':fleet_license_documents',
    true
  );
  RETURN NEW;
END;
$function$;

REVOKE ALL
ON FUNCTION private.broadcast_fleet_license_documents_invalidation()
FROM PUBLIC, anon, authenticated;

-- Create, add-side and replace all register a new file as their last
-- metadata mutation. Do not also notify on old-file removal during replace.
CREATE TRIGGER fleet_license_document_files_write_realtime_invalidation
AFTER INSERT ON public.fleet_license_document_files
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_fleet_license_documents_invalidation();

-- Logical document remove is the only RPC without a file INSERT.
CREATE TRIGGER fleet_license_documents_remove_realtime_invalidation
AFTER UPDATE OF removed_at ON public.fleet_license_documents
FOR EACH ROW
WHEN (OLD.removed_at IS NULL AND NEW.removed_at IS NOT NULL)
EXECUTE FUNCTION private.broadcast_fleet_license_documents_invalidation();

COMMIT;