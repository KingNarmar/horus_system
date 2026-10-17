-- Issue #327 — finance-only rows and ledger mutations (Development first).
-- Operations/Viewer retain operational Trips access; no Trip/Route price grants change here.
BEGIN;

DROP POLICY IF EXISTS company_expenses_select_company_members ON public.company_expenses;
CREATE POLICY company_expenses_select_finance_roles
ON public.company_expenses FOR SELECT TO authenticated
USING (private.has_company_role(company_id, ARRAY['owner','admin','accountant']::public.company_role[]));

DROP POLICY IF EXISTS expense_ledger_entries_select_company_roles ON public.expense_ledger_entries;
CREATE POLICY expense_ledger_entries_select_finance_roles
ON public.expense_ledger_entries FOR SELECT TO authenticated
USING (private.has_company_role(company_id, ARRAY['owner','admin','accountant']::public.company_role[]));

DROP POLICY IF EXISTS invoices_select ON public.invoices;
CREATE POLICY invoices_select_finance_roles
ON public.invoices FOR SELECT TO authenticated
USING (private.has_company_role(company_id, ARRAY['owner','admin','accountant']::public.company_role[]));

DROP POLICY IF EXISTS invoice_lines_select ON public.invoice_lines;
CREATE POLICY invoice_lines_select_finance_roles
ON public.invoice_lines FOR SELECT TO authenticated
USING (private.has_company_role(company_id, ARRAY['owner','admin','accountant']::public.company_role[]));

DROP POLICY IF EXISTS payments_select_business_roles ON public.payments;
CREATE POLICY payments_select_finance_roles
ON public.payments FOR SELECT TO authenticated
USING (private.has_company_role(company_id, ARRAY['owner','admin','accountant']::public.company_role[]));

DROP POLICY IF EXISTS driver_financial_movements_select_company_roles ON public.driver_financial_movements;
CREATE POLICY driver_financial_movements_select_finance_roles
ON public.driver_financial_movements FOR SELECT TO authenticated
USING (private.has_company_role(company_id, ARRAY['owner','admin','accountant']::public.company_role[]));

DROP POLICY IF EXISTS driver_advances_select_company_roles ON public.driver_advances;
CREATE POLICY driver_advances_select_finance_roles
ON public.driver_advances FOR SELECT TO authenticated
USING (private.has_company_role(company_id, ARRAY['owner','admin','accountant']::public.company_role[]));

DROP POLICY IF EXISTS driver_deductions_select_company_roles ON public.driver_deductions;
CREATE POLICY driver_deductions_select_finance_roles
ON public.driver_deductions FOR SELECT TO authenticated
USING (private.has_company_role(company_id, ARRAY['owner','admin','accountant']::public.company_role[]));

-- The canonical ledger's privileged create/void RPCs historically admit Operations.
-- Enforce the approved financial role matrix at the mutation boundary regardless
-- of which privileged caller writes the ledger. Audit and rollups remain atomic.
CREATE OR REPLACE FUNCTION private.enforce_finance_only_expense_ledger_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF TG_OP = 'UPDATE' AND
     NEW.company_id IS DISTINCT FROM OLD.company_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2801',
      MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  IF auth.uid() IS NOT NULL AND NOT private.has_company_role(
    NEW.company_id,
    ARRAY['owner','admin','accountant']::public.company_role[]
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2801',
      MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.enforce_finance_only_expense_ledger_mutation()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS expense_ledger_finance_write_gate
ON public.expense_ledger_entries;
CREATE TRIGGER expense_ledger_finance_write_gate
BEFORE INSERT OR UPDATE ON public.expense_ledger_entries
FOR EACH ROW
EXECUTE FUNCTION private.enforce_finance_only_expense_ledger_mutation();

COMMIT;
