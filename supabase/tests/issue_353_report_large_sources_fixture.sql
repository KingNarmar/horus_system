-- Issue #353: disposable-local-only, deterministic large Reports RPC fixtures.
-- NEVER apply this to Development or Production. Used by CI local database only.
-- All identifiers and values below are synthetic. This is NOT a migration.
\set ON_ERROR_STOP on
BEGIN;

INSERT INTO public.companies (
  id, name, is_active, base_currency_code, base_currency_fraction_digits, business_timezone
) VALUES
  ('11111111-1111-4111-8111-111111111111', 'Report Fixture A', true, 'AED', 2, 'Asia/Dubai'),
  ('22222222-2222-4222-8222-222222222222', 'Report Fixture B', true, 'AED', 2, 'Asia/Dubai');

INSERT INTO public.company_users (company_id, user_id, role, is_active)
SELECT
  role_assignment.company_id::uuid,
  auth_user.id,
  role_assignment.company_role::public.company_role,
  role_assignment.active
FROM (
  VALUES
    ('11111111-1111-4111-8111-111111111111','horus353.owner.a@example.invalid','owner',true),
    ('11111111-1111-4111-8111-111111111111','horus353.accountant.a@example.invalid','accountant',true),
    ('11111111-1111-4111-8111-111111111111','horus353.operations.a@example.invalid','operations',true),
    ('11111111-1111-4111-8111-111111111111','horus353.viewer.a@example.invalid','viewer',true),
    ('11111111-1111-4111-8111-111111111111','horus353.deactivated.a@example.invalid','owner',false),
    ('22222222-2222-4222-8222-222222222222','horus353.owner.b@example.invalid','owner',true)
) AS role_assignment(company_id, email, company_role, active)
JOIN auth.users auth_user ON auth_user.email = role_assignment.email;

DO $check$
BEGIN
  IF (SELECT count(*) FROM public.company_users
      WHERE company_id IN ('11111111-1111-4111-8111-111111111111',
                           '22222222-2222-4222-8222-222222222222')) <> 6 THEN
    RAISE EXCEPTION 'Issue 353: missing signed-JWT fixture accounts';
  END IF;
END;
$check$;

INSERT INTO public.customers (id, company_id, name)
VALUES
 ('11111111-1111-4111-8111-111111111112','11111111-1111-4111-8111-111111111111','Fixture Customer A'),
 ('22222222-2222-4222-8222-222222222223','22222222-2222-4222-8222-222222222222','Fixture Customer B');

INSERT INTO public.routes (id, company_id, loading_location, unloading_location)
VALUES
 ('11111111-1111-4111-8111-111111111113','11111111-1111-4111-8111-111111111111','Origin A','Destination A'),
 ('22222222-2222-4222-8222-222222222224','22222222-2222-4222-8222-222222222222','Origin B','Destination B');

INSERT INTO public.expense_types (id, company_id, name, ledger_eligible)
VALUES
 ('11111111-1111-4111-8111-111111111114','11111111-1111-4111-8111-111111111111','Report Stress Type A',true),
 ('22222222-2222-4222-8222-222222222225','22222222-2222-4222-8222-222222222222','Report Stress Type B',true);

INSERT INTO public.payment_methods (id, company_id, name, code)
VALUES
 ('11111111-1111-4111-8111-111111111115','11111111-1111-4111-8111-111111111111','Fixture Method A','other'),
 ('22222222-2222-4222-8222-222222222226','22222222-2222-4222-8222-222222222222','Fixture Method B','other');

-- Each company has its own sequence, identifiers, currency and money rows.
-- Tenant A deliberately exceeds PostgREST's common 1,000-row table default.
INSERT INTO public.trips (
 id,company_id,trip_number,customer_id,route_id,trip_date,
 loading_location,unloading_location,freight_price,quantity_tons,status
)
SELECT md5('a-trip-'||i)::uuid,
 '11111111-1111-4111-8111-111111111111'::uuid,
 'TRP-2026-'||lpad(i::text,6,'0'),
 '11111111-1111-4111-8111-111111111112'::uuid,
 '11111111-1111-4111-8111-111111111113'::uuid,
 date '2026-11-15','Origin A','Destination A',500.00,10,'created'::public.trip_status
FROM generate_series(1,1300) AS i;

