-- PC-06: retire the legacy Trip Expense write/taxonomy path.
--
-- After this migration:
-- - expense_ledger_entries is the only active Trip Expense financial source.
-- - trip_expenses is archival only and is not accessible to authenticated users.
-- - canonical ledger rows preserve a description snapshot for historical display.
-- - reports/dashboard read Trip Expense financials from the canonical ledger.
-- - legacy Company Expense coexistence remains intact for its later retirement issue.

BEGIN;

LOCK TABLE public.trip_expenses IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.expense_ledger_entries IN SHARE ROW EXCLUSIVE MODE;
LOCK TABLE public.expense_types IN SHARE ROW EXCLUSIVE MODE;

ALTER TABLE public.expense_ledger_entries
  ADD COLUMN description text;

DO $preflight$
DECLARE
  v_legacy_count bigint;
  v_projection_count bigint;
BEGIN
  SELECT count(*) INTO v_legacy_count
  FROM public.trip_expenses;

  SELECT count(*) INTO v_projection_count
  FROM public.expense_ledger_entries
  WHERE origin_kind::text = 'legacy_trip_expense';

  IF v_legacy_count <> v_projection_count THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'pc06_legacy_trip_expense_projection_count_mismatch';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.trip_expenses AS legacy_row
    LEFT JOIN public.expense_ledger_entries AS ledger_row
      ON ledger_row.company_id = legacy_row.company_id
     AND ledger_row.origin_kind::text = 'legacy_trip_expense'
     AND ledger_row.origin_id = legacy_row.id
    WHERE ledger_row.id IS NULL
       OR ledger_row.trip_id IS DISTINCT FROM legacy_row.trip_id
       OR ledger_row.expense_date IS DISTINCT FROM legacy_row.expense_date
       OR ledger_row.funding_source::text IS DISTINCT FROM legacy_row.paid_by::text
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'pc06_legacy_trip_expense_projection_mismatch';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.trip_expenses
    WHERE nullif(pg_catalog.btrim(expense_name), '') IS NULL
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'pc06_legacy_trip_expense_description_missing';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.expense_ledger_entries AS ledger_row
    JOIN public.companies AS company_row
      ON company_row.id = ledger_row.company_id
    WHERE ledger_row.currency_code IS DISTINCT FROM company_row.base_currency_code
       OR ledger_row.currency_fraction_digits IS DISTINCT FROM company_row.base_currency_fraction_digits
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'pc06_expense_ledger_currency_snapshot_mismatch';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.expense_ledger_entries AS ledger_row
    JOIN public.expense_types AS type_row
      ON type_row.company_id = ledger_row.company_id
     AND type_row.id = ledger_row.expense_type_id
    WHERE ledger_row.origin_kind::text = 'manual'
      AND type_row.code = 'other'
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'pc06_unrecoverable_manual_other_description';
  END IF;
END;
$preflight$;

-- Preserve the legacy Trip Expense business description exactly on its canonical
-- projection. Existing manual non-Other entries, if any, can safely snapshot the
-- current canonical type name. Other requires an explicit description going forward.
UPDATE public.expense_ledger_entries AS ledger_row
SET description = nullif(pg_catalog.btrim(legacy_row.expense_name), '')
FROM public.trip_expenses AS legacy_row
WHERE ledger_row.company_id = legacy_row.company_id
  AND ledger_row.origin_kind::text = 'legacy_trip_expense'
  AND ledger_row.origin_id = legacy_row.id;

UPDATE public.expense_ledger_entries AS ledger_row
SET description = nullif(pg_catalog.btrim(type_row.name), '')
FROM public.expense_types AS type_row
WHERE ledger_row.company_id = type_row.company_id
  AND ledger_row.expense_type_id = type_row.id
  AND ledger_row.origin_kind::text = 'manual'
  AND type_row.code IS DISTINCT FROM 'other'
  AND ledger_row.description IS NULL;

-- The RPC signature changes because description is a first-class canonical field.
-- Drop the old overload so PostgREST never sees two create contracts.
DROP FUNCTION public.create_expense_ledger_entry(
  uuid, uuid, bigint, text, integer, date, text,
  uuid, uuid, uuid, uuid, text, text
);

