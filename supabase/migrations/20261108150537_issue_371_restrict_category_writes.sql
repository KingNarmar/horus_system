-- Issue #371: Company Expense Categories are read-only in the current product.
-- Remove unused unaudited client write access. Internal trusted company
-- onboarding continues to seed default categories through its definer trigger.
BEGIN;

-- Fail closed if the expected tenant-safe baseline has changed.
DO $issue_371_preflight$
BEGIN
  IF NOT (SELECT c.relrowsecurity
          FROM pg_catalog.pg_class c
          WHERE c.oid = 'public.company_expense_categories'::regclass) THEN
    RAISE EXCEPTION 'issue_371_category_rls_required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_trigger t
    JOIN pg_catalog.pg_proc p ON p.oid = t.tgfoid
    WHERE t.tgrelid = 'public.companies'::regclass
      AND t.tgname = 'companies_seed_default_company_expense_categories'
      AND t.tgenabled <> 'D'
      AND p.proname = 'seed_default_company_expense_categories_for_company'
      AND p.prosecdef
  ) THEN
    RAISE EXCEPTION 'issue_371_trusted_category_seed_required';
  END IF;
END;
$issue_371_preflight$;

-- Do not rely on frontend-only restrictions or tenant RLS as a substitute
-- for removing an unused write capability.
REVOKE INSERT, UPDATE
ON TABLE public.company_expense_categories
FROM authenticated;

DROP POLICY IF EXISTS company_expense_categories_insert_finance_roles
ON public.company_expense_categories;

DROP POLICY IF EXISTS company_expense_categories_update_finance_roles
ON public.company_expense_categories;

-- Verify all columns, not just table-level grants. Preserve SELECT and RLS.
DO $issue_371_postflight$
BEGIN
  IF pg_catalog.has_table_privilege(
       'authenticated', 'public.company_expense_categories', 'INSERT'
     )
     OR pg_catalog.has_table_privilege(
       'authenticated', 'public.company_expense_categories', 'UPDATE'
     )
     OR EXISTS (
       SELECT 1
       FROM pg_catalog.pg_attribute a
       WHERE a.attrelid = 'public.company_expense_categories'::regclass
         AND a.attnum > 0
         AND NOT a.attisdropped
         AND (
           pg_catalog.has_column_privilege(
             'authenticated', a.attrelid, a.attname, 'INSERT'
           )
           OR pg_catalog.has_column_privilege(
             'authenticated', a.attrelid, a.attname, 'UPDATE'
           )
         )
     ) THEN
    RAISE EXCEPTION 'issue_371_category_write_access_still_exposed';
  END IF;

  IF NOT pg_catalog.has_table_privilege(
       'authenticated', 'public.company_expense_categories', 'SELECT'
     )
     OR NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_policies
       WHERE schemaname = 'public'
         AND tablename = 'company_expense_categories'
         AND policyname = 'company_expense_categories_select_company_members'
         AND cmd = 'SELECT'
     ) THEN
    RAISE EXCEPTION 'issue_371_category_read_access_missing';
  END IF;
END;
$issue_371_postflight$;

COMMIT;
