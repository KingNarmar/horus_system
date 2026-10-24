-- Issue #317 R4.5 — finance-only, company-private invoice invalidation.
-- Development-first migration. Applying this to Production requires separate approval.
-- Invoice draft reservation, issuance, cancellation and payment-status changes
-- all update public.invoices inside their existing atomic business transactions.
BEGIN;

CREATE POLICY horus_invoices_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:invoices$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'accountant']::public.company_role[]
  )
);

-- No client broadcast INSERT/ALL grant or policy is introduced.
CREATE FUNCTION private.broadcast_invoices_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'invoices'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':invoices',
    true
  );
  RETURN NULL; -- AFTER row trigger: business state is never changed.
END;
$function$;

REVOKE ALL ON FUNCTION private.broadcast_invoices_invalidation()
FROM PUBLIC, anon, authenticated;

-- UPDATE is required even when invoice.status remains draft. Draft lines
-- and their billable-trip reservations may change without a status transition.
-- Updates caused by register_payment are likewise covered without modifying
-- the payment RPC or creating a competing broadcast source.
CREATE TRIGGER invoices_realtime_invalidation
AFTER INSERT OR UPDATE ON public.invoices
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_invoices_invalidation();

COMMIT;
