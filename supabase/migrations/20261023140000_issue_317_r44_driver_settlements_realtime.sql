-- Issue #317 R4.4 — REVIEW ONLY until separately approved for Development.
-- Atomic settlement draft write, finance-only private invalidation.
-- A header broadcast is enqueued in the same database transaction as its items.
BEGIN;

CREATE OR REPLACE FUNCTION public.create_driver_settlement_draft_atomic(
  p_company_id uuid,
  p_header jsonb,
  p_items jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_id uuid;
  v_item jsonb;
  v_source_type public.driver_settlement_item_source_type;
BEGIN
  IF auth.uid() IS NULL
     OR p_company_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner','admin','accountant']::public.company_role[]
     )
  THEN
    RAISE EXCEPTION USING ERRCODE = 'P2813',
      MESSAGE = 'driver_settlement_create_permission_denied';
  END IF;

  IF p_header IS NULL
     OR pg_catalog.jsonb_typeof(p_header) <> 'object'
     OR p_items IS NULL
     OR pg_catalog.jsonb_typeof(p_items) <> 'array'
     OR p_header ->> 'company_id' IS DISTINCT FROM p_company_id::text
     OR p_header ->> 'status' IS DISTINCT FROM 'draft'
     OR p_header - ARRAY['company_id', 'status', 'driver_id', 'period_start', 'period_end', 'compensation_revision_id', 'currency_code', 'currency_fraction_digits', 'opening_driver_balance', 'opening_driver_balance_minor_units', 'advances_total', 'advances_total_minor_units', 'driver_paid_trip_expenses_total', 'driver_paid_trip_expenses_total_minor_units', 'returned_cash_total', 'returned_cash_total_minor_units', 'deductions_total', 'deductions_total_minor_units', 'settlement_deductions_total', 'settlement_deductions_total_minor_units', 'gross_salary', 'gross_salary_minor_units', 'salary_deductions_total', 'salary_deductions_total_minor_units', 'balance_deduction_applied', 'balance_deduction_applied_minor_units', 'net_salary_payable', 'net_salary_payable_minor_units', 'closing_driver_balance', 'closing_driver_balance_minor_units', 'notes'] <> '{}'::jsonb
  THEN
    RAISE EXCEPTION USING ERRCODE = 'P2814',
      MESSAGE = 'driver_settlement_draft_payload_invalid';
  END IF;

  -- Explicitly selected fields; clients cannot supply id, actor or status.
  INSERT INTO public.driver_settlements (
    company_id,
    driver_id,
    period_start,
    period_end,
    compensation_revision_id,
    currency_code,
    currency_fraction_digits,
    opening_driver_balance,
    opening_driver_balance_minor_units,
    advances_total,
    advances_total_minor_units,
    driver_paid_trip_expenses_total,
    driver_paid_trip_expenses_total_minor_units,
    returned_cash_total,
    returned_cash_total_minor_units,
    deductions_total,
    deductions_total_minor_units,
    settlement_deductions_total,
    settlement_deductions_total_minor_units,
    gross_salary,
    gross_salary_minor_units,
    salary_deductions_total,
    salary_deductions_total_minor_units,
    balance_deduction_applied,
    balance_deduction_applied_minor_units,
    net_salary_payable,
    net_salary_payable_minor_units,
    closing_driver_balance,
    closing_driver_balance_minor_units,
    notes
  )
  SELECT p_company_id,
         input.driver_id,
         input.period_start,
         input.period_end,
         input.compensation_revision_id,
         input.currency_code,
         input.currency_fraction_digits,
         input.opening_driver_balance,
         input.opening_driver_balance_minor_units,
         input.advances_total,
         input.advances_total_minor_units,
         input.driver_paid_trip_expenses_total,
         input.driver_paid_trip_expenses_total_minor_units,
         input.returned_cash_total,
         input.returned_cash_total_minor_units,
         input.deductions_total,
         input.deductions_total_minor_units,
         input.settlement_deductions_total,
         input.settlement_deductions_total_minor_units,
         input.gross_salary,
         input.gross_salary_minor_units,
         input.salary_deductions_total,
         input.salary_deductions_total_minor_units,
         input.balance_deduction_applied,
         input.balance_deduction_applied_minor_units,
         input.net_salary_payable,
         input.net_salary_payable_minor_units,
         input.closing_driver_balance,
         input.closing_driver_balance_minor_units,
         input.notes
  FROM pg_catalog.jsonb_populate_record(
    NULL::public.driver_settlements, p_header
  ) AS input
  RETURNING id INTO v_id;

  FOR v_item IN SELECT value FROM pg_catalog.jsonb_array_elements(p_items)
  LOOP
    IF pg_catalog.jsonb_typeof(v_item) <> 'object'
       OR v_item ->> 'company_id' IS DISTINCT FROM p_company_id::text
       OR v_item - ARRAY[
         'company_id', 'source_type', 'source_id', 'source_date',
         'direction', 'amount', 'amount_minor_units', 'currency_code',
         'currency_fraction_digits', 'label_key', 'description_key', 'metadata'
       ] <> '{}'::jsonb
    THEN
      RAISE EXCEPTION USING ERRCODE = 'P2814',
        MESSAGE = 'driver_settlement_item_payload_invalid';
    END IF;

    -- The relation and company identifier are always server-owned.
    INSERT INTO public.driver_settlement_items (
      company_id, settlement_id, source_type, source_id, source_date,
      direction, amount, amount_minor_units, currency_code,
      currency_fraction_digits, label_key, description_key, metadata
    )
    SELECT
      p_company_id, v_id, input.source_type, input.source_id,
      input.source_date, input.direction, input.amount,
      input.amount_minor_units, input.currency_code,
      input.currency_fraction_digits, input.label_key,
      input.description_key, COALESCE(input.metadata, '{}'::jsonb)
    FROM pg_catalog.jsonb_populate_record(
      NULL::public.driver_settlement_items, v_item
    ) AS input;
  END LOOP;

  -- New snapshots with captured driver-paid expenses require provenance.
  IF EXISTS (
    SELECT 1 FROM public.driver_settlements s
    WHERE s.id = v_id AND s.company_id = p_company_id
      AND s.driver_paid_trip_expenses_total > 0
      AND NOT EXISTS (
        SELECT 1 FROM public.driver_settlement_items i
        WHERE i.company_id = s.company_id AND i.settlement_id = s.id
          AND i.source_type = 'trip_expense'
      )
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2812',
      MESSAGE = 'driver_settlement_expense_source_invalid';
  END IF;

  RETURN v_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.create_driver_settlement_draft_atomic(
  uuid, jsonb, jsonb
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_driver_settlement_draft_atomic(
  uuid, jsonb, jsonb
) TO authenticated;

-- Remove the former split-write route for browser/desktop/mobile clients.
REVOKE INSERT ON public.driver_settlements FROM PUBLIC, anon, authenticated;
REVOKE INSERT ON public.driver_settlement_items FROM PUBLIC, anon, authenticated;

CREATE POLICY horus_driver_settlements_realtime_receive
ON realtime.messages FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND private.has_company_role(
    CASE
      WHEN realtime.topic() ~
        '^horus:company:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}:driver_settlements$'
      THEN split_part(realtime.topic(), ':', 3)::uuid
      ELSE NULL::uuid
    END,
    ARRAY['owner','admin','accountant']::public.company_role[]
  )
);

CREATE FUNCTION private.broadcast_driver_settlements_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NULL;
  END IF;

  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'company_id', NEW.company_id,
      'resource', 'driver_settlements'
    ),
    'changed',
    'horus:company:' || NEW.company_id::text || ':driver_settlements',
    true
  );
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION private.broadcast_driver_settlements_invalidation()
  FROM PUBLIC, anon, authenticated;

CREATE TRIGGER driver_settlements_realtime_invalidation
AFTER INSERT OR UPDATE ON public.driver_settlements
FOR EACH ROW EXECUTE FUNCTION private.broadcast_driver_settlements_invalidation();

COMMIT;
