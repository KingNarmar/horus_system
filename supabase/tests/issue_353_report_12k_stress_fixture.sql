-- #353 12,000-record load extension for disposable local Supabase ONLY.
-- Prerequisite: issue_353_report_large_sources_fixture.sql (1,300 rows).
-- NEVER run against hosted Development or Production.
\set ON_ERROR_STOP on
BEGIN;

-- Preserve all real quota triggers; raise only the disposable test entitlement.
UPDATE public.subscription_plans
SET max_trips_per_month = 20000
WHERE code = 'ci_report_load';

UPDATE private.entitlement_policy_versions
SET limits = pg_catalog.jsonb_set(
    pg_catalog.jsonb_set(limits, '{lifetime_trips}', '20000'::jsonb),
    '{lifetime_invoices}', '20000'::jsonb
  )
WHERE plan_id = (SELECT id FROM public.subscription_plans
                 WHERE code = 'ci_report_load')
  AND version = 1;

-- Continue the exact deterministic IDs/dates/amounts from the 1,300 fixture,
-- keeping the second tenant's 23 records untouched. No triggers disabled.
INSERT INTO public.trips (
 id,company_id,customer_id,route_id,trip_date,
 loading_location,unloading_location,freight_price,quantity_tons,status
)
SELECT md5('a-trip-'||i)::uuid,
 '11111111-1111-4111-8111-111111111111'::uuid,
 '11111111-1111-4111-8111-111111111112'::uuid,
 '11111111-1111-4111-8111-111111111113'::uuid,
 (date '2026-11-01' + ((i - 1) % 13)),'Origin A','Destination A',500.00,10,'created'::public.trip_status
FROM generate_series(1301,12000) AS i;

INSERT INTO public.expense_ledger_entries (
 id, company_id, expense_type_id, amount_minor_units,
 currency_code,currency_fraction_digits,expense_date,trip_id,
 funding_source,origin_kind,description
)
SELECT md5('a-expense-'||i)::uuid,
 '11111111-1111-4111-8111-111111111111'::uuid,
 '11111111-1111-4111-8111-111111111114'::uuid,
 12345,'AED',2,(date '2026-11-01' + ((i - 1) % 13)),md5('a-trip-'||i)::uuid,
 'company','manual','Fixture expense'
FROM generate_series(1301,12000) AS i;

INSERT INTO public.invoices (
 id,company_id,customer_id,status,invoice_number,currency_code,customer_name,
 subtotal_minor_units,discount_minor_units,taxable_minor_units,tax_rate_basis_points,
 tax_minor_units,total_minor_units,issue_date,due_date,issued_at,issued_by,
 issuer_company_name,issuer_snapshot_source,issuer_captured_at
)
SELECT md5('a-invoice-'||i)::uuid,
 '11111111-1111-4111-8111-111111111111'::uuid,
 '11111111-1111-4111-8111-111111111112'::uuid,
 'issued'::public.invoice_status,
 'INV-2026-'||lpad(i::text,6,'0'),
 'AED','Fixture Customer A',
 20000,0,20000,0,0,20000,(date '2026-11-01' + ((i - 1) % 13)),date '2026-12-15',
 timestamp with time zone '2026-11-15 12:00:00+00',
 (SELECT id FROM auth.users WHERE email='horus353.owner.a@example.invalid'),
 'Report Fixture A','issuance',timestamp with time zone '2026-11-15 12:00:00+00'
FROM generate_series(1301,12000) AS i;

INSERT INTO public.payments (
 id,company_id,invoice_id,customer_id,payment_method_id,payment_date,
 amount_minor_units,currency_code,created_by
)
SELECT md5('a-payment-'||i)::uuid,
 '11111111-1111-4111-8111-111111111111'::uuid,md5('a-invoice-'||i)::uuid,
 '11111111-1111-4111-8111-111111111112'::uuid,
 '11111111-1111-4111-8111-111111111115'::uuid,date '2026-11-15',
 5000,'AED',(SELECT id FROM auth.users WHERE email='horus353.owner.a@example.invalid')
FROM generate_series(1301,12000) AS i;

COMMIT;
