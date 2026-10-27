-- Issue #317 R4.6 — private payment-history invalidation only.
-- Development-first migration; Production requires separate explicit approval.
-- register_payment inserts a payment and updates its invoice atomically.
-- R4.5 owns all invoice-derived invalidations, so this trigger only signals
-- that the authoritative Payments List should be re-read.
BEGIN;

CREATE POLICY horus_payments_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:payments$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'accountant']::public.company_role[]
  )
);

-- No client broadcast INSERT/ALL policy or new GRANT is introduced.
CREATE FUNCTION private.broadcast_payments_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'payments'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':payments',
    true
  );
  RETURN NULL; -- AFTER trigger: never changes the business row.
END;
$function$;

REVOKE ALL ON FUNCTION private.broadcast_payments_invalidation()
FROM PUBLIC, anon, authenticated;

-- Payment registration is the only authorized business write.
-- The invoices UPDATE in the same RPC already broadcasts through R4.5.
CREATE TRIGGER payments_realtime_invalidation
AFTER INSERT ON public.payments
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_payments_invalidation();

COMMIT;
