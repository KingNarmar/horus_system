-- Issue #26: keep invoice issuance service-date validation consistent with
-- billable-trip and invoice-creation snapshot rules.

BEGIN;

CREATE OR REPLACE FUNCTION public.issue_invoice(
  p_company_id uuid,
  p_invoice_id uuid,
  p_issue_date date,
  p_due_date date
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role text;
  v_actor_display_name text;
  v_actor_email text;
  v_currency_code text;
  v_fraction_digits smallint;
  v_business_timezone text;
  v_business_date date;
  v_prefix text;
  v_invoice public.invoices%ROWTYPE;
  v_customer public.customers%ROWTYPE;
  v_line record;
  v_line_count integer := 0;
  v_current_amount bigint;
  v_current_service_date date;
  v_subtotal_numeric numeric := 0;
  v_subtotal_minor_units bigint;
  v_taxable_minor_units bigint;
  v_tax_minor_units bigint;
  v_total_numeric numeric;
  v_total_minor_units bigint;
  v_invoice_year integer;
  v_sequence_value bigint;
  v_invoice_number text;
  v_updated_trip_count integer;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2610',
      MESSAGE = 'invoice_permission_denied';
  END IF;

  IF p_invoice_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2618',
      MESSAGE = 'invoice_not_found';
  END IF;

  IF p_issue_date IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2635',
      MESSAGE = 'invoice_issue_date_required';
  END IF;

  IF p_due_date IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2636',
      MESSAGE = 'invoice_due_date_required';
  END IF;

  IF p_due_date < p_issue_date THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2622',
      MESSAGE = 'invoice_due_date_before_issue';
  END IF;

  SELECT
    company_row.base_currency_code,
    company_row.base_currency_fraction_digits,
    company_row.business_timezone
  INTO
    v_currency_code,
    v_fraction_digits,
    v_business_timezone
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2633',
      MESSAGE = 'invoice_company_not_found';
  END IF;

  IF v_currency_code IS NULL
     OR v_fraction_digits IS NULL
     OR v_business_timezone IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2611',
      MESSAGE = 'company_regional_settings_not_configured';
  END IF;

  v_business_date :=
    (pg_catalog.now() AT TIME ZONE v_business_timezone)::date;

  IF p_issue_date > v_business_date THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2630',
      MESSAGE = 'invoice_issue_date_future';
  END IF;

  SELECT invoice_row.*
  INTO v_invoice
  FROM public.invoices invoice_row
  WHERE invoice_row.company_id = p_company_id
    AND invoice_row.id = p_invoice_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2618',
      MESSAGE = 'invoice_not_found';
  END IF;

  IF v_invoice.status <> 'draft' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2619',
      MESSAGE = 'invoice_status_transition_invalid';
  END IF;

  IF v_invoice.currency_code <> v_currency_code THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2625',
      MESSAGE = 'invoice_currency_mismatch';
  END IF;

  SELECT customer_row.*
  INTO v_customer
  FROM public.customers customer_row
  WHERE customer_row.company_id = p_company_id
    AND customer_row.id = v_invoice.customer_id
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2613',
      MESSAGE = 'invoice_customer_not_found';
  END IF;

  IF NOT v_customer.is_active THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2614',
      MESSAGE = 'invoice_customer_inactive';
  END IF;

  IF v_invoice.customer_name IS DISTINCT FROM v_customer.name
     OR v_invoice.customer_tax_registration_number
        IS DISTINCT FROM v_customer.tax_registration_number
     OR v_invoice.customer_address IS DISTINCT FROM v_customer.address
     OR v_invoice.customer_city IS DISTINCT FROM v_customer.city
     OR v_invoice.customer_country IS DISTINCT FROM v_customer.country THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2637',
      MESSAGE = 'invoice_customer_snapshot_changed';
  END IF;

  -- Deterministic trip lock order prevents overlapping invoice deadlocks.
  FOR v_line IN
    SELECT trip_row.id
    FROM public.invoice_lines line_row
    JOIN public.trips trip_row
      ON trip_row.company_id = line_row.company_id
     AND trip_row.id = line_row.trip_id
    WHERE line_row.company_id = p_company_id
      AND line_row.invoice_id = p_invoice_id
    ORDER BY trip_row.id
    FOR UPDATE OF trip_row
  LOOP
    NULL;
  END LOOP;

  FOR v_line IN
    SELECT
      line_row.*,
      trip_row.customer_id AS current_customer_id,
      trip_row.status AS current_status,
      trip_row.invoice_id AS current_invoice_id,
      trip_row.loading_order_number AS current_loading_order_number,
      trip_row.waybill_number AS current_waybill_number,
      trip_row.trip_date AS current_trip_date,
      trip_row.actual_delivery_at AS current_actual_delivery_at,
      trip_row.scheduled_delivery_at AS current_scheduled_delivery_at,
      trip_row.quantity_tons AS current_quantity_tons,
      trip_row.freight_price AS current_freight_price
    FROM public.invoice_lines line_row
    JOIN public.trips trip_row
      ON trip_row.company_id = line_row.company_id
     AND trip_row.id = line_row.trip_id
    WHERE line_row.company_id = p_company_id
      AND line_row.invoice_id = p_invoice_id
    ORDER BY line_row.line_position
  LOOP
    v_line_count := v_line_count + 1;

    IF v_line.current_customer_id <> v_invoice.customer_id THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2632',
        MESSAGE = 'invoice_customer_mismatch';
    END IF;

    IF v_line.current_status <> 'documents_received' THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2616',
        MESSAGE = 'invoice_trip_not_billable';
    END IF;

    IF v_line.current_invoice_id IS NOT NULL THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2617',
        MESSAGE = 'invoice_trip_already_invoiced';
    END IF;

    v_current_amount := private.invoice_freight_to_minor_units(
      v_line.current_freight_price,
      v_fraction_digits
    );
    v_current_service_date := COALESCE(
      (
        COALESCE(
          v_line.current_actual_delivery_at,
          v_line.current_scheduled_delivery_at
        ) AT TIME ZONE v_business_timezone
      )::date,
      v_line.current_trip_date
    );

    IF v_line.loading_order_number
          IS DISTINCT FROM v_line.current_loading_order_number
       OR v_line.waybill_number
          IS DISTINCT FROM v_line.current_waybill_number
       OR v_line.service_date IS DISTINCT FROM v_current_service_date
       OR v_line.quantity_tons
          IS DISTINCT FROM v_line.current_quantity_tons
       OR v_line.amount_minor_units IS DISTINCT FROM v_current_amount
       OR v_line.currency_code IS DISTINCT FROM v_currency_code THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2638',
        MESSAGE = 'invoice_trip_snapshot_changed';
    END IF;

    v_subtotal_numeric := v_subtotal_numeric + v_current_amount;
  END LOOP;

  IF v_line_count = 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2624',
      MESSAGE = 'invoice_lines_required';
  END IF;

  IF v_subtotal_numeric > 9223372036854775807::numeric THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2621',
      MESSAGE = 'invoice_freight_precision_invalid';
  END IF;

  v_subtotal_minor_units := v_subtotal_numeric::bigint;

  IF v_invoice.discount_minor_units < 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2626',
      MESSAGE = 'invoice_discount_negative';
  END IF;

  IF v_invoice.discount_minor_units > v_subtotal_minor_units THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2627',
      MESSAGE = 'invoice_discount_exceeds_subtotal';
  END IF;

  IF v_invoice.tax_rate_basis_points NOT BETWEEN 0 AND 10000 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2628',
      MESSAGE = 'invoice_tax_rate_out_of_range';
  END IF;

  v_taxable_minor_units :=
    v_subtotal_minor_units - v_invoice.discount_minor_units;
  v_tax_minor_units := private.invoice_tax_minor_units(
    v_taxable_minor_units,
    v_invoice.tax_rate_basis_points
  );
  v_total_numeric :=
    v_taxable_minor_units::numeric + v_tax_minor_units::numeric;

  IF v_total_numeric <= 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2629',
      MESSAGE = 'invoice_total_not_positive';
  END IF;

  IF v_total_numeric > 9223372036854775807::numeric THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2621',
      MESSAGE = 'invoice_freight_precision_invalid';
  END IF;

  v_total_minor_units := v_total_numeric::bigint;

  IF v_invoice.subtotal_minor_units <> v_subtotal_minor_units
     OR v_invoice.taxable_minor_units <> v_taxable_minor_units
     OR v_invoice.tax_minor_units <> v_tax_minor_units
     OR v_invoice.total_minor_units <> v_total_minor_units THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2620',
      MESSAGE = 'invoice_totals_changed';
  END IF;

  SELECT settings_row.invoice_prefix
  INTO v_prefix
  FROM public.company_invoice_settings settings_row
  WHERE settings_row.company_id = p_company_id
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2612',
      MESSAGE = 'invoice_settings_not_configured';
  END IF;

  v_invoice_year := EXTRACT(YEAR FROM p_issue_date)::integer;

  INSERT INTO public.invoice_sequences AS sequence_row (
    company_id,
    invoice_year,
    last_value,
    updated_at
  )
  VALUES (
    p_company_id,
    v_invoice_year,
    1,
    pg_catalog.now()
  )
  ON CONFLICT (company_id, invoice_year) DO UPDATE
  SET
    last_value = sequence_row.last_value + 1,
    updated_at = pg_catalog.now()
  RETURNING last_value INTO v_sequence_value;

  IF v_sequence_value > 999999 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2639',
      MESSAGE = 'invoice_sequence_exhausted';
  END IF;

  v_invoice_number :=
    v_prefix
    || '-'
    || v_invoice_year::text
    || '-'
    || pg_catalog.lpad(v_sequence_value::text, 6, '0');

  UPDATE public.invoices
  SET
    status = 'issued',
    invoice_number = v_invoice_number,
    issue_date = p_issue_date,
    due_date = p_due_date,
    issued_at = pg_catalog.now(),
    issued_by = v_actor_user_id,
    updated_by = v_actor_user_id,
    updated_at = pg_catalog.now()
  WHERE company_id = p_company_id
    AND id = p_invoice_id;

  UPDATE public.trips trip_row
  SET
    status = 'invoiced',
    invoice_id = p_invoice_id,
    updated_by = v_actor_user_id,
    updated_at = pg_catalog.now()
  FROM public.invoice_lines line_row
  WHERE line_row.company_id = p_company_id
    AND line_row.invoice_id = p_invoice_id
    AND trip_row.company_id = line_row.company_id
    AND trip_row.id = line_row.trip_id;

  GET DIAGNOSTICS v_updated_trip_count = ROW_COUNT;
  IF v_updated_trip_count <> v_line_count THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2619',
      MESSAGE = 'invoice_status_transition_invalid';
  END IF;

  SELECT
    company_user.role::text,
    COALESCE(
      NULLIF(pg_catalog.btrim(user_profile.full_name), ''),
      auth_user.email,
      v_actor_user_id::text
    ),
    auth_user.email
  INTO
    v_actor_role,
    v_actor_display_name,
    v_actor_email
  FROM public.company_users company_user
  LEFT JOIN public.user_profiles user_profile
    ON user_profile.id = company_user.user_id
  LEFT JOIN auth.users auth_user
    ON auth_user.id = company_user.user_id
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true;

  INSERT INTO public.trip_status_history (
    company_id,
    trip_id,
    old_status,
    new_status,
    changed_by,
    changed_by_name,
    changed_by_role,
    notes,
    changed_at
  )
  SELECT
    p_company_id,
    line_row.trip_id,
    'documents_received',
    'invoiced',
    v_actor_user_id,
    v_actor_display_name,
    v_actor_role,
    'invoice_issued',
    pg_catalog.now()
  FROM public.invoice_lines line_row
  WHERE line_row.company_id = p_company_id
    AND line_row.invoice_id = p_invoice_id;

  PERFORM private.write_invoice_audit_event(
    p_company_id,
    'invoices',
    'invoice',
    p_invoice_id::text,
    v_invoice_number,
    'issued',
    'invoice_issued',
    pg_catalog.jsonb_build_object(
      'status', v_invoice.status,
      'invoice_number', v_invoice.invoice_number,
      'issue_date', v_invoice.issue_date,
      'due_date', v_invoice.due_date
    ),
    pg_catalog.jsonb_build_object(
      'status', 'issued',
      'invoice_number', v_invoice_number,
      'issue_date', p_issue_date,
      'due_date', p_due_date
    )
  );

  FOR v_line IN
    SELECT line_row.trip_id
    FROM public.invoice_lines line_row
    WHERE line_row.company_id = p_company_id
      AND line_row.invoice_id = p_invoice_id
    ORDER BY line_row.line_position
  LOOP
    PERFORM private.write_invoice_audit_event(
      p_company_id,
      'trips',
      'trip',
      v_line.trip_id::text,
      v_line.trip_id::text,
      'status_changed',
      'trip_status_changed_by_invoice_issue',
      pg_catalog.jsonb_build_object(
        'status', 'documents_received',
        'invoice_id', NULL
      ),
      pg_catalog.jsonb_build_object(
        'status', 'invoiced',
        'invoice_id', p_invoice_id
      ),
      pg_catalog.jsonb_build_object(
        'invoice_id', p_invoice_id,
        'invoice_number', v_invoice_number
      )
    );
  END LOOP;

  RETURN p_invoice_id;
END;
$$;

REVOKE ALL ON FUNCTION public.issue_invoice(uuid, uuid, date, date)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.issue_invoice(uuid, uuid, date, date)
  FROM anon;
GRANT EXECUTE ON FUNCTION public.issue_invoice(uuid, uuid, date, date)
  TO authenticated;

COMMIT;
