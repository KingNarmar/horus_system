-- H.O.R.U.S System — Issue #27 Payments module
-- Atomic company-scoped payment registration and invoice/trip lifecycle update.

BEGIN;

CREATE OR REPLACE FUNCTION public.register_payment(
  p_company_id uuid,
  p_invoice_id uuid,
  p_payment_method_id uuid,
  p_payment_date date,
  p_amount_minor_units bigint,
  p_currency_code text,
  p_reference_number text DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS public.payments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role text;
  v_actor_display_name text;
  v_actor_email text;
  v_business_timezone text;
  v_business_date date;
  v_invoice public.invoices%ROWTYPE;
  v_payment_method public.payment_methods%ROWTYPE;
  v_payment public.payments%ROWTYPE;
  v_reference_number text := NULLIF(pg_catalog.btrim(p_reference_number), '');
  v_notes text := NULLIF(pg_catalog.btrim(p_notes), '');
  v_currency_code text := pg_catalog.upper(NULLIF(pg_catalog.btrim(p_currency_code), ''));
  v_paid_numeric numeric := 0;
  v_paid_minor_units bigint := 0;
  v_remaining_minor_units bigint;
  v_new_paid_minor_units bigint;
  v_new_status public.invoice_status;
  v_trip record;
  v_line_count integer := 0;
  v_updated_trip_count integer := 0;
BEGIN
  IF v_actor_user_id IS NULL
     OR NOT private.has_company_role(
       p_company_id,
       ARRAY['owner', 'admin', 'accountant']::public.company_role[]
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2710',
      MESSAGE = 'payment_permission_denied';
  END IF;

  IF p_invoice_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2711',
      MESSAGE = 'payment_invoice_not_found';
  END IF;

  IF p_payment_method_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2726',
      MESSAGE = 'payment_method_required';
  END IF;

  IF p_amount_minor_units IS NULL OR p_amount_minor_units <= 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2713',
      MESSAGE = 'payment_amount_not_positive';
  END IF;

  IF v_currency_code IS NULL OR v_currency_code !~ '^[A-Z]{3}$' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2727',
      MESSAGE = 'payment_currency_required';
  END IF;

  IF p_payment_date IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2717',
      MESSAGE = 'payment_date_required';
  END IF;

  SELECT company_row.business_timezone
  INTO v_business_timezone
  FROM public.companies company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2724',
      MESSAGE = 'payment_company_not_found';
  END IF;

  IF v_business_timezone IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2725',
      MESSAGE = 'payment_company_regional_settings_not_configured';
  END IF;

  v_business_date :=
    (pg_catalog.now() AT TIME ZONE v_business_timezone)::date;

  SELECT invoice_row.*
  INTO v_invoice
  FROM public.invoices invoice_row
  WHERE invoice_row.company_id = p_company_id
    AND invoice_row.id = p_invoice_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2711',
      MESSAGE = 'payment_invoice_not_found';
  END IF;

  IF v_invoice.status NOT IN ('issued', 'partially_paid') THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2712',
      MESSAGE = 'payment_invoice_status_invalid';
  END IF;

  IF v_invoice.currency_code <> v_currency_code THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2714',
      MESSAGE = 'payment_currency_mismatch';
  END IF;

  IF p_payment_date < v_invoice.issue_date THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2718',
      MESSAGE = 'payment_date_before_invoice';
  END IF;

  IF p_payment_date > v_business_date THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2719',
      MESSAGE = 'payment_date_future';
  END IF;

  SELECT method_row.*
  INTO v_payment_method
  FROM public.payment_methods method_row
  WHERE method_row.company_id = p_company_id
    AND method_row.id = p_payment_method_id
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2715',
      MESSAGE = 'payment_method_not_found';
  END IF;

  IF NOT v_payment_method.is_active THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2716',
      MESSAGE = 'payment_method_inactive';
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

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2710',
      MESSAGE = 'payment_permission_denied';
  END IF;

  SELECT COALESCE(
    pg_catalog.sum(payment_row.amount_minor_units::numeric),
    0::numeric
  )
  INTO v_paid_numeric
  FROM public.payments payment_row
  WHERE payment_row.company_id = p_company_id
    AND payment_row.invoice_id = p_invoice_id;

  IF v_paid_numeric < 0
     OR v_paid_numeric > 9223372036854775807::numeric
     OR v_paid_numeric > v_invoice.total_minor_units::numeric THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2721',
      MESSAGE = 'payment_invoice_balance_invalid';
  END IF;

  v_paid_minor_units := v_paid_numeric::bigint;

  IF (v_invoice.status = 'issued' AND v_paid_minor_units <> 0)
     OR (
       v_invoice.status = 'partially_paid'
       AND NOT (
         v_paid_minor_units > 0
         AND v_paid_minor_units < v_invoice.total_minor_units
       )
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2721',
      MESSAGE = 'payment_invoice_balance_invalid';
  END IF;

  v_remaining_minor_units :=
    v_invoice.total_minor_units - v_paid_minor_units;

  IF p_amount_minor_units > v_remaining_minor_units THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2720',
      MESSAGE = 'payment_overpayment';
  END IF;

  v_new_paid_minor_units :=
    v_paid_minor_units + p_amount_minor_units;

  v_new_status := CASE
    WHEN v_new_paid_minor_units = v_invoice.total_minor_units
      THEN 'paid'::public.invoice_status
    ELSE 'partially_paid'::public.invoice_status
  END;

  IF v_new_status = 'paid' THEN
    -- Match the invoice lifecycle lock order to avoid cross-RPC deadlocks.
    FOR v_trip IN
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

    FOR v_trip IN
      SELECT
        trip_row.id,
        trip_row.status,
        trip_row.invoice_id
      FROM public.invoice_lines line_row
      JOIN public.trips trip_row
        ON trip_row.company_id = line_row.company_id
       AND trip_row.id = line_row.trip_id
      WHERE line_row.company_id = p_company_id
        AND line_row.invoice_id = p_invoice_id
      ORDER BY line_row.line_position
    LOOP
      v_line_count := v_line_count + 1;

      IF v_trip.status <> 'invoiced'
         OR v_trip.invoice_id IS DISTINCT FROM p_invoice_id THEN
        RAISE EXCEPTION USING
          ERRCODE = 'P2723',
          MESSAGE = 'payment_trip_state_invalid';
      END IF;
    END LOOP;

    IF v_line_count = 0 THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2722',
        MESSAGE = 'payment_invoice_lines_required';
    END IF;
  END IF;

  INSERT INTO public.payments (
    company_id,
    invoice_id,
    customer_id,
    payment_method_id,
    payment_date,
    amount_minor_units,
    currency_code,
    reference_number,
    notes,
    created_by,
    updated_by
  )
  VALUES (
    p_company_id,
    p_invoice_id,
    v_invoice.customer_id,
    p_payment_method_id,
    p_payment_date,
    p_amount_minor_units,
    v_currency_code,
    v_reference_number,
    v_notes,
    v_actor_user_id,
    v_actor_user_id
  )
  RETURNING * INTO v_payment;

  UPDATE public.invoices
  SET
    status = v_new_status,
    updated_by = v_actor_user_id,
    updated_at = pg_catalog.now()
  WHERE company_id = p_company_id
    AND id = p_invoice_id;

  IF v_new_status = 'paid' THEN
    UPDATE public.trips trip_row
    SET
      status = 'paid',
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
        ERRCODE = 'P2723',
        MESSAGE = 'payment_trip_state_invalid';
    END IF;

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
      'invoiced',
      'paid',
      v_actor_user_id,
      v_actor_display_name,
      v_actor_role,
      'invoice_paid',
      pg_catalog.now()
    FROM public.invoice_lines line_row
    WHERE line_row.company_id = p_company_id
      AND line_row.invoice_id = p_invoice_id;
  END IF;

  PERFORM private.write_audit_event(
    p_company_id,
    'payments',
    'payment',
    v_payment.id::text,
    COALESCE(v_reference_number, v_payment.id::text),
    'registered',
    'payment_registered',
    '{}'::jsonb,
    pg_catalog.jsonb_build_object(
      'invoice_id', p_invoice_id,
      'customer_id', v_invoice.customer_id,
      'payment_method_id', p_payment_method_id,
      'payment_date', p_payment_date,
      'amount_minor_units', p_amount_minor_units,
      'currency_code', v_currency_code,
      'reference_number', v_reference_number
    ),
    pg_catalog.jsonb_build_object(
      'invoice_number', v_invoice.invoice_number,
      'invoice_total_minor_units', v_invoice.total_minor_units,
      'paid_minor_units', v_new_paid_minor_units,
      'remaining_minor_units',
        v_invoice.total_minor_units - v_new_paid_minor_units
    )
  );

  PERFORM private.write_audit_event(
    p_company_id,
    'invoices',
    'invoice',
    p_invoice_id::text,
    v_invoice.invoice_number,
    'payment_status_changed',
    'invoice_payment_status_changed',
    pg_catalog.jsonb_build_object(
      'status', v_invoice.status,
      'paid_minor_units', v_paid_minor_units
    ),
    pg_catalog.jsonb_build_object(
      'status', v_new_status,
      'paid_minor_units', v_new_paid_minor_units
    ),
    pg_catalog.jsonb_build_object(
      'payment_id', v_payment.id,
      'amount_minor_units', p_amount_minor_units,
      'currency_code', v_currency_code,
      'remaining_minor_units',
        v_invoice.total_minor_units - v_new_paid_minor_units
    )
  );

  IF v_new_status = 'paid' THEN
    FOR v_trip IN
      SELECT line_row.trip_id
      FROM public.invoice_lines line_row
      WHERE line_row.company_id = p_company_id
        AND line_row.invoice_id = p_invoice_id
      ORDER BY line_row.line_position
    LOOP
      PERFORM private.write_audit_event(
        p_company_id,
        'trips',
        'trip',
        v_trip.trip_id::text,
        v_trip.trip_id::text,
        'status_changed',
        'trip_status_changed_by_invoice_payment',
        pg_catalog.jsonb_build_object(
          'status', 'invoiced',
          'invoice_id', p_invoice_id
        ),
        pg_catalog.jsonb_build_object(
          'status', 'paid',
          'invoice_id', p_invoice_id
        ),
        pg_catalog.jsonb_build_object(
          'invoice_id', p_invoice_id,
          'invoice_number', v_invoice.invoice_number,
          'payment_id', v_payment.id
        )
      );
    END LOOP;
  END IF;

  RETURN v_payment;
END;
$$;

REVOKE ALL ON FUNCTION public.register_payment(
  uuid, uuid, uuid, date, bigint, text, text, text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.register_payment(
  uuid, uuid, uuid, date, bigint, text, text, text
) FROM anon;
GRANT EXECUTE ON FUNCTION public.register_payment(
  uuid, uuid, uuid, date, bigint, text, text, text
) TO authenticated;

COMMIT;
