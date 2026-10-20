-- Issue #317 R4.1: finance-only tenant-private Ledger and Trip Expense hints.
-- Only company/resource markers are broadcast; no amounts or ledger records.
-- The ledger is canonical, including trip-linked legacy company expense mirroring.
BEGIN;

CREATE POLICY horus_expense_ledger_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:expense_ledger$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'accountant']::public.company_role[]
  )
);

CREATE POLICY horus_trip_expenses_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:trip_expenses$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'accountant']::public.company_role[]
  )
);

-- No INSERT policy is added on realtime.messages for clients.
-- Both signals are inserted transactionally with the canonical ledger mutation.
CREATE FUNCTION private.broadcast_expense_ledger_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_company_id uuid;
  v_trip_related boolean;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_company_id := NEW.company_id;
    v_trip_related := NEW.trip_id IS NOT NULL;
  ELSIF TG_OP = 'UPDATE' THEN
    v_company_id := NEW.company_id;
    v_trip_related := OLD.trip_id IS NOT NULL OR NEW.trip_id IS NOT NULL;
  ELSE
    v_company_id := OLD.company_id;
    v_trip_related := OLD.trip_id IS NOT NULL;
  END IF;

  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', v_company_id,
      'resource', 'expense_ledger'
    ),
    'changed',
    'horus:company:' || v_company_id::text || ':expense_ledger',
    true
  );

  IF v_trip_related THEN
    PERFORM realtime.send(
      pg_catalog.jsonb_build_object(
        'company_id', v_company_id,
        'resource', 'trip_expenses'
      ),
      'changed',
      'horus:company:' || v_company_id::text || ':trip_expenses',
      true
    );
  END IF;

  RETURN NULL; -- AFTER row trigger; never changes business data.
END;
$function$;

REVOKE ALL
ON FUNCTION private.broadcast_expense_ledger_invalidation()
FROM PUBLIC, anon, authenticated;

CREATE TRIGGER expense_ledger_entries_realtime_invalidation
AFTER INSERT OR UPDATE OR DELETE ON public.expense_ledger_entries
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_expense_ledger_invalidation();

COMMIT;
