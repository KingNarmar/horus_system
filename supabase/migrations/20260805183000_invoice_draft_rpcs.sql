-- Issue #26: trusted invoice draft creation and update.
-- Client-provided snapshots and totals are never persisted directly.

BEGIN;

CREATE OR REPLACE FUNCTION private.persist_invoice_draft(
  p_company_id uuid,
  p_invoice_id uuid,
  p_customer_id uuid,
  p_trip_ids uuid[],
  p_discount_minor_units bigint,
  p_tax_rate_basis_points integer,
  p_issue_date date,
  p_due_date date,
  p_notes text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_currency_code text;
  v_fraction_digits smallint;
  v_business_timezone text;
  v_customer public.customers%ROWTYPE;
  v_old_invoice public.invoices%ROWTYPE;
  v_old_trip_ids jsonb := '[]'::jsonb;
  v_trip record;
  v_line_count integer := 0;
  v_line_amount bigint;
  v_subtotal_numeric numeric := 0;
  v_subtotal_minor_units bigint;
  v_taxable_minor_units bigint;
  v_tax_minor_units bigint;
  v_total_numeric numeric;
  v_total_minor_units bigint;
  v_normalized_notes text := NULLIF(pg_catalog.btrim(p_notes), '');
  v_saved_invoice_id uuid;
  v_is_create boolean := p_invoice_id IS NULL;
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

  IF p_trip_ids IS NULL OR pg_catalog.cardinality(p_trip_ids) = 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2624',
      MESSAGE = 'invoice_lines_required';
  END IF;

  IF pg_catalog.cardinality(p_trip_ids) <>
     (
       SELECT pg_catalog.count(DISTINCT input_trip.trip_id)
       FROM pg_catalog.unnest(p_trip_ids) AS input_trip(trip_id)
     ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2631',
      MESSAGE = 'invoice_duplicate_trips';
  END IF;

  IF p_discount_minor_units IS NULL OR p_discount_minor_units < 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2626',
      MESSAGE = 'invoice_discount_negative';
  END IF;

  IF p_tax_rate_basis_points IS NULL
     OR p_tax_rate_basis_points NOT BETWEEN 0 AND 10000 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2628',
      MESSAGE = 'invoice_tax_rate_out_of_range';
  END IF;

  IF p_issue_date IS NOT NULL
     AND p_due_date IS NOT NULL
     AND p_due_date < p_issue_date THEN
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

  SELECT customer_row.*
  INTO v_customer
  FROM public.customers customer_row
  WHERE customer_row.company_id = p_company_id
    AND customer_row.id = p_customer_id
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

  IF NOT v_is_create THEN
    SELECT invoice_row.*
    INTO v_old_invoice
    FROM public.invoices invoice_row
    WHERE invoice_row.company_id = p_company_id
      AND invoice_row.id = p_invoice_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2618',
        MESSAGE = 'invoice_not_found';
    END IF;

    IF v_old_invoice.status <> 'draft' THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2619',
        MESSAGE = 'invoice_status_transition_invalid';
    END IF;

    SELECT COALESCE(
      pg_catalog.jsonb_agg(
        line_row.trip_id
        ORDER BY line_row.line_position
      ),
      '[]'::jsonb
    )
    INTO v_old_trip_ids
    FROM public.invoice_lines line_row
    WHERE line_row.company_id = p_company_id
      AND line_row.invoice_id = p_invoice_id;
  END IF;

  FOR v_trip IN
    SELECT
      requested_trip.line_position::integer AS line_position,
      trip_row.*
    FROM pg_catalog.unnest(p_trip_ids) WITH ORDINALITY
      AS requested_trip(trip_id, line_position)
    JOIN public.trips trip_row
      ON trip_row.id = requested_trip.trip_id
     AND trip_row.company_id = p_company_id
    ORDER BY requested_trip.line_position
    FOR UPDATE OF trip_row
  LOOP
    v_line_count := v_line_count + 1;

    IF v_trip.customer_id <> p_customer_id THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2632',
        MESSAGE = 'invoice_customer_mismatch';
    END IF;

    IF v_trip.status <> 'documents_received' THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2616',
        MESSAGE = 'invoice_trip_not_billable';
    END IF;

    IF v_trip.invoice_id IS NOT NULL THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2617',
        MESSAGE = 'invoice_trip_already_invoiced';
    END IF;

    v_line_amount := private.invoice_freight_to_minor_units(
      v_trip.freight_price,
      v_fraction_digits
    );
    v_subtotal_numeric := v_subtotal_numeric + v_line_amount;
  END LOOP;

  IF v_line_count <> pg_catalog.cardinality(p_trip_ids) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2615',
      MESSAGE = 'invoice_trip_not_found';
  END IF;

  IF v_subtotal_numeric > 9223372036854775807::numeric THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2621',
      MESSAGE = 'invoice_freight_precision_invalid';
  END IF;

  v_subtotal_minor_units := v_subtotal_numeric::bigint;

  IF p_discount_minor_units > v_subtotal_minor_units THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2627',
      MESSAGE = 'invoice_discount_exceeds_subtotal';
  END IF;

  v_taxable_minor_units :=
    v_subtotal_minor_units - p_discount_minor_units;
  v_tax_minor_units := private.invoice_tax_minor_units(
    v_taxable_minor_units,
    p_tax_rate_basis_points
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

  IF v_is_create THEN
    INSERT INTO public.invoices (
      company_id,
      customer_id,
      status,
      currency_code,
      customer_name,
      customer_tax_registration_number,
      customer_address,
      customer_city,
      customer_country,
      subtotal_minor_units,
      discount_minor_units,
      taxable_minor_units,
      tax_rate_basis_points,
      tax_minor_units,
      total_minor_units,
      issue_date,
      due_date,
      notes,
      created_by,
      updated_by
    )
    VALUES (
      p_company_id,
      p_customer_id,
      'draft',
      v_currency_code,
      v_customer.name,
      v_customer.tax_registration_number,
      v_customer.address,
      v_customer.city,
      v_customer.country,
      v_subtotal_minor_units,
      p_discount_minor_units,
      v_taxable_minor_units,
      p_tax_rate_basis_points,
      v_tax_minor_units,
      v_total_minor_units,
      p_issue_date,
      p_due_date,
      v_normalized_notes,
      v_actor_user_id,
      v_actor_user_id
    )
    RETURNING id INTO v_saved_invoice_id;
  ELSE
    v_saved_invoice_id := p_invoice_id;

    DELETE FROM public.invoice_lines line_row
    WHERE line_row.company_id = p_company_id
      AND line_row.invoice_id = p_invoice_id;

    UPDATE public.invoices
    SET
      customer_id = p_customer_id,
      currency_code = v_currency_code,
      customer_name = v_customer.name,
      customer_tax_registration_number =
        v_customer.tax_registration_number,
      customer_address = v_customer.address,
      customer_city = v_customer.city,
      customer_country = v_customer.country,
      subtotal_minor_units = v_subtotal_minor_units,
      discount_minor_units = p_discount_minor_units,
      taxable_minor_units = v_taxable_minor_units,
      tax_rate_basis_points = p_tax_rate_basis_points,
      tax_minor_units = v_tax_minor_units,
      total_minor_units = v_total_minor_units,
      issue_date = p_issue_date,
      due_date = p_due_date,
      notes = v_normalized_notes,
      updated_by = v_actor_user_id,
      updated_at = pg_catalog.now()
    WHERE company_id = p_company_id
      AND id = p_invoice_id;
  END IF;

  INSERT INTO public.invoice_lines (
    company_id,
    invoice_id,
    trip_id,
    line_position,
    loading_order_number,
    waybill_number,
    service_date,
    quantity_tons,
    amount_minor_units,
    currency_code
  )
  SELECT
    p_company_id,
    v_saved_invoice_id,
    trip_row.id,
    requested_trip.line_position::integer,
    trip_row.loading_order_number,
    trip_row.waybill_number,
    (
      COALESCE(
        trip_row.actual_delivery_at,
        trip_row.scheduled_delivery_at
      ) AT TIME ZONE v_business_timezone
    )::date,
    trip_row.quantity_tons,
    private.invoice_freight_to_minor_units(
      trip_row.freight_price,
      v_fraction_digits
    ),
    v_currency_code
  FROM pg_catalog.unnest(p_trip_ids) WITH ORDINALITY
    AS requested_trip(trip_id, line_position)
  JOIN public.trips trip_row
    ON trip_row.id = requested_trip.trip_id
   AND trip_row.company_id = p_company_id
  ORDER BY requested_trip.line_position;

  PERFORM private.write_invoice_audit_event(
    p_company_id,
    'invoices',
    'invoice',
    v_saved_invoice_id::text,
    v_saved_invoice_id::text,
    CASE WHEN v_is_create THEN 'created' ELSE 'updated' END,
    CASE WHEN v_is_create THEN 'invoice_created' ELSE 'invoice_updated' END,
    CASE
      WHEN v_is_create THEN '{}'::jsonb
      ELSE pg_catalog.jsonb_build_object(
        'customer_id', v_old_invoice.customer_id,
        'currency_code', v_old_invoice.currency_code,
        'trip_ids', v_old_trip_ids,
        'subtotal_minor_units', v_old_invoice.subtotal_minor_units,
        'discount_minor_units', v_old_invoice.discount_minor_units,
        'tax_rate_basis_points', v_old_invoice.tax_rate_basis_points,
        'tax_minor_units', v_old_invoice.tax_minor_units,
        'total_minor_units', v_old_invoice.total_minor_units,
        'issue_date', v_old_invoice.issue_date,
        'due_date', v_old_invoice.due_date,
        'notes', v_old_invoice.notes
      )
    END,
    pg_catalog.jsonb_build_object(
      'customer_id', p_customer_id,
      'currency_code', v_currency_code,
      'trip_ids', pg_catalog.to_jsonb(p_trip_ids),
      'subtotal_minor_units', v_subtotal_minor_units,
      'discount_minor_units', p_discount_minor_units,
      'tax_rate_basis_points', p_tax_rate_basis_points,
      'tax_minor_units', v_tax_minor_units,
      'total_minor_units', v_total_minor_units,
      'issue_date', p_issue_date,
      'due_date', p_due_date,
      'notes', v_normalized_notes
    )
  );

  RETURN v_saved_invoice_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_invoice_draft(
  p_company_id uuid,
  p_customer_id uuid,
  p_trip_ids uuid[],
  p_discount_minor_units bigint,
  p_tax_rate_basis_points integer,
  p_issue_date date,
  p_due_date date,
  p_notes text
)
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT private.persist_invoice_draft(
    p_company_id,
    NULL,
    p_customer_id,
    p_trip_ids,
    p_discount_minor_units,
    p_tax_rate_basis_points,
    p_issue_date,
    p_due_date,
    p_notes
  );
$$;

CREATE OR REPLACE FUNCTION public.update_invoice_draft(
  p_company_id uuid,
  p_invoice_id uuid,
  p_customer_id uuid,
  p_trip_ids uuid[],
  p_discount_minor_units bigint,
  p_tax_rate_basis_points integer,
  p_issue_date date,
  p_due_date date,
  p_notes text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
  IF p_invoice_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2618',
      MESSAGE = 'invoice_not_found';
  END IF;

  RETURN private.persist_invoice_draft(
    p_company_id,
    p_invoice_id,
    p_customer_id,
    p_trip_ids,
    p_discount_minor_units,
    p_tax_rate_basis_points,
    p_issue_date,
    p_due_date,
    p_notes
  );
END;
$$;

REVOKE ALL ON FUNCTION private.persist_invoice_draft(
  uuid,
  uuid,
  uuid,
  uuid[],
  bigint,
  integer,
  date,
  date,
  text
) FROM PUBLIC;

REVOKE ALL ON FUNCTION public.create_invoice_draft(
  uuid,
  uuid,
  uuid[],
  bigint,
  integer,
  date,
  date,
  text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_invoice_draft(
  uuid,
  uuid,
  uuid[],
  bigint,
  integer,
  date,
  date,
  text
) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_invoice_draft(
  uuid,
  uuid,
  uuid[],
  bigint,
  integer,
  date,
  date,
  text
) TO authenticated;

REVOKE ALL ON FUNCTION public.update_invoice_draft(
  uuid,
  uuid,
  uuid,
  uuid[],
  bigint,
  integer,
  date,
  date,
  text
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_invoice_draft(
  uuid,
  uuid,
  uuid,
  uuid[],
  bigint,
  integer,
  date,
  date,
  text
) FROM anon;
GRANT EXECUTE ON FUNCTION public.update_invoice_draft(
  uuid,
  uuid,
  uuid,
  uuid[],
  bigint,
  integer,
  date,
  date,
  text
) TO authenticated;

COMMIT;
