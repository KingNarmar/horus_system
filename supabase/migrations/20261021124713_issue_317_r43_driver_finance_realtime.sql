-- Issue #317 R4.3: finance-only Driver Finance invalidation.
-- The present business mutation path inserts driver_financial_movements rows.
-- Deliver company/resource markers only, never movement details or balances.
BEGIN;

CREATE POLICY horus_driver_finance_realtime_receive
ON realtime.messages FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:driver_finance$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'accountant']::public.company_role[]
  )
);

-- No policy grants clients permission to send a Broadcast.
CREATE FUNCTION private.broadcast_driver_finance_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'driver_finance'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':driver_finance',
    true
  );

  RETURN NULL; -- AFTER trigger; does not modify the financial movement.
END;
$function$;

REVOKE ALL
ON FUNCTION private.broadcast_driver_finance_invalidation()
FROM PUBLIC, anon, authenticated;

CREATE TRIGGER driver_financial_movements_realtime_invalidation
AFTER INSERT ON public.driver_financial_movements
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_driver_finance_invalidation();

COMMIT;
