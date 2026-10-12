-- Issue #317: tenant-scoped, server-owned Customers invalidation.
-- Clients never receive customer values, audit snapshots or financial data.
BEGIN;

DROP POLICY IF EXISTS horus_customers_realtime_receive
ON realtime.messages;

-- Match the exact roles allowed by public.customers SELECT RLS.
-- The guarded cast rejects arbitrary channel topics safely.
CREATE POLICY horus_customers_realtime_receive
ON realtime.messages
FOR SELECT
TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:customers$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY[
      'owner', 'admin', 'operations', 'accountant', 'viewer'
    ]::public.company_role[]
  )
);

-- NO client INSERT policy. This channel is receive-only.
CREATE OR REPLACE FUNCTION private.broadcast_customer_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'customers'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':customers',
    true
  );
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.broadcast_customer_invalidation()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS customers_write_realtime_invalidation
ON public.customers;

CREATE TRIGGER customers_write_realtime_invalidation
AFTER INSERT OR UPDATE
ON public.customers
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_customer_invalidation();

COMMIT;
