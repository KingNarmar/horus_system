-- Issue #232 / PC-08 - Keep Driver compensation audit semantics distinct
-- from Driver profile audit records while preserving accountant visibility.

BEGIN;

DROP POLICY IF EXISTS audit_logs_select_accountant_driver_compensation
  ON public.audit_logs;

CREATE POLICY audit_logs_select_accountant_driver_compensation
ON public.audit_logs
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY['accountant']::public.company_role[]
  )
  AND module = 'drivers'
  AND entity_type = 'driver_compensation_revision'
  AND metadata IS NOT NULL
  AND NULLIF(pg_catalog.btrim(metadata ->> 'driver_id'), '') IS NOT NULL
  AND NULLIF(
    pg_catalog.btrim(metadata ->> 'compensation_revision_id'),
    ''
  ) IS NOT NULL
  AND entity_id = metadata ->> 'compensation_revision_id'
  AND metadata ->> 'audit_event' IN (
    'driver_compensation_revision_created',
    'driver_compensation_revision_ended',
    'driver_compensation_contract_attached'
  )
  AND description = metadata ->> 'audit_event'
);

COMMIT;
