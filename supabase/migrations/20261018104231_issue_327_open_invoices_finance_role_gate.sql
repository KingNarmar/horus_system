-- #327: Open Invoices exposes monetary invoice/payment balances.
-- Reject non-finance company roles in SQL, before reading a report source.
-- Preserve existing invoker mode, filters, response model and failure code.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_open_invoices_report_source(p_company_id uuid, p_from_date date, p_to_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_currency_code text;
  v_fraction_digits smallint;
  v_business_timezone text;
  v_business_date date;
  v_invoices jsonb;
  v_payments jsonb;
  v_invoice_currency_mismatch_count bigint;
  v_payment_currency_mismatch_count bigint;
  v_invalid_invoice_amount_count bigint;
  v_invalid_payment_amount_count bigint;
  v_missing_issue_date_count bigint;
BEGIN
  IF auth.uid() IS NULL
     OR NOT EXISTS (
       SELECT 1
       FROM public.company_users AS membership_row
       WHERE membership_row.company_id = p_company_id
         AND membership_row.user_id = auth.uid()
         AND membership_row.is_active = true
         AND membership_row.role IN (
           'owner'::public.company_role,
           'admin'::public.company_role,
           'accountant'::public.company_role
         )
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3010',
      MESSAGE = 'reports_permission_denied';
  END IF;

  IF p_from_date IS NOT NULL
     AND p_to_date IS NOT NULL
     AND p_from_date > p_to_date THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3011',
      MESSAGE = 'reports_invalid_date_range';
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
      ERRCODE = 'P3012',
      MESSAGE = 'reports_company_not_found';
  END IF;

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3014',
      MESSAGE = 'reports_financial_settings_not_configured';
  END IF;

  IF v_business_timezone IS NULL
     OR pg_catalog.btrim(v_business_timezone) = '' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P3013',
      MESSAGE = 'reports_business_timezone_not_configured';
  END IF;

  v_business_date := (
    CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone
  )::date;

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE invoice_row.currency_code <> v_currency_code
    ),
    pg_catalog.count(*) FILTER (
      WHERE invoice_row.total_minor_units < 0
    ),
    pg_catalog.count(*) FILTER (
      WHERE invoice_row.issue_date IS NULL
    )
  INTO
    v_invoice_currency_mismatch_count,
    v_invalid_invoice_amount_count,
    v_missing_issue_date_count
  FROM public.invoices AS invoice_row
  WHERE invoice_row.company_id = p_company_id
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
    );

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'invoice_id', invoice_row.id,
        'invoice_number', invoice_row.invoice_number,
        'customer_id', invoice_row.customer_id,
        'customer_name', invoice_row.customer_name,
        'status', invoice_row.status::text,
        'currency_code', invoice_row.currency_code,
        'total_minor_units', invoice_row.total_minor_units,
        'issue_date', invoice_row.issue_date,
        'due_date', invoice_row.due_date,
        'issued_at', invoice_row.issued_at
      )
      ORDER BY
        invoice_row.issue_date DESC NULLS LAST,
        invoice_row.issued_at DESC NULLS LAST,
        invoice_row.id
    ),
    '[]'::jsonb
  )
  INTO v_invoices
  FROM public.invoices AS invoice_row
  WHERE invoice_row.company_id = p_company_id
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
    );

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE payment_row.currency_code <> v_currency_code
    ),
    pg_catalog.count(*) FILTER (
      WHERE payment_row.amount_minor_units <= 0
    )
  INTO
    v_payment_currency_mismatch_count,
    v_invalid_payment_amount_count
  FROM public.payments AS payment_row
  INNER JOIN public.invoices AS invoice_row
    ON invoice_row.company_id = payment_row.company_id
   AND invoice_row.id = payment_row.invoice_id
  WHERE invoice_row.company_id = p_company_id
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
    );

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'payment_id', payment_row.id,
        'invoice_id', payment_row.invoice_id,
        'currency_code', payment_row.currency_code,
        'amount_minor_units', payment_row.amount_minor_units,
        'payment_date', payment_row.payment_date,
        'created_at', payment_row.created_at
      )
      ORDER BY
        payment_row.invoice_id,
        payment_row.payment_date,
        payment_row.created_at,
        payment_row.id
    ),
    '[]'::jsonb
  )
  INTO v_payments
  FROM public.payments AS payment_row
  INNER JOIN public.invoices AS invoice_row
    ON invoice_row.company_id = payment_row.company_id
   AND invoice_row.id = payment_row.invoice_id
  WHERE invoice_row.company_id = p_company_id
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
    );

  RETURN pg_catalog.jsonb_build_object(
    'company',
    pg_catalog.jsonb_build_object(
      'company_id', p_company_id,
      'base_currency_code', v_currency_code,
      'base_currency_fraction_digits', v_fraction_digits,
      'business_timezone', v_business_timezone,
      'business_date', v_business_date
    ),
    'period',
    pg_catalog.jsonb_build_object(
      'from_date', p_from_date,
      'to_date', p_to_date
    ),
    'validation',
    pg_catalog.jsonb_build_object(
      'invoice_currency_mismatch_count', v_invoice_currency_mismatch_count,
      'payment_currency_mismatch_count', v_payment_currency_mismatch_count,
      'invalid_invoice_amount_count', v_invalid_invoice_amount_count,
      'invalid_payment_amount_count', v_invalid_payment_amount_count,
      'missing_issue_date_count', v_missing_issue_date_count
    ),
    'invoices', v_invoices,
    'payments', v_payments
  );
END;
$function$;

COMMIT;
