-- H.O.R.U.S System — Issue #337: follow-up on the already applied
-- Development migration 20261022173301.
-- Keep finalized settlement snapshots complete with captured Trip Expense
-- provenance; historical finalized rows remain unchanged.
-- No table/column changes and no trigger recreation.

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