INSERT INTO public.trips (
 id,company_id,trip_number,customer_id,route_id,trip_date,
 loading_location,unloading_location,freight_price,quantity_tons,status
)
SELECT md5('b-trip-'||i)::uuid,
 '22222222-2222-4222-8222-222222222222'::uuid,
 'TRP-2026-'||lpad(i::text,6,'0'),
 '22222222-2222-4222-8222-222222222223'::uuid,
 '22222222-2222-4222-8222-222222222224'::uuid,
 date '2026-11-15','Origin B','Destination B',500.00,10,'created'::public.trip_status
FROM generate_series(1,23) AS i;

INSERT INTO public.expense_ledger_entries (
 id, company_id, expense_type_id, amount_minor_units,
 currency_code,currency_fraction_digits,expense_date,trip_id,
 funding_source,origin_kind,description
)
SELECT md5('a-expense-'||i)::uuid,
 '11111111-1111-4111-8111-111111111111'::uuid,
 '11111111-1111-4111-8111-111111111114'::uuid,
 12345,'AED',2,date '2026-11-15',md5('a-trip-'||i)::uuid,
 'company','manual','Fixture expense'
FROM generate_series(1,1300) AS i;

INSERT INTO public.expense_ledger_entries (
 id, company_id, expense_type_id, amount_minor_units,
 currency_code,currency_fraction_digits,expense_date,trip_id,
 funding_source,origin_kind,description
)
SELECT md5('b-expense-'||i)::uuid,
 '22222222-2222-4222-8222-222222222222'::uuid,
 '22222222-2222-4222-8222-222222222225'::uuid,
 12345,'AED',2,date '2026-11-15',md5('b-trip-'||i)::uuid,
 'company','manual','Fixture expense'
FROM generate_series(1,23) AS i;

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
 20000,0,20000,0,0,20000,date '2026-11-15',date '2026-12-15',
 timestamp with time zone '2026-11-15 12:00:00+00',
 (SELECT id FROM auth.users WHERE email='horus353.owner.a@example.invalid'),
 'Report Fixture A','issuance',timestamp with time zone '2026-11-15 12:00:00+00'
FROM generate_series(1,1300) AS i;

INSERT INTO public.invoices (
 id,company_id,customer_id,status,invoice_number,currency_code,customer_name,
 subtotal_minor_units,discount_minor_units,taxable_minor_units,tax_rate_basis_points,
 tax_minor_units,total_minor_units,issue_date,due_date,issued_at,issued_by,
 issuer_company_name,issuer_snapshot_source,issuer_captured_at
)
SELECT md5('b-invoice-'||i)::uuid,
 '22222222-2222-4222-8222-222222222222'::uuid,
 '22222222-2222-4222-8222-222222222223'::uuid,
 'issued'::public.invoice_status,
 'INV-2026-'||lpad(i::text,6,'0'),
 'AED','Fixture Customer B',
 20000,0,20000,0,0,20000,date '2026-11-15',date '2026-12-15',
 timestamp with time zone '2026-11-15 12:00:00+00',
 (SELECT id FROM auth.users WHERE email='horus353.owner.b@example.invalid'),
 'Report Fixture B','issuance',timestamp with time zone '2026-11-15 12:00:00+00'
FROM generate_series(1,23) AS i;

INSERT INTO public.payments (
 id,company_id,invoice_id,customer_id,payment_method_id,payment_date,
 amount_minor_units,currency_code,created_by
)
SELECT md5('a-payment-'||i)::uuid,
 '11111111-1111-4111-8111-111111111111'::uuid,md5('a-invoice-'||i)::uuid,
 '11111111-1111-4111-8111-111111111112'::uuid,
 '11111111-1111-4111-8111-111111111115'::uuid,date '2026-11-15',
 5000,'AED',(SELECT id FROM auth.users WHERE email='horus353.owner.a@example.invalid')
FROM generate_series(1,1300) AS i;

INSERT INTO public.payments (
 id,company_id,invoice_id,customer_id,payment_method_id,payment_date,
 amount_minor_units,currency_code,created_by
)
SELECT md5('b-payment-'||i)::uuid,
 '22222222-2222-4222-8222-222222222222'::uuid,md5('b-invoice-'||i)::uuid,
 '22222222-2222-4222-8222-222222222223'::uuid,
 '22222222-2222-4222-8222-222222222226'::uuid,date '2026-11-15',
 5000,'AED',(SELECT id FROM auth.users WHERE email='horus353.owner.b@example.invalid')
FROM generate_series(1,23) AS i;

COMMIT;
