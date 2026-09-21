-- H.O.R.U.S System — Issue #244
-- Make business-sensitive lifecycle timestamps server-authoritative and
-- protect historical Driver Settlement transitions from client tampering.

BEGIN;

CREATE OR REPLACE FUNCTION private.guard_company_expense_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.'
      USING ERRCODE = '42501';
  END IF;

  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.company_id IS DISTINCT FROM OLD.company_id
     OR NEW.created_by IS DISTINCT FROM OLD.created_by
     OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'Company expense identity and creation metadata are immutable.'
      USING ERRCODE = '23514';
  END IF;

  IF OLD.is_voided THEN
    RAISE EXCEPTION 'Voided company expenses are immutable.'
      USING ERRCODE = '23514';
  END IF;

  NEW.updated_by := v_actor_user_id;

  IF NEW.is_voided THEN
    IF ROW(
      NEW.category_id,
      NEW.driver_id,
      NEW.tractor_head_id,
      NEW.trailer_id,
      NEW.trip_id,
      NEW.amount,
      NEW.expense_date,
      NEW.reference_number,
      NEW.notes
    ) IS DISTINCT FROM ROW(
      OLD.category_id,
      OLD.driver_id,
      OLD.tractor_head_id,
      OLD.trailer_id,
      OLD.trip_id,
      OLD.amount,
      OLD.expense_date,
      OLD.reference_number,
      OLD.notes
    ) THEN
      RAISE EXCEPTION 'Company expense values cannot change while voiding.'
        USING ERRCODE = '23514';
    END IF;

    NEW.voided_at := pg_catalog.now();
    NEW.voided_by := v_actor_user_id;
  ELSE
    IF NEW.voided_at IS DISTINCT FROM OLD.voided_at
       OR NEW.voided_by IS DISTINCT FROM OLD.voided_by
       OR NEW.void_reason IS DISTINCT FROM OLD.void_reason THEN
      RAISE EXCEPTION 'Company expense void metadata is server-owned.'
        USING ERRCODE = '23514';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL
ON FUNCTION private.guard_company_expense_update()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS company_expenses_guard_update
ON public.company_expenses;

CREATE TRIGGER company_expenses_guard_update
BEFORE UPDATE ON public.company_expenses
FOR EACH ROW
EXECUTE FUNCTION private.guard_company_expense_update();

CREATE OR REPLACE FUNCTION private.guard_driver_settlement_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication is required.'
      USING ERRCODE = '42501';
  END IF;

  IF ROW(
    NEW.id,
    NEW.company_id,
    NEW.driver_id,
    NEW.period_start,
    NEW.period_end,
    NEW.compensation_revision_id,
    NEW.currency_code,
    NEW.currency_fraction_digits,
    NEW.opening_driver_balance,
    NEW.opening_driver_balance_minor_units,
    NEW.advances_total,
    NEW.advances_total_minor_units,
    NEW.driver_paid_trip_expenses_total,
    NEW.driver_paid_trip_expenses_total_minor_units,
    NEW.returned_cash_total,
    NEW.returned_cash_total_minor_units,
    NEW.deductions_total,
    NEW.deductions_total_minor_units,
    NEW.settlement_deductions_total,
    NEW.settlement_deductions_total_minor_units,
    NEW.gross_salary,
    NEW.gross_salary_minor_units,
    NEW.salary_deductions_total,
    NEW.salary_deductions_total_minor_units,
    NEW.balance_deduction_applied,
    NEW.balance_deduction_applied_minor_units,
    NEW.net_salary_payable,
    NEW.net_salary_payable_minor_units,
    NEW.closing_driver_balance,
    NEW.closing_driver_balance_minor_units,
    NEW.notes,
    NEW.created_by,
    NEW.created_at
  ) IS DISTINCT FROM ROW(
    OLD.id,
    OLD.company_id,
    OLD.driver_id,
    OLD.period_start,
    OLD.period_end,
    OLD.compensation_revision_id,
    OLD.currency_code,
    OLD.currency_fraction_digits,
    OLD.opening_driver_balance,
    OLD.opening_driver_balance_minor_units,
    OLD.advances_total,
    OLD.advances_total_minor_units,
    OLD.driver_paid_trip_expenses_total,
    OLD.driver_paid_trip_expenses_total_minor_units,
    OLD.returned_cash_total,
    OLD.returned_cash_total_minor_units,
    OLD.deductions_total,
    OLD.deductions_total_minor_units,
    OLD.settlement_deductions_total,
    OLD.settlement_deductions_total_minor_units,
    OLD.gross_salary,
    OLD.gross_salary_minor_units,
    OLD.salary_deductions_total,
    OLD.salary_deductions_total_minor_units,
    OLD.balance_deduction_applied,
    OLD.balance_deduction_applied_minor_units,
    OLD.net_salary_payable,
    OLD.net_salary_payable_minor_units,
    OLD.closing_driver_balance,
    OLD.closing_driver_balance_minor_units,
    OLD.notes,
    OLD.created_by,
    OLD.created_at
  ) THEN
    RAISE EXCEPTION 'Driver settlement snapshot is immutable after creation.'
      USING ERRCODE = '23514';
  END IF;

  IF OLD.status = 'voided'::public.driver_settlement_status THEN
    RAISE EXCEPTION 'Voided driver settlements are immutable.'
      USING ERRCODE = '23514';
  END IF;

  IF OLD.status = 'draft'::public.driver_settlement_status
     AND NEW.status = 'finalized'::public.driver_settlement_status THEN
    NEW.finalized_at := pg_catalog.now();
    NEW.finalized_by := v_actor_user_id;
    NEW.voided_at := NULL;
    NEW.voided_by := NULL;
    NEW.void_reason := NULL;
  ELSIF OLD.status IN (
      'draft'::public.driver_settlement_status,
      'finalized'::public.driver_settlement_status
    )
    AND NEW.status = 'voided'::public.driver_settlement_status THEN
    IF NEW.void_reason IS NULL
       OR pg_catalog.length(pg_catalog.btrim(NEW.void_reason)) = 0 THEN
      RAISE EXCEPTION 'Driver settlement void reason is required.'
        USING ERRCODE = '23514';
    END IF;

    IF OLD.status = 'finalized'::public.driver_settlement_status THEN
      NEW.finalized_at := OLD.finalized_at;
      NEW.finalized_by := OLD.finalized_by;
    ELSE
      NEW.finalized_at := NULL;
      NEW.finalized_by := NULL;
    END IF;

    NEW.void_reason := pg_catalog.btrim(NEW.void_reason);
    NEW.voided_at := pg_catalog.now();
    NEW.voided_by := v_actor_user_id;
  ELSE
    RAISE EXCEPTION 'Driver settlement status transition is invalid.'
      USING ERRCODE = '23514';
  END IF;

  NEW.updated_by := v_actor_user_id;
  RETURN NEW;
END;
$function$;

REVOKE ALL
ON FUNCTION private.guard_driver_settlement_update()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS driver_settlements_guard_update
ON public.driver_settlements;

CREATE TRIGGER driver_settlements_guard_update
BEFORE UPDATE ON public.driver_settlements
FOR EACH ROW
EXECUTE FUNCTION private.guard_driver_settlement_update();

COMMENT ON FUNCTION private.guard_company_expense_update() IS
  'Issue #244: owns Company Expense update actor/void timestamps on the server and makes voided rows immutable.';

COMMENT ON FUNCTION private.guard_driver_settlement_update() IS
  'Issue #244: owns Driver Settlement lifecycle timestamps/actors on the server and protects historical snapshots and status transitions.';

COMMIT;
