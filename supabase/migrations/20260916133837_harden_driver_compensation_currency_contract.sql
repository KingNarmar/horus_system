-- Issue #232 / PC-08 - Enforce company currency contract for Driver compensation.

BEGIN;

DROP POLICY IF EXISTS driver_compensation_revisions_insert_managers
  ON public.driver_compensation_revisions;

CREATE POLICY driver_compensation_revisions_insert_managers
ON public.driver_compensation_revisions
FOR INSERT
TO authenticated
WITH CHECK (
  private.has_company_role(
    company_id,
    ARRAY['owner', 'admin']::public.company_role[]
  )
  AND EXISTS (
    SELECT 1
    FROM public.companies AS company_row
    WHERE company_row.id = driver_compensation_revisions.company_id
      AND company_row.base_currency_code =
        driver_compensation_revisions.currency_code
      AND company_row.base_currency_fraction_digits =
        driver_compensation_revisions.currency_fraction_digits
  )
);

COMMIT;
