-- H.O.R.U.S System — Issue #337 (Development first).
-- A finalized Driver Settlement must never retain a voided Trip Expense source.
-- Existing settlement snapshot, audit and private Realtime triggers stay intact.

-- Settlement items carry the authoritative captured-source identity.
-- Historical Trip Expense items may reference origin_id instead of ledger id.
-- Checkpoint fallback is deliberately limited to incomplete legacy snapshots.
CREATE OR REPLACE FUNCTION private.driver_settlement_captured_expense(
  p_entry public.expense_ledger_entries
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = pg_catalog
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.driver_settlement_items AS item
    JOIN public.driver_settlements AS settlement
      ON settlement.company_id = item.company_id
     AND settlement.id = item.settlement_id
    WHERE item.company_id = (p_entry).company_id
      AND item.source_type = 'trip_expense'::public.driver_settlement_item_source_type
      AND settlement.status = 'finalized'::public.driver_settlement_status
      AND (
        item.source_id = (p_entry).id
        OR (
          (p_entry).origin_kind = 'legacy_trip_expense'
          AND (p_entry).origin_id IS NOT NULL
          AND item.source_id = (p_entry).origin_id
        )
      )
  )
  OR (
    -- Fail closed only for historical snapshots whose captured Trip Expense
    -- total is positive but whose source item provenance is absent altogether.
    -- Ordinary late-posted/backdated ledger rows (created after the snapshot)
    -- are not considered captured merely because their expense_date is old.
    (p_entry).trip_id IS NOT NULL
    AND (p_entry).funding_source IN ('driver_advance', 'driver_cash')
    AND EXISTS (
      SELECT 1
      FROM public.driver_settlements AS settlement
      JOIN public.trips AS trip
        ON trip.company_id = settlement.company_id
       AND trip.driver_id = settlement.driver_id
       AND trip.id = (p_entry).trip_id
      WHERE settlement.company_id = (p_entry).company_id
        AND settlement.status = 'finalized'::public.driver_settlement_status
        AND settlement.driver_paid_trip_expenses_total > 0
        AND (p_entry).created_at <= settlement.created_at
        AND (p_entry).expense_date BETWEEN settlement.period_start
                                        AND settlement.period_end
        AND NOT EXISTS (
          SELECT 1
          FROM public.driver_settlement_items AS item
          WHERE item.company_id = settlement.company_id
            AND item.settlement_id = settlement.id
            AND item.source_type =
              'trip_expense'::public.driver_settlement_item_source_type
        )
    )
  );
$function$;

REVOKE ALL ON FUNCTION private.driver_settlement_captured_expense(
  public.expense_ledger_entries
) FROM PUBLIC, anon, authenticated;

