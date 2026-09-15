-- PC-06: retire the final obsolete Expense Type mutation policy.
-- Expense Types are a read-only canonical taxonomy in the application.
-- authenticated retains SELECT only; removing this inert UPDATE policy keeps
-- the database authorization surface aligned with the retired mutation path.

DROP POLICY IF EXISTS expense_types_update_accounting
ON public.expense_types;
