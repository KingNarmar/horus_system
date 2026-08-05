-- Issue #26: atomic invoice cancellation.
-- Issued trips are restored only when they still belong to the invoice.

BEGIN;

CREATE OR REPLACE FUNCTION public.cancel_invoice(
  p_company_id uuid,
  p_invoice_id uuid,
  p_reason text
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
  v_reason text := NULLIF(pg_catalog.btrim(p_reason), '');
  v_invoice public.invoices%ROWTYPE;
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
      ERRCODE = 'P2610',
      MESSAGE = 'invoice_permission_denied';
  END IF;

  IF p_invoice_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2618',
      MESSAGE = 'invoice_not_found';
  END IF;

  IF v_reason IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2623',
      MESSAGE = 'invoice_cancellation_reason_required';
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

  IF v_invoice.status NOT IN ('draft', 'issued') THEN
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

  IF v_invoice.status = 'issued' THEN
    -- Use the same deterministic trip lock order as issuance.
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
          ERRCODE = 'P2619',
          MESSAGE = 'invoice_status_transition_invalid';
      END IF;
    END LOOP;

    IF v_line_count = 0 THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P2624',
        MESSAGE = 'invoice_lines_required';
    END IF;

    UPDATE public.trips trip_row
    SET
      status = 'documents_received',
      invoice_id = NULL,
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
      'documents_received',
      v_actor_user_id,
      v_actor_display_name,
      v_actor_role,
      'invoice_cancelled',
      pg_catalog.now()
    FROM public.invoice_lines line_row
    WHERE line_row.company_id = p_company_id
      AND line_row.invoice_id = p_invoice_id;

    FOR v_trip IN
      SELECT line_row.trip_id AS id
      FROM public.invoice_lines line_row
      WHERE line_row.company_id = p_company_id
        AND line_row.invoice_id = p_invoice_id
      ORDER BY line_row.line_position
    LOOP
      PERFORM private.write_invoice_audit_event(
        p_company_id,
        'trips',
        'trip',
        v_trip.id::text,
        v_trip.id::text,
        'status_changed',
        'trip_status_changed_by_invoice_cancellation',
        pg_catalog.jsonb_build_object(
          'status', 'invoiced',
          'invoice_id', p_invoice_id
        ),
        pg_catalog.jsonb_build_object(
          'status', 'documents_received',
          'invoice_id', NULL
        ),
        pg_catalog.jsonb_build_object('invoice_id', p_invoice_id)
      );
    END LOOP;
  END IF;

  UPDATE public.invoices
  SET
    status = 'cancelled',
    cancellation_reason = v_reason,
    cancelled_at = pg_catalog.now(),
    cancelled_by = v_actor_user_id,
    updated_by = v_actor_user_id,
    updated_at = pg_catalog.now()
  WHERE company_id = p_company_id
    AND id = p_invoice_id;

  PERFORM private.write_invoice_audit_event(
    p_company_id,
    'invoices',
    'invoice',
    p_invoice_id::text,
    COALESCE(v_invoice.invoice_number, p_invoice_id::text),
    'cancelled',
    'invoice_cancelled',
    pg_catalog.jsonb_build_object(
      'status', v_invoice.status,
      'cancellation_reason', v_invoice.cancellation_reason
    ),
    pg_catalog.jsonb_build_object(
      'status', 'cancelled',
      'cancellation_reason', v_reason
    )
  );

  RETURN p_invoice_id;
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_invoice(uuid, uuid, text)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.cancel_invoice(uuid, uuid, text)
  FROM anon;
GRANT EXECUTE ON FUNCTION public.cancel_invoice(uuid, uuid, text)
  TO authenticated;

COMMIT;
