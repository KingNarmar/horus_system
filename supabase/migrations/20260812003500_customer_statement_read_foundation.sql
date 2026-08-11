-- H.O.R.U.S System — Issue #28 Customer Statement read foundation
--
-- Adds a customer-scoped invoice access index and a hardened read RPC that
-- returns raw statement source facts. Financial interpretation (opening net,
-- debit/credit effect, running balance, and closing balance) remains in Domain.

BEGIN;

CREATE INDEX IF NOT EXISTS invoices_company_customer_issue_date_idx
ON public.invoices (
  company_id,
  customer_id,
  issue_date,
  issued_at,
  id
)
INCLUDE (
  total_minor_units,
  currency_code,
  invoice_number
)
WHERE status IN (
  'issued'::public.invoice_status,
  'partially_paid'::public.invoice_status,
  'paid'::public.invoice_status
);

CREATE OR REPLACE FUNCTION public.get_customer_statement_source(
  p_company_id uuid,
  p_customer_id uuid,
  p_from_date date,
  p_to_date date
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
  v_business_timezone text;

  v_customer_name text;
  v_customer_is_active boolean;

  v_opening_invoices jsonb;
  v_opening_payments jsonb;
  v_movements jsonb;
BEGIN
  IF auth.uid() IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY[
         'owner',
         'admin',
         'operations',
         'accountant',
         'viewer'
       ]::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2810',
      MESSAGE = 'customer_statement_permission_denied';
  END IF;

  IF p_from_date IS NOT NULL
     AND p_to_date IS NOT NULL
     AND p_from_date > p_to_date THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2811',
      MESSAGE = 'customer_statement_invalid_date_range';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    company_row.business_timezone
  INTO
    v_currency_code,
    v_fraction_digits,
    v_business_timezone
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2812',
      MESSAGE = 'customer_statement_company_not_found';
  END IF;

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL
     OR v_business_timezone IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2813',
      MESSAGE = 'customer_statement_regional_settings_not_configured';
  END IF;

  SELECT
    customer_row.name,
    customer_row.is_active
  INTO
    v_customer_name,
    v_customer_is_active
  FROM public.customers AS customer_row
  WHERE customer_row.company_id = p_company_id
    AND customer_row.id = p_customer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2814',
      MESSAGE = 'customer_statement_customer_not_found';
  END IF;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'currency_code', opening_row.currency_code,
        'total_minor_units', opening_row.total_minor_units
      )
      ORDER BY opening_row.currency_code
    ),
    '[]'::jsonb
  )
  INTO v_opening_invoices
  FROM (
    SELECT
      invoice_row.currency_code,
      pg_catalog.sum(invoice_row.total_minor_units) AS total_minor_units
    FROM public.invoices AS invoice_row
    WHERE invoice_row.company_id = p_company_id
      AND invoice_row.customer_id = p_customer_id
      AND invoice_row.status IN (
        'issued'::public.invoice_status,
        'partially_paid'::public.invoice_status,
        'paid'::public.invoice_status
      )
      AND invoice_row.issue_date < p_from_date
    GROUP BY invoice_row.currency_code
  ) AS opening_row;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'currency_code', opening_row.currency_code,
        'total_minor_units', opening_row.total_minor_units
      )
      ORDER BY opening_row.currency_code
    ),
    '[]'::jsonb
  )
  INTO v_opening_payments
  FROM (
    SELECT
      payment_row.currency_code,
      pg_catalog.sum(payment_row.amount_minor_units) AS total_minor_units
    FROM public.payments AS payment_row
    WHERE payment_row.company_id = p_company_id
      AND payment_row.customer_id = p_customer_id
      AND payment_row.payment_date < p_from_date
    GROUP BY payment_row.currency_code
  ) AS opening_row;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'source_type', movement_row.source_type,
        'source_id', movement_row.source_id,
        'business_date', movement_row.business_date,
        'event_timestamp', movement_row.event_timestamp,
        'amount_minor_units', movement_row.amount_minor_units,
        'currency_code', movement_row.currency_code,
        'reference', movement_row.reference,
        'related_invoice_id', movement_row.related_invoice_id
      )
      ORDER BY
        movement_row.business_date,
        movement_row.event_timestamp,
        movement_row.source_type,
        movement_row.source_id
    ),
    '[]'::jsonb
  )
  INTO v_movements
  FROM (
    SELECT
      'invoice'::text AS source_type,
      invoice_row.id AS source_id,
      invoice_row.issue_date AS business_date,
      invoice_row.issued_at AS event_timestamp,
      invoice_row.total_minor_units AS amount_minor_units,
      invoice_row.currency_code,
      invoice_row.invoice_number AS reference,
      invoice_row.id AS related_invoice_id
    FROM public.invoices AS invoice_row
    WHERE invoice_row.company_id = p_company_id
      AND invoice_row.customer_id = p_customer_id
      AND invoice_row.status IN (
        'issued'::public.invoice_status,
        'partially_paid'::public.invoice_status,
        'paid'::public.invoice_status
      )
      AND (
        p_from_date IS NULL
        OR invoice_row.issue_date >= p_from_date
      )
      AND (
        p_to_date IS NULL
        OR invoice_row.issue_date <= p_to_date
      )

    UNION ALL

    SELECT
      'payment'::text AS source_type,
      payment_row.id AS source_id,
      payment_row.payment_date AS business_date,
      payment_row.created_at AS event_timestamp,
      payment_row.amount_minor_units AS amount_minor_units,
      payment_row.currency_code,
      payment_row.reference_number AS reference,
      payment_row.invoice_id AS related_invoice_id
    FROM public.payments AS payment_row
    WHERE payment_row.company_id = p_company_id
      AND payment_row.customer_id = p_customer_id
      AND (
        p_from_date IS NULL
        OR payment_row.payment_date >= p_from_date
      )
      AND (
        p_to_date IS NULL
        OR payment_row.payment_date <= p_to_date
      )
  ) AS movement_row;

  RETURN pg_catalog.jsonb_build_object(
    'company',
    pg_catalog.jsonb_build_object(
      'company_id', p_company_id,
      'base_currency_code', v_currency_code,
      'base_currency_fraction_digits', v_fraction_digits,
      'business_timezone', v_business_timezone
    ),
    'customer',
    pg_catalog.jsonb_build_object(
      'customer_id', p_customer_id,
      'customer_name', v_customer_name,
      'is_active', v_customer_is_active
    ),
    'period',
    pg_catalog.jsonb_build_object(
      'from_date', p_from_date,
      'to_date', p_to_date
    ),
    'opening',
    pg_catalog.jsonb_build_object(
      'invoices', v_opening_invoices,
      'payments', v_opening_payments
    ),
    'movements', v_movements
  );
END;
$function$;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_customer_statement_source(uuid, uuid, date, date)
FROM PUBLIC;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_customer_statement_source(uuid, uuid, date, date)
FROM anon;

REVOKE ALL PRIVILEGES
ON FUNCTION public.get_customer_statement_source(uuid, uuid, date, date)
FROM authenticated;

GRANT EXECUTE
ON FUNCTION public.get_customer_statement_source(uuid, uuid, date, date)
TO authenticated;

COMMIT;
