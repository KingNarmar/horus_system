-- Issue #317 / R4.2: tenant-private Company Expenses invalidation.
-- Company Expenses include salary-category records excluded from the canonical
-- Expense Ledger. Do not piggyback on its broadcast or alter financial rules.
-- Emit a minimal hint after each committed INSERT/UPDATE of the legacy view.
BEGIN;

CREATE POLICY horus_company_expenses_realtime_receive
ON realtime.messages FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:company_expenses$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner', 'admin', 'accountant']::public.company_role[]
  )
);

-- No authenticated/anon broadcast INSERT grants or policies are introduced.
CREATE FUNCTION private.broadcast_company_expenses_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'company_expenses'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':company_expenses',
    true
  );

  RETURN NULL; -- AFTER trigger, never modifies the business record.
END;
$function$;

REVOKE ALL
ON FUNCTION private.broadcast_company_expenses_invalidation()
FROM PUBLIC, anon, authenticated;

CREATE TRIGGER company_expenses_realtime_invalidation
AFTER INSERT OR UPDATE ON public.company_expenses
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_company_expenses_invalidation();

COMMIT;