-- Finalization and expense void contend for the same ledger-row locks.
-- Whichever mutation commits first determines whether the other may proceed:
--   finalize first -> void observes finalized source and is rejected;
--   void first     -> finalize observes voided source and is rejected.
-- This additional trigger does not replace the existing snapshot immutability
-- / status-transition / audit triggers on driver_settlements.
CREATE OR REPLACE FUNCTION private.guard_finalized_settlement_expense_sources()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_expense record;
BEGIN
  IF OLD.status <> 'draft'::public.driver_settlement_status
     OR NEW.status <> 'finalized'::public.driver_settlement_status THEN
    RETURN NEW;
  END IF;

  -- New settlements with a positive driver-paid expense total must retain
  -- at least one identifiable source item. Historical gaps are handled by
  -- the conservative void fallback above; do not create new gaps.
  IF NEW.driver_paid_trip_expenses_total > 0
     AND NOT EXISTS (
       SELECT 1
       FROM public.driver_settlement_items AS item
       WHERE item.company_id = NEW.company_id
         AND item.settlement_id = NEW.id
         AND item.source_type =
           'trip_expense'::public.driver_settlement_item_source_type
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2812',
      MESSAGE = 'driver_settlement_expense_source_invalid';
  END IF;

  -- A missing canonical ledger projection is not a valid source to finalize.
  IF EXISTS (
    SELECT 1
    FROM public.driver_settlement_items AS item
    LEFT JOIN public.expense_ledger_entries AS entry
      ON entry.company_id = item.company_id
     AND (
       entry.id = item.source_id
       OR (
         entry.origin_kind = 'legacy_trip_expense'
         AND entry.origin_id = item.source_id
       )
     )
    WHERE item.company_id = NEW.company_id
      AND item.settlement_id = NEW.id
      AND item.source_type = 'trip_expense'::public.driver_settlement_item_source_type
      AND entry.id IS NULL
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2812',
      MESSAGE = 'driver_settlement_expense_source_invalid';
  END IF;

  -- FOR SHARE conflicts with the Void RPC's FOR UPDATE on an expense row.
  FOR v_expense IN
    SELECT entry.id, entry.is_voided
    FROM public.driver_settlement_items AS item
    JOIN public.expense_ledger_entries AS entry
      ON entry.company_id = item.company_id
     AND (
       entry.id = item.source_id
       OR (
         entry.origin_kind = 'legacy_trip_expense'
         AND entry.origin_id = item.source_id
       )
     )
    WHERE item.company_id = NEW.company_id
      AND item.settlement_id = NEW.id
      AND item.source_type = 'trip_expense'::public.driver_settlement_item_source_type
    ORDER BY entry.id
    FOR SHARE OF entry
  LOOP
    IF v_expense.is_voided THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2812',
        MESSAGE = 'driver_settlement_expense_source_invalid';
    END IF;
  END LOOP;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.guard_finalized_settlement_expense_sources()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS driver_settlements_guard_expense_sources
  ON public.driver_settlements;
CREATE TRIGGER driver_settlements_guard_expense_sources
BEFORE UPDATE ON public.driver_settlements
FOR EACH ROW
EXECUTE FUNCTION private.guard_finalized_settlement_expense_sources();

-- Preserve the established RPC signature, grants and successful audit event.
-- Direct authenticated UPDATE on the ledger remains revoked.
CREATE OR REPLACE FUNCTION public.void_expense_ledger_entry(
  p_company_id uuid,
  p_expense_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS public.expense_ledger_entries
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_entry public.expense_ledger_entries%ROWTYPE;
  v_expense_type_name text;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  SELECT entry_row.*
    INTO v_entry
  FROM public.expense_ledger_entries AS entry_row
  WHERE entry_row.company_id = p_company_id
    AND entry_row.id = p_expense_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2806', MESSAGE = 'expense_ledger_not_found';
  END IF;

  -- Retain the existing supported origins; legacy Company Expense and
  -- Driver Financial Movement void remain outside this RPC's scope.
  IF v_entry.origin_kind NOT IN ('manual', 'legacy_trip_expense') THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  IF v_entry.is_voided THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2807', MESSAGE = 'expense_ledger_already_voided';
  END IF;

  IF private.driver_settlement_captured_expense(v_entry) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2811',
      MESSAGE = 'expense_ledger_finalized_settlement_locked';
  END IF;

  SELECT expense_type_row.name
    INTO v_expense_type_name
  FROM public.expense_types AS expense_type_row
  WHERE expense_type_row.company_id = p_company_id
    AND expense_type_row.id = v_entry.expense_type_id;

  UPDATE public.expense_ledger_entries
  SET is_voided = true,
      voided_at = pg_catalog.now(),
      voided_by = v_actor_user_id,
      void_reason = NULLIF(pg_catalog.btrim(p_reason), ''),
      updated_by = v_actor_user_id
  WHERE company_id = p_company_id
    AND id = p_expense_id
  RETURNING * INTO v_entry;

  PERFORM private.write_audit_event(
    p_company_id, 'expenses', 'expense_ledger_entry', v_entry.id::text,
    v_expense_type_name, 'voided', 'expense_ledger_entry_voided',
    pg_catalog.jsonb_build_object('is_voided', false),
    pg_catalog.jsonb_build_object(
      'is_voided', true, 'voided_at', v_entry.voided_at,
      'void_reason', v_entry.void_reason
    ),
    pg_catalog.jsonb_build_object('source', 'expense_ledger')
  );

  RETURN v_entry;
END;
$function$;

REVOKE ALL ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text)
  TO authenticated;

