-- Allow accountants to read only driver settlement audit events for their company.
-- Existing owner/admin/platform-admin audit access remains unchanged.

drop policy if exists audit_logs_select_accountant_driver_settlements
on public.audit_logs;

create policy audit_logs_select_accountant_driver_settlements
on public.audit_logs
for select
to authenticated
using (
  private.has_company_role(
    company_id,
    array['accountant'::public.company_role]
  )
  and module = 'drivers'
  and entity_type = 'driver'
  and metadata is not null
  and nullif(btrim(metadata ->> 'settlement_id'), '') is not null
  and entity_id = metadata ->> 'driver_id'
  and metadata ->> 'audit_event' in (
    'driver_settlement_created',
    'driver_settlement_finalized',
    'driver_settlement_voided'
  )
  and description = metadata ->> 'audit_event'
);