CREATE FUNCTION public.create_expense_ledger_entry(
  p_company_id uuid,
  p_expense_type_id uuid,
  p_amount_minor_units bigint,
  p_currency_code text,
  p_currency_fraction_digits integer,
  p_expense_date date,
  p_funding_source text DEFAULT 'company',
  p_trip_id uuid DEFAULT NULL,
  p_driver_id uuid DEFAULT NULL,
  p_tractor_head_id uuid DEFAULT NULL,
  p_trailer_id uuid DEFAULT NULL,
  p_description text DEFAULT NULL,
  p_reference_number text DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS public.expense_ledger_entries
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_company public.companies%ROWTYPE;
  v_expense_type public.expense_types%ROWTYPE;
  v_entry public.expense_ledger_entries%ROWTYPE;
  v_currency_code text := pg_catalog.upper(pg_catalog.btrim(p_currency_code));
  v_description text := nullif(pg_catalog.btrim(p_description), '');
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  IF p_trip_id IS NULL THEN
    IF NOT private.has_company_role(
      p_company_id,
      ARRAY['owner', 'admin', 'accountant']::public.company_role[]
    ) THEN
      RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
    END IF;
  ELSE
    IF NOT private.has_company_role(
      p_company_id,
      ARRAY['owner', 'admin', 'operations', 'accountant']::public.company_role[]
    ) THEN
      RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
    END IF;
  END IF;

  IF p_trip_id IS NOT NULL
     AND (p_driver_id IS NOT NULL OR p_tractor_head_id IS NOT NULL OR p_trailer_id IS NOT NULL) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2802', MESSAGE = 'expense_ledger_attribution_invalid';
  END IF;

  IF p_amount_minor_units IS NULL OR p_amount_minor_units <= 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P2808', MESSAGE = 'expense_ledger_amount_invalid';
  END IF;

  IF p_funding_source IS NULL
     OR p_funding_source NOT IN ('company', 'driver_advance', 'driver_cash', 'customer', 'other') THEN
    RAISE EXCEPTION USING ERRCODE = 'P2809', MESSAGE = 'expense_ledger_funding_source_invalid';
  END IF;

  SELECT company_row.*
  INTO v_company
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2806', MESSAGE = 'expense_ledger_company_not_found';
  END IF;

  IF v_company.base_currency_code IS NULL
     OR v_company.base_currency_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2804', MESSAGE = 'expense_ledger_financial_configuration_required';
  END IF;

  IF v_currency_code IS DISTINCT FROM v_company.base_currency_code
     OR p_currency_fraction_digits IS DISTINCT FROM v_company.base_currency_fraction_digits THEN
    RAISE EXCEPTION USING ERRCODE = 'P2805', MESSAGE = 'expense_ledger_currency_mismatch';
  END IF;

  SELECT expense_type_row.*
  INTO v_expense_type
  FROM public.expense_types AS expense_type_row
  WHERE expense_type_row.company_id = p_company_id
    AND expense_type_row.id = p_expense_type_id;

  IF NOT FOUND
     OR v_expense_type.is_active = false
     OR v_expense_type.ledger_eligible = false THEN
    RAISE EXCEPTION USING ERRCODE = 'P2803', MESSAGE = 'expense_ledger_expense_type_unavailable';
  END IF;

  IF v_description IS NULL THEN
    IF v_expense_type.code = 'other' THEN
      RAISE EXCEPTION USING ERRCODE = 'P2810', MESSAGE = 'expense_ledger_description_required';
    END IF;
    v_description := nullif(pg_catalog.btrim(v_expense_type.name), '');
  END IF;

  INSERT INTO public.expense_ledger_entries (
    company_id,
    expense_type_id,
    amount_minor_units,
    currency_code,
    currency_fraction_digits,
    expense_date,
    funding_source,
    trip_id,
    driver_id,
    tractor_head_id,
    trailer_id,
    description,
    reference_number,
    notes,
    origin_kind,
    created_by
  )
  VALUES (
    p_company_id,
    p_expense_type_id,
    p_amount_minor_units,
    v_currency_code,
    p_currency_fraction_digits,
    p_expense_date,
    p_funding_source,
    p_trip_id,
    p_driver_id,
    p_tractor_head_id,
    p_trailer_id,
    v_description,
    nullif(pg_catalog.btrim(p_reference_number), ''),
    nullif(pg_catalog.btrim(p_notes), ''),
    'manual',
    v_actor_user_id
  )
  RETURNING * INTO v_entry;

  PERFORM private.write_audit_event(
    p_company_id,
    'expenses',
    'expense_ledger_entry',
    v_entry.id::text,
    v_expense_type.name,
    'created',
    'expense_ledger_entry_created',
    NULL,
    pg_catalog.jsonb_build_object(
      'expense_type_id', v_entry.expense_type_id,
      'description', v_entry.description,
      'amount_minor_units', v_entry.amount_minor_units,
      'currency_code', v_entry.currency_code,
      'currency_fraction_digits', v_entry.currency_fraction_digits,
      'expense_date', v_entry.expense_date,
      'funding_source', v_entry.funding_source,
      'trip_id', v_entry.trip_id,
      'driver_id', v_entry.driver_id,
      'tractor_head_id', v_entry.tractor_head_id,
      'trailer_id', v_entry.trailer_id,
      'reference_number', v_entry.reference_number,
      'notes', v_entry.notes
    ),
    pg_catalog.jsonb_build_object('source', 'expense_ledger')
  );

  RETURN v_entry;
END;
$function$;

REVOKE ALL ON FUNCTION public.create_expense_ledger_entry(
  uuid, uuid, bigint, text, integer, date, text,
  uuid, uuid, uuid, uuid, text, text, text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_expense_ledger_entry(
  uuid, uuid, bigint, text, integer, date, text,
  uuid, uuid, uuid, uuid, text, text, text
) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_expense_ledger_entry(
  uuid, uuid, bigint, text, integer, date, text,
  uuid, uuid, uuid, uuid, text, text, text
) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.void_expense_ledger_entry(
  p_company_id uuid,
  p_expense_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS public.expense_ledger_entries
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_entry public.expense_ledger_entries%ROWTYPE;
  v_expense_type_name text;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'operations', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  SELECT entry_row.*
  INTO v_entry
  FROM public.expense_ledger_entries AS entry_row
  WHERE entry_row.company_id = p_company_id
    AND entry_row.id = p_expense_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2806', MESSAGE = 'expense_ledger_not_found';
  END IF;

  IF v_entry.origin_kind::text NOT IN ('manual', 'legacy_trip_expense') THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  IF v_entry.trip_id IS NULL
     AND NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2801', MESSAGE = 'expense_ledger_permission_denied';
  END IF;

  IF v_entry.is_voided THEN
    RAISE EXCEPTION USING ERRCODE = 'P2807', MESSAGE = 'expense_ledger_already_voided';
  END IF;

  SELECT type_row.name
  INTO v_expense_type_name
  FROM public.expense_types AS type_row
  WHERE type_row.company_id = p_company_id
    AND type_row.id = v_entry.expense_type_id;

  UPDATE public.expense_ledger_entries
  SET
    is_voided = true,
    voided_at = pg_catalog.now(),
    voided_by = v_actor_user_id,
    void_reason = nullif(pg_catalog.btrim(p_reason), ''),
    updated_by = v_actor_user_id
  WHERE company_id = p_company_id
    AND id = p_expense_id
  RETURNING * INTO v_entry;

  PERFORM private.write_audit_event(
    p_company_id,
    'expenses',
    'expense_ledger_entry',
    v_entry.id::text,
    v_expense_type_name,
    'voided',
    'expense_ledger_entry_voided',
    pg_catalog.jsonb_build_object('is_voided', false),
    pg_catalog.jsonb_build_object(
      'is_voided', true,
      'voided_at', v_entry.voided_at,
      'void_reason', v_entry.void_reason
    ),
    pg_catalog.jsonb_build_object('source', 'expense_ledger')
  );

  RETURN v_entry;
END;
$function$;

REVOKE ALL ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.void_expense_ledger_entry(uuid, uuid, text)
TO authenticated, service_role;

CREATE OR REPLACE FUNCTION private.company_has_currency_bound_financial_data(
  p_company_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  RETURN
    EXISTS (
      SELECT 1 FROM public.expense_ledger_entries AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1 FROM public.company_expenses AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1 FROM public.driver_financial_movements AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1 FROM public.driver_advances AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1 FROM public.driver_deductions AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1 FROM public.driver_settlements AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1 FROM public.driver_settlement_items AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1 FROM public.invoices AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1 FROM public.invoice_lines AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1 FROM public.payments AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.trips AS row
      WHERE row.company_id = p_company_id
        AND (
          coalesce(row.freight_price, 0::numeric) <> 0
          OR coalesce(row.total_expenses, 0::numeric) <> 0
        )
    )
    OR EXISTS (
      SELECT 1 FROM public.routes AS row
      WHERE row.company_id = p_company_id
        AND coalesce(row.default_freight_price, 0::numeric) <> 0
    )
    OR EXISTS (
      SELECT 1 FROM public.customers AS row
      WHERE row.company_id = p_company_id
        AND coalesce(row.credit_limit, 0::numeric) <> 0
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dashboard_source(p_company_id uuid)
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
  v_minor_factor numeric;
  v_today_trips bigint;
  v_running_trips bigint;
  v_delivered_trips bigint;
  v_available_vehicles bigint;
  v_vehicles_on_trip bigint;
  v_unpaid_invoices bigint;
  v_revenue_minor_units bigint;
  v_trip_expenses_minor_units bigint;
  v_company_expenses_amount numeric;
  v_company_expenses_minor_units bigint;
  v_invoice_currency_mismatch_count bigint;
  v_payment_currency_mismatch_count bigint;
  v_expense_precision_loss_count bigint := 0;
  v_negative_expense_count bigint := 0;
  v_invalid_invoice_balance_count bigint;
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
           'operations'::public.company_role,
           'accountant'::public.company_role,
           'viewer'::public.company_role
         )
     ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2910', MESSAGE = 'dashboard_permission_denied';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    company_row.business_timezone
  INTO v_currency_code, v_fraction_digits, v_business_timezone
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2911', MESSAGE = 'dashboard_company_not_found';
  END IF;

  IF v_currency_code IS NULL OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2913', MESSAGE = 'dashboard_financial_settings_not_configured';
  END IF;

  IF v_business_timezone IS NULL OR pg_catalog.btrim(v_business_timezone) = '' THEN
    RAISE EXCEPTION USING ERRCODE = 'P2912', MESSAGE = 'dashboard_business_timezone_not_configured';
  END IF;

  v_business_date := (CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone)::date;
  v_minor_factor := pg_catalog.power(10::numeric, v_fraction_digits);

  SELECT pg_catalog.count(*) INTO v_today_trips
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND coalesce(
      (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
      (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
      trip_row.trip_date
    ) = v_business_date;

  SELECT pg_catalog.count(*) INTO v_running_trips
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.status = 'on_road'::public.trip_status;

  SELECT pg_catalog.count(*) INTO v_delivered_trips
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.status IN (
      'delivered'::public.trip_status,
      'documents_received'::public.trip_status,
      'invoiced'::public.trip_status,
      'paid'::public.trip_status
    );

  SELECT pg_catalog.count(*) INTO v_available_vehicles
  FROM public.tractor_heads AS tractor_row
  WHERE tractor_row.company_id = p_company_id
    AND tractor_row.is_active = true
    AND tractor_row.status = 'available'::public.vehicle_status
    AND NOT EXISTS (
      SELECT 1
      FROM public.trips AS blocking_trip
      WHERE blocking_trip.company_id = p_company_id
        AND blocking_trip.tractor_head_id = tractor_row.id
        AND blocking_trip.status IN (
          'created'::public.trip_status,
          'assigned'::public.trip_status,
          'loaded'::public.trip_status,
          'on_road'::public.trip_status,
          'arrived'::public.trip_status
        )
    );

  SELECT pg_catalog.count(DISTINCT trip_row.tractor_head_id)
  INTO v_vehicles_on_trip
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND trip_row.tractor_head_id IS NOT NULL
    AND trip_row.status IN (
      'created'::public.trip_status,
      'assigned'::public.trip_status,
      'loaded'::public.trip_status,
      'on_road'::public.trip_status,
      'arrived'::public.trip_status
    );

  SELECT
    coalesce(pg_catalog.sum(invoice_row.taxable_minor_units), 0)::bigint,
    pg_catalog.count(*) FILTER (WHERE invoice_row.currency_code <> v_currency_code)
  INTO v_revenue_minor_units, v_invoice_currency_mismatch_count
  FROM public.invoices AS invoice_row
  WHERE invoice_row.company_id = p_company_id
    AND invoice_row.status IN (
      'issued'::public.invoice_status,
      'partially_paid'::public.invoice_status,
      'paid'::public.invoice_status
    );

  SELECT pg_catalog.count(*) INTO v_payment_currency_mismatch_count
  FROM public.payments AS payment_row
  WHERE payment_row.company_id = p_company_id
    AND payment_row.currency_code <> v_currency_code;

  SELECT
    coalesce(pg_catalog.sum(expense_row.amount_minor_units), 0)::bigint,
    pg_catalog.count(*) FILTER (WHERE expense_row.amount_minor_units < 0)
  INTO v_trip_expenses_minor_units, v_negative_expense_count
  FROM public.expense_ledger_entries AS expense_row
  WHERE expense_row.company_id = p_company_id
    AND expense_row.trip_id IS NOT NULL
    AND expense_row.is_voided = false
    AND expense_row.origin_kind::text IN ('manual', 'legacy_trip_expense');

  SELECT
    coalesce(pg_catalog.sum(expense_row.amount), 0),
    pg_catalog.count(*) FILTER (
      WHERE pg_catalog.round(expense_row.amount * v_minor_factor)
        IS DISTINCT FROM expense_row.amount * v_minor_factor
    ),
    v_negative_expense_count + pg_catalog.count(*) FILTER (
      WHERE expense_row.amount < 0
    )
  INTO
    v_company_expenses_amount,
    v_expense_precision_loss_count,
    v_negative_expense_count
  FROM public.company_expenses AS expense_row
  WHERE expense_row.company_id = p_company_id
    AND expense_row.is_voided = false;

  v_company_expenses_minor_units := pg_catalog.round(
    v_company_expenses_amount * v_minor_factor
  )::bigint;

  WITH payment_totals AS (
    SELECT
      payment_row.invoice_id,
      pg_catalog.sum(payment_row.amount_minor_units)::bigint AS paid_minor_units
    FROM public.payments AS payment_row
    WHERE payment_row.company_id = p_company_id
    GROUP BY payment_row.invoice_id
  ),
  invoice_balances AS (
    SELECT
      invoice_row.status,
      invoice_row.total_minor_units,
      coalesce(payment_totals.paid_minor_units, 0)::bigint AS paid_minor_units,
      (invoice_row.total_minor_units - coalesce(payment_totals.paid_minor_units, 0))::bigint
        AS remaining_minor_units
    FROM public.invoices AS invoice_row
    LEFT JOIN payment_totals ON payment_totals.invoice_id = invoice_row.id
    WHERE invoice_row.company_id = p_company_id
      AND invoice_row.status IN (
        'issued'::public.invoice_status,
        'partially_paid'::public.invoice_status,
        'paid'::public.invoice_status
      )
  )
  SELECT
    pg_catalog.count(*) FILTER (
      WHERE balance_row.status IN (
        'issued'::public.invoice_status,
        'partially_paid'::public.invoice_status
      )
      AND balance_row.remaining_minor_units > 0
    ),
    pg_catalog.count(*) FILTER (
      WHERE balance_row.paid_minor_units < 0
         OR balance_row.remaining_minor_units < 0
         OR (
           balance_row.status = 'paid'::public.invoice_status
           AND balance_row.remaining_minor_units <> 0
         )
         OR (
           balance_row.status IN (
             'issued'::public.invoice_status,
             'partially_paid'::public.invoice_status
           )
           AND balance_row.remaining_minor_units <= 0
         )
    )
  INTO v_unpaid_invoices, v_invalid_invoice_balance_count
  FROM invoice_balances AS balance_row;

  RETURN pg_catalog.jsonb_build_object(
    'company', pg_catalog.jsonb_build_object(
      'company_id', p_company_id,
      'base_currency_code', v_currency_code,
      'base_currency_fraction_digits', v_fraction_digits,
      'business_timezone', v_business_timezone,
      'business_date', v_business_date
    ),
    'metrics', pg_catalog.jsonb_build_object(
      'today_trips', v_today_trips,
      'running_trips', v_running_trips,
      'delivered_trips', v_delivered_trips,
      'available_vehicles', v_available_vehicles,
      'vehicles_on_trip', v_vehicles_on_trip,
      'unpaid_invoices', v_unpaid_invoices
    ),
    'financial', pg_catalog.jsonb_build_object(
      'revenue_minor_units', v_revenue_minor_units,
      'trip_expenses_minor_units', v_trip_expenses_minor_units,
      'company_expenses_minor_units', v_company_expenses_minor_units
    ),
    'validation', pg_catalog.jsonb_build_object(
      'financial_currency_mismatch_count',
        v_invoice_currency_mismatch_count + v_payment_currency_mismatch_count,
      'expense_precision_loss_count', v_expense_precision_loss_count,
      'negative_expense_count', v_negative_expense_count,
      'invalid_invoice_balance_count', v_invalid_invoice_balance_count
    )
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_trip_expenses_report_source(
  p_company_id uuid,
  p_from_date date,
  p_to_date date
)
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
  v_rows jsonb;
  v_precision_loss_count bigint := 0;
  v_negative_amount_count bigint;
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
    RAISE EXCEPTION USING ERRCODE = 'P3010', MESSAGE = 'reports_permission_denied';
  END IF;

  IF p_from_date IS NOT NULL AND p_to_date IS NOT NULL AND p_from_date > p_to_date THEN
    RAISE EXCEPTION USING ERRCODE = 'P3011', MESSAGE = 'reports_invalid_date_range';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    company_row.business_timezone
  INTO v_currency_code, v_fraction_digits, v_business_timezone
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P3012', MESSAGE = 'reports_company_not_found';
  END IF;

  IF v_currency_code IS NULL OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P3014', MESSAGE = 'reports_financial_settings_not_configured';
  END IF;

  IF v_business_timezone IS NULL OR pg_catalog.btrim(v_business_timezone) = '' THEN
    RAISE EXCEPTION USING ERRCODE = 'P3013', MESSAGE = 'reports_business_timezone_not_configured';
  END IF;

  v_business_date := (CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone)::date;

  SELECT pg_catalog.count(*) FILTER (WHERE expense_row.amount_minor_units < 0)
  INTO v_negative_amount_count
  FROM public.expense_ledger_entries AS expense_row
  WHERE expense_row.company_id = p_company_id
    AND expense_row.trip_id IS NOT NULL
    AND expense_row.is_voided = false
    AND expense_row.origin_kind::text IN ('manual', 'legacy_trip_expense')
    AND (p_from_date IS NULL OR expense_row.expense_date >= p_from_date)
    AND (p_to_date IS NULL OR expense_row.expense_date <= p_to_date);

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'expense_id', report_row.expense_id,
        'expense_date', report_row.expense_date,
        'trip_id', report_row.trip_id,
        'trip_number', report_row.trip_number,
        'trip_date', report_row.trip_date,
        'customer_id', report_row.customer_id,
        'customer_name', report_row.customer_name,
        'loading_location', report_row.loading_location,
        'unloading_location', report_row.unloading_location,
        'loading_order_number', report_row.loading_order_number,
        'waybill_number', report_row.waybill_number,
        'expense_type_id', report_row.expense_type_id,
        'expense_name', report_row.expense_name,
        'paid_by', report_row.paid_by,
        'amount_minor_units', report_row.amount_minor_units
      )
      ORDER BY report_row.expense_date DESC, report_row.created_at DESC, report_row.expense_id
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM (
    SELECT
      CASE
        WHEN expense_row.origin_kind::text = 'legacy_trip_expense'
          THEN expense_row.origin_id
        ELSE expense_row.id
      END AS expense_id,
      expense_row.expense_date,
      trip_row.id AS trip_id,
      trip_row.trip_number,
      trip_row.trip_date,
      customer_row.id AS customer_id,
      customer_row.name AS customer_name,
      route_row.loading_location,
      route_row.unloading_location,
      trip_row.loading_order_number,
      trip_row.waybill_number,
      expense_row.expense_type_id,
      coalesce(expense_row.description, type_row.name) AS expense_name,
      expense_row.funding_source::text AS paid_by,
      expense_row.amount_minor_units,
      expense_row.created_at
    FROM public.expense_ledger_entries AS expense_row
    INNER JOIN public.expense_types AS type_row
      ON type_row.company_id = expense_row.company_id
     AND type_row.id = expense_row.expense_type_id
    INNER JOIN public.trips AS trip_row
      ON trip_row.company_id = expense_row.company_id
     AND trip_row.id = expense_row.trip_id
    INNER JOIN public.customers AS customer_row
      ON customer_row.company_id = trip_row.company_id
     AND customer_row.id = trip_row.customer_id
    INNER JOIN public.routes AS route_row
      ON route_row.company_id = trip_row.company_id
     AND route_row.id = trip_row.route_id
    WHERE expense_row.company_id = p_company_id
      AND expense_row.trip_id IS NOT NULL
      AND expense_row.is_voided = false
      AND expense_row.origin_kind::text IN ('manual', 'legacy_trip_expense')
      AND (p_from_date IS NULL OR expense_row.expense_date >= p_from_date)
      AND (p_to_date IS NULL OR expense_row.expense_date <= p_to_date)
  ) AS report_row;

  RETURN pg_catalog.jsonb_build_object(
    'company', pg_catalog.jsonb_build_object(
      'company_id', p_company_id,
      'base_currency_code', v_currency_code,
      'base_currency_fraction_digits', v_fraction_digits,
      'business_timezone', v_business_timezone,
      'business_date', v_business_date
    ),
    'period', pg_catalog.jsonb_build_object(
      'from_date', p_from_date,
      'to_date', p_to_date
    ),
    'validation', pg_catalog.jsonb_build_object(
      'precision_loss_count', v_precision_loss_count,
      'negative_amount_count', v_negative_amount_count
    ),
    'rows', v_rows
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_trip_net_profit_report_source(
  p_company_id uuid,
  p_from_date date,
  p_to_date date
)
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
  v_minor_factor numeric;
  v_trips jsonb;
  v_expenses jsonb;
  v_freight_precision_loss_count bigint;
  v_negative_freight_count bigint;
  v_expense_precision_loss_count bigint := 0;
  v_negative_expense_count bigint;
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
    RAISE EXCEPTION USING ERRCODE = 'P3010', MESSAGE = 'reports_permission_denied';
  END IF;

  IF p_from_date IS NOT NULL AND p_to_date IS NOT NULL AND p_from_date > p_to_date THEN
    RAISE EXCEPTION USING ERRCODE = 'P3011', MESSAGE = 'reports_invalid_date_range';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    company_row.business_timezone
  INTO v_currency_code, v_fraction_digits, v_business_timezone
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P3012', MESSAGE = 'reports_company_not_found';
  END IF;

  IF v_currency_code IS NULL OR v_fraction_digits IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P3014', MESSAGE = 'reports_financial_settings_not_configured';
  END IF;

  IF v_business_timezone IS NULL OR pg_catalog.btrim(v_business_timezone) = '' THEN
    RAISE EXCEPTION USING ERRCODE = 'P3013', MESSAGE = 'reports_business_timezone_not_configured';
  END IF;

  v_business_date := (CURRENT_TIMESTAMP AT TIME ZONE v_business_timezone)::date;
  v_minor_factor := pg_catalog.power(10::numeric, v_fraction_digits);

  SELECT
    pg_catalog.count(*) FILTER (
      WHERE pg_catalog.round(coalesce(trip_row.freight_price, 0::numeric) * v_minor_factor)
        IS DISTINCT FROM coalesce(trip_row.freight_price, 0::numeric) * v_minor_factor
    ),
    pg_catalog.count(*) FILTER (WHERE coalesce(trip_row.freight_price, 0::numeric) < 0)
  INTO v_freight_precision_loss_count, v_negative_freight_count
  FROM public.trips AS trip_row
  WHERE trip_row.company_id = p_company_id
    AND (
      p_from_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) >= p_from_date
    )
    AND (
      p_to_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) <= p_to_date
    );

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'trip_id', report_row.trip_id,
        'trip_number', report_row.trip_number,
        'operational_date', report_row.operational_date,
        'status', report_row.status,
        'customer_id', report_row.customer_id,
        'customer_name', report_row.customer_name,
        'driver_id', report_row.driver_id,
        'driver_name', report_row.driver_name,
        'tractor_head_id', report_row.tractor_head_id,
        'tractor_head_plate_number', report_row.tractor_head_plate_number,
        'trailer_id', report_row.trailer_id,
        'trailer_plate_number', report_row.trailer_plate_number,
        'loading_location', report_row.loading_location,
        'unloading_location', report_row.unloading_location,
        'loading_order_number', report_row.loading_order_number,
        'waybill_number', report_row.waybill_number,
        'freight_minor_units', report_row.freight_minor_units
      )
      ORDER BY report_row.operational_date DESC, report_row.created_at DESC, report_row.trip_id
    ),
    '[]'::jsonb
  )
  INTO v_trips
  FROM (
    SELECT
      trip_row.id AS trip_id,
      trip_row.trip_number,
      coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) AS operational_date,
      trip_row.status::text AS status,
      customer_row.id AS customer_id,
      customer_row.name AS customer_name,
      driver_row.id AS driver_id,
      driver_row.name AS driver_name,
      tractor_row.id AS tractor_head_id,
      tractor_row.plate_number AS tractor_head_plate_number,
      trailer_row.id AS trailer_id,
      trailer_row.plate_number AS trailer_plate_number,
      route_row.loading_location,
      route_row.unloading_location,
      trip_row.loading_order_number,
      trip_row.waybill_number,
      pg_catalog.round(coalesce(trip_row.freight_price, 0::numeric) * v_minor_factor)::bigint
        AS freight_minor_units,
      trip_row.created_at
    FROM public.trips AS trip_row
    INNER JOIN public.customers AS customer_row
      ON customer_row.company_id = trip_row.company_id
     AND customer_row.id = trip_row.customer_id
    INNER JOIN public.routes AS route_row
      ON route_row.company_id = trip_row.company_id
     AND route_row.id = trip_row.route_id
    LEFT JOIN public.drivers AS driver_row
      ON driver_row.company_id = trip_row.company_id
     AND driver_row.id = trip_row.driver_id
    LEFT JOIN public.tractor_heads AS tractor_row
      ON tractor_row.company_id = trip_row.company_id
     AND tractor_row.id = trip_row.tractor_head_id
    LEFT JOIN public.trailers AS trailer_row
      ON trailer_row.company_id = trip_row.company_id
     AND trailer_row.id = trip_row.trailer_id
    WHERE trip_row.company_id = p_company_id
      AND (
        p_from_date IS NULL
        OR coalesce(
          (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
          (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
          trip_row.trip_date
        ) >= p_from_date
      )
      AND (
        p_to_date IS NULL
        OR coalesce(
          (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
          (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
          trip_row.trip_date
        ) <= p_to_date
      )
  ) AS report_row;

  SELECT pg_catalog.count(*) FILTER (WHERE expense_row.amount_minor_units < 0)
  INTO v_negative_expense_count
  FROM public.expense_ledger_entries AS expense_row
  INNER JOIN public.trips AS trip_row
    ON trip_row.company_id = expense_row.company_id
   AND trip_row.id = expense_row.trip_id
  WHERE expense_row.company_id = p_company_id
    AND expense_row.trip_id IS NOT NULL
    AND expense_row.is_voided = false
    AND (
      p_from_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) >= p_from_date
    )
    AND (
      p_to_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) <= p_to_date
    );

  SELECT coalesce(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'expense_id', CASE
          WHEN expense_row.origin_kind::text = 'legacy_trip_expense'
            THEN expense_row.origin_id
          ELSE expense_row.id
        END,
        'trip_id', expense_row.trip_id,
        'amount_minor_units', expense_row.amount_minor_units
      )
      ORDER BY expense_row.trip_id, expense_row.created_at, expense_row.id
    ),
    '[]'::jsonb
  )
  INTO v_expenses
  FROM public.expense_ledger_entries AS expense_row
  INNER JOIN public.trips AS trip_row
    ON trip_row.company_id = expense_row.company_id
   AND trip_row.id = expense_row.trip_id
  WHERE expense_row.company_id = p_company_id
    AND expense_row.trip_id IS NOT NULL
    AND expense_row.is_voided = false
    AND (
      p_from_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) >= p_from_date
    )
    AND (
      p_to_date IS NULL
      OR coalesce(
        (trip_row.actual_loading_at AT TIME ZONE v_business_timezone)::date,
        (trip_row.scheduled_loading_at AT TIME ZONE v_business_timezone)::date,
        trip_row.trip_date
      ) <= p_to_date
    );

  RETURN pg_catalog.jsonb_build_object(
    'company', pg_catalog.jsonb_build_object(
      'company_id', p_company_id,
      'base_currency_code', v_currency_code,
      'base_currency_fraction_digits', v_fraction_digits,
      'business_timezone', v_business_timezone,
      'business_date', v_business_date
    ),
    'period', pg_catalog.jsonb_build_object(
      'from_date', p_from_date,
      'to_date', p_to_date
    ),
    'validation', pg_catalog.jsonb_build_object(
      'freight_precision_loss_count', v_freight_precision_loss_count,
      'negative_freight_count', v_negative_freight_count,
      'expense_precision_loss_count', v_expense_precision_loss_count,
      'negative_expense_count', v_negative_expense_count
    ),
    'trips', v_trips,
    'expenses', v_expenses
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_dashboard_source(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_dashboard_source(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_dashboard_source(uuid) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_trip_expenses_report_source(uuid, date, date) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_trip_expenses_report_source(uuid, date, date) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_trip_expenses_report_source(uuid, date, date)
TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_trip_net_profit_report_source(uuid, date, date) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_trip_net_profit_report_source(uuid, date, date) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_trip_net_profit_report_source(uuid, date, date)
TO authenticated, service_role;

-- Retire the one-way legacy projection only after every active reader has been moved.
DROP TRIGGER IF EXISTS trip_expenses_sync_canonical_ledger ON public.trip_expenses;
DROP FUNCTION IF EXISTS private.sync_legacy_trip_expense_to_ledger();

-- trip_expenses remains as immutable archival provenance, unavailable to app users.
REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLE public.trip_expenses FROM authenticated;
DROP POLICY IF EXISTS trip_expenses_select ON public.trip_expenses;
DROP POLICY IF EXISTS trip_expenses_insert ON public.trip_expenses;
DROP POLICY IF EXISTS trip_expenses_update ON public.trip_expenses;

-- Canonical taxonomy codes are system-owned. Custom type creation is retired;
-- name/status lifecycle remains available through the existing update policy.
REVOKE INSERT ON TABLE public.expense_types FROM authenticated;
DROP POLICY IF EXISTS expense_types_insert_scoped ON public.expense_types;

COMMIT;
