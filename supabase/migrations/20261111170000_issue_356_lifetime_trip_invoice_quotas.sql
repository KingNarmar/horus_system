-- Issue #356: company-scoped lifetime successful Trip and Invoice creations.
-- SOURCE ONLY. DO NOT apply to hosted Development or Production without approval.
-- PostgreSQL locking and all new records are atomic; source reviewed against #270/#355.
BEGIN;

-- Private durable history: no company FK by design, preserving creation evidence
-- across company deletion/re-creation attempts (subject to approved retention).
CREATE TABLE private.company_lifetime_creation_events (
  company_id uuid NOT NULL,
  resource text NOT NULL CHECK (resource IN ('lifetime_trips','lifetime_invoices')),
  entity_id text NOT NULL CHECK (pg_catalog.btrim(entity_id) <> ''),
  created_at timestamptz NOT NULL,
  source text NOT NULL CHECK (source IN ('record_backfill','audit_backfill','created')),
  request_id uuid,
  payload_fingerprint text,
  CONSTRAINT company_lifetime_creation_events_entity_pkey
    PRIMARY KEY (company_id, resource, entity_id),
  CONSTRAINT company_lifetime_request_pair_check
    CHECK ((request_id IS NULL AND payload_fingerprint IS NULL)
        OR (request_id IS NOT NULL AND payload_fingerprint ~ '^[0-9a-f]{64}$'))
);
CREATE UNIQUE INDEX company_lifetime_creation_events_request_uidx
  ON private.company_lifetime_creation_events(company_id, resource, request_id)
  WHERE request_id IS NOT NULL;
CREATE INDEX company_lifetime_creation_events_company_resource_idx
  ON private.company_lifetime_creation_events(company_id, resource, created_at);
ALTER TABLE private.company_lifetime_creation_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.company_lifetime_creation_events FROM PUBLIC, anon, authenticated;

CREATE TABLE private.company_lifetime_usage_counters (
  company_id uuid NOT NULL,
  resource text NOT NULL CHECK (resource IN ('lifetime_trips','lifetime_invoices')),
  used bigint NOT NULL CHECK (used >= 0),
  baseline_evidence jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  PRIMARY KEY (company_id, resource)
);
ALTER TABLE private.company_lifetime_usage_counters ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.company_lifetime_usage_counters FROM PUBLIC, anon, authenticated;

-- Reconcile actual records and trusted structured 'created' audit evidence.
-- Never fabricate individual deleted records based on sequence gaps.
WITH candidates AS (
  SELECT company_id, 'lifetime_trips'::text AS resource,
    id::text AS entity_id, created_at, 'record_backfill'::text AS source
  FROM public.trips
  UNION ALL
  SELECT company_id, 'lifetime_invoices', id::text, created_at, 'record_backfill'
  FROM public.invoices
  UNION ALL
  SELECT company_id, 'lifetime_trips', entity_id, created_at, 'audit_backfill'
  FROM public.audit_logs
  WHERE module='trips' AND entity_type='trip' AND action='created'
    AND entity_id ~ '^[0-9a-fA-F-]{36}$'
  UNION ALL
  SELECT company_id, 'lifetime_invoices', entity_id, created_at, 'audit_backfill'
  FROM public.audit_logs
  WHERE module='invoices' AND entity_type='invoice' AND action='created'
    AND entity_id ~ '^[0-9a-fA-F-]{36}$'
), distinct_events AS (
  SELECT DISTINCT ON (company_id, resource, entity_id)
    company_id, resource, entity_id, created_at, source
  FROM candidates
  ORDER BY company_id, resource, entity_id, created_at, source
)
INSERT INTO private.company_lifetime_creation_events
  (company_id,resource,entity_id,created_at,source)
SELECT company_id,resource,entity_id,created_at,source FROM distinct_events
ON CONFLICT (company_id,resource,entity_id) DO NOTHING;

-- Sequence high-water marks supply additional lower-bound evidence for deleted
-- issued invoices / trips. They are NOT synthetic creation-ledger entries.
WITH evidence AS (
 SELECT c.id AS company_id, r.resource,
   COALESCE((SELECT count(*) FROM private.company_lifetime_creation_events e
             WHERE e.company_id=c.id AND e.resource=r.resource),0)::bigint AS event_count,
   CASE r.resource
     WHEN 'lifetime_trips' THEN COALESCE((
       SELECT sum(s.last_value) FROM public.trip_sequences s
       WHERE s.company_id=c.id),0)::bigint
     ELSE COALESCE((
       SELECT sum(s.last_value) FROM public.invoice_sequences s
       WHERE s.company_id=c.id),0)::bigint
   END AS sequence_high_water
 FROM public.companies c
 CROSS JOIN (VALUES('lifetime_trips'),('lifetime_invoices')) AS r(resource)
)
INSERT INTO private.company_lifetime_usage_counters
 (company_id,resource,used,baseline_evidence)
SELECT company_id, resource,
  GREATEST(event_count, sequence_high_water),
  pg_catalog.jsonb_build_object(
    'known_created_events',event_count,
    'sequence_high_water',sequence_high_water,
    'basis','legacy_reconciliation_356')
FROM evidence
ON CONFLICT (company_id,resource) DO NOTHING;

-- Historical ledger and counters cannot be modified/deleted through routines
-- after migration; new events are appended only in the protected trigger.
CREATE FUNCTION private.reject_lifetime_history_reduction()
RETURNS trigger
LANGUAGE plpgsql
SET search_path=pg_catalog
AS $$
BEGIN
  IF TG_OP='DELETE' OR (TG_TABLE_NAME='company_lifetime_creation_events'
                       AND TG_OP='UPDATE')
    OR (TG_OP='UPDATE' AND
        (NEW.used < OLD.used OR NEW.company_id IS DISTINCT FROM OLD.company_id
         OR NEW.resource IS DISTINCT FROM OLD.resource
         OR NEW.baseline_evidence IS DISTINCT FROM OLD.baseline_evidence)) THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_lifetime_history_immutable';
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION private.reject_lifetime_history_reduction()
  FROM PUBLIC, anon, authenticated;
CREATE TRIGGER company_lifetime_creation_events_immutable
  BEFORE UPDATE OR DELETE ON private.company_lifetime_creation_events
  FOR EACH ROW EXECUTE FUNCTION private.reject_lifetime_history_reduction();
CREATE TRIGGER company_lifetime_usage_counters_monotonic
  BEFORE UPDATE OR DELETE ON private.company_lifetime_usage_counters
  FOR EACH ROW EXECUTE FUNCTION private.reject_lifetime_history_reduction();

-- Extend the same canonical entitlement reader, company lock, and usage API.
CREATE OR REPLACE FUNCTION private.company_quota_used(
  p_company_id uuid, p_resource text
)
RETURNS bigint
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_used bigint;
BEGIN
  IF p_resource = 'company_users' THEN
    SELECT
      (SELECT pg_catalog.count(*)
       FROM public.company_users member
       WHERE member.company_id=p_company_id AND member.is_active=true)
      +
      (SELECT pg_catalog.count(*)
       FROM public.company_invitations invitation
       WHERE invitation.company_id=p_company_id
         AND invitation.status='pending'::public.company_invitation_status
         AND GREATEST(
           invitation.expires_at,
           COALESCE(
             invitation.pending_token_expires_at, invitation.expires_at
           )
         ) > pg_catalog.now()
         AND NOT EXISTS (
           SELECT 1
           FROM public.company_users active_member
           JOIN auth.users account ON account.id=active_member.user_id
           WHERE active_member.company_id=p_company_id
             AND active_member.is_active=true
             AND pg_catalog.lower(pg_catalog.btrim(account.email)) =
               invitation.email_normalized
         )
      )
      INTO v_used;
  ELSIF p_resource = 'combined_vehicles' THEN
    SELECT
      (SELECT pg_catalog.count(*) FROM public.tractor_heads
        WHERE company_id=p_company_id AND is_active=true)
      +
      (SELECT pg_catalog.count(*) FROM public.trailers
        WHERE company_id=p_company_id AND is_active=true)
      INTO v_used;
  ELSIF p_resource IN ('customers','drivers','routes') THEN
    -- Capacity is current active records, never historical creations.
    IF p_resource='customers' THEN
      SELECT pg_catalog.count(*) INTO v_used FROM public.customers
      WHERE company_id=p_company_id AND is_active=true;
    ELSIF p_resource='drivers' THEN
      SELECT pg_catalog.count(*) INTO v_used FROM public.drivers
      WHERE company_id=p_company_id AND is_active=true;
    ELSE
      SELECT pg_catalog.count(*) INTO v_used FROM public.routes
      WHERE company_id=p_company_id AND is_active=true;
    END IF;
  ELSIF p_resource IN ('lifetime_trips','lifetime_invoices') THEN
    SELECT counter.used INTO v_used
      FROM private.company_lifetime_usage_counters AS counter
      WHERE counter.company_id = p_company_id
        AND counter.resource = p_resource;
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE='P2862',
        MESSAGE='quota_lifetime_counter_missing';
    END IF;
  ELSE
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_unsupported_resource';
  END IF;
  RETURN v_used;
END;
$$;

CREATE OR REPLACE FUNCTION private.assert_company_quota_capacity(
  p_company_id uuid, p_resource text, p_additional integer
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_entitlement jsonb;
  v_limit_text text;
  v_limit bigint;
  v_used bigint;
BEGIN
  IF p_company_id IS NULL OR p_additional IS NULL OR p_additional <= 0 THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_invalid_request';
  END IF;
  IF p_resource NOT IN ('company_users', 'combined_vehicles',
                        'customers', 'drivers', 'routes',
                        'lifetime_trips', 'lifetime_invoices')
     OR p_resource IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_unsupported_resource';
  END IF;

  PERFORM 1 FROM public.companies company_row
  WHERE company_row.id=p_company_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2861',
      MESSAGE='quota_entitlement_unavailable';
  END IF;

  v_entitlement := private.resolve_company_effective_entitlement(p_company_id);
  IF v_entitlement->>'status' IS DISTINCT FROM 'active' THEN
    RAISE EXCEPTION USING ERRCODE='P2861',
      MESSAGE='quota_entitlement_unavailable';
  END IF;

  v_limit_text := v_entitlement->'limits'->>p_resource;
  IF v_limit_text IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_policy_invalid';
  END IF;
  IF v_limit_text='unlimited' THEN
    RETURN;
  END IF;
  IF v_limit_text !~ '^(0|[1-9][0-9]*)$' THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_policy_invalid';
  END IF;
  v_limit := v_limit_text::bigint;
  v_used := private.company_quota_used(p_company_id,p_resource);
  IF v_used+p_additional > v_limit THEN
    RAISE EXCEPTION USING ERRCODE='P2860',
      MESSAGE=CASE p_resource
        WHEN 'company_users' THEN 'quota_company_users_reached'
        WHEN 'combined_vehicles' THEN 'quota_combined_vehicles_reached'
        WHEN 'customers' THEN 'quota_customers_reached'
        WHEN 'drivers' THEN 'quota_drivers_reached'
        WHEN 'routes' THEN 'quota_routes_reached'
        WHEN 'lifetime_trips' THEN 'quota_lifetime_trips_reached'
        WHEN 'lifetime_invoices' THEN 'quota_lifetime_invoices_reached'
      END;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_company_quota_usage(p_company_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog
AS $$
DECLARE
  v_entitlement jsonb;
BEGIN
  IF auth.uid() IS NULL OR p_company_id IS NULL OR NOT private.has_company_role(
    p_company_id,
    ARRAY['owner'::public.company_role, 'admin'::public.company_role]
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2863',
      MESSAGE='quota_permission_denied';
  END IF;

  v_entitlement := private.resolve_company_effective_entitlement(p_company_id);
  RETURN pg_catalog.jsonb_build_object(
    'entitlement',v_entitlement,
    'usage',pg_catalog.jsonb_build_object(
      'company_users',private.company_quota_used(p_company_id,'company_users'),
      'combined_vehicles',private.company_quota_used(p_company_id,'combined_vehicles'),
      'customers',private.company_quota_used(p_company_id,'customers'),
      'drivers',private.company_quota_used(p_company_id,'drivers'),
      'routes',private.company_quota_used(p_company_id,'routes'),
      'lifetime_trips',private.company_quota_used(p_company_id,'lifetime_trips'),
      'lifetime_invoices',private.company_quota_used(p_company_id,'lifetime_invoices')
    )
  );
END;
$$;

CREATE FUNCTION private.enforce_lifetime_creation_quota()
RETURNS trigger
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path=pg_catalog
AS $$
DECLARE
  v_resource text;
  v_role public.company_role[];
  v_request_id_text text;
  v_request_id uuid;
  v_request_resource text;
  v_fingerprint text;
BEGIN
  v_resource := CASE TG_TABLE_NAME
    WHEN 'trips' THEN 'lifetime_trips'
    WHEN 'invoices' THEN 'lifetime_invoices'
    ELSE NULL
  END;
  IF v_resource IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_unsupported_resource';
  END IF;
  v_role := CASE WHEN v_resource='lifetime_trips'
    THEN ARRAY['owner','admin','operations']::public.company_role[]
    ELSE ARRAY['owner','admin','accountant']::public.company_role[] END;

  -- A privileged BEFORE trigger must not disclose cross-company utilization.
  IF (auth.uid() IS NOT NULL OR
      pg_catalog.current_setting('request.jwt.claim.role', true)
          IN ('authenticated','anon'))
     AND NOT private.has_company_role(NEW.company_id,v_role) THEN
    RAISE EXCEPTION USING ERRCODE='42501',
      MESSAGE='quota_creation_permission_denied';
  END IF;

  v_request_id_text := NULLIF(
    pg_catalog.current_setting('horus.creation_request_id',true),'');
  v_request_resource := NULLIF(
    pg_catalog.current_setting('horus.creation_resource',true),'');
  v_fingerprint := NULLIF(
    pg_catalog.current_setting('horus.creation_payload_fingerprint',true),'');
  IF v_request_id_text IS NOT NULL THEN
    IF v_request_resource IS DISTINCT FROM v_resource
        OR v_fingerprint IS NULL THEN
      RAISE EXCEPTION USING ERRCODE='P2862',
        MESSAGE='quota_creation_request_invalid';
    END IF;
    v_request_id := v_request_id_text::uuid;
  END IF;

  PERFORM private.assert_company_quota_capacity(NEW.company_id,v_resource,1);
  INSERT INTO private.company_lifetime_usage_counters AS counter
    (company_id,resource,used) VALUES(NEW.company_id,v_resource,1)
    ON CONFLICT(company_id,resource) DO UPDATE
      SET used=counter.used+1,updated_at=pg_catalog.now();
  INSERT INTO private.company_lifetime_creation_events
    (company_id,resource,entity_id,created_at,source,request_id,payload_fingerprint)
  VALUES
    (NEW.company_id,v_resource,NEW.id::text,pg_catalog.now(),'created',
      v_request_id, CASE WHEN v_request_id IS NULL THEN NULL ELSE v_fingerprint END);
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION private.enforce_lifetime_creation_quota()
  FROM PUBLIC, anon, authenticated;

-- Alphabetical BEFORE trigger order: lifetime gate runs before trip numbering.
CREATE TRIGGER trips_00_enforce_lifetime_creation_quota
  BEFORE INSERT ON public.trips
  FOR EACH ROW EXECUTE FUNCTION private.enforce_lifetime_creation_quota();
CREATE TRIGGER invoices_00_enforce_lifetime_creation_quota
  BEFORE INSERT ON public.invoices
  FOR EACH ROW EXECUTE FUNCTION private.enforce_lifetime_creation_quota();

-- The #270 draft implementation previously held a SHARE lock on company,
-- then locked trips before INSERT. Upgrade to a company UPDATE lock first,
-- preserving the entire original accounting/financial/audit body unchanged.
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
  FROM public.companies AS company_row
  WHERE company_row.id = p_company_id
    AND company_row.is_active = true
  FOR UPDATE;

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
  FROM public.customers AS customer_row
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
    FROM public.invoices AS invoice_row
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
    FROM public.invoice_lines AS line_row
    WHERE line_row.company_id = p_company_id
      AND line_row.invoice_id = p_invoice_id;
  END IF;

  -- Lock every requested Trip in one deterministic order so concurrent grouped
  -- draft creation cannot reserve the same Trips or deadlock on opposite input
  -- ordering.
  FOR v_trip IN
    SELECT
      requested_trip.line_position::integer AS line_position,
      trip_row.*
    FROM pg_catalog.unnest(p_trip_ids) WITH ORDINALITY
      AS requested_trip(trip_id, line_position)
    JOIN public.trips AS trip_row
      ON trip_row.id = requested_trip.trip_id
     AND trip_row.company_id = p_company_id
    ORDER BY trip_row.id
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

    IF EXISTS (
      SELECT 1
      FROM public.invoice_lines AS reserved_line
      JOIN public.invoices AS reserved_invoice
        ON reserved_invoice.company_id = reserved_line.company_id
       AND reserved_invoice.id = reserved_line.invoice_id
      WHERE reserved_line.company_id = p_company_id
        AND reserved_line.trip_id = v_trip.id
        AND reserved_invoice.status <> 'cancelled'
        AND (
          p_invoice_id IS NULL
          OR reserved_invoice.id <> p_invoice_id
        )
    ) THEN
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

    DELETE FROM public.invoice_lines AS line_row
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
  JOIN public.trips AS trip_row
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
    CASE
      WHEN v_is_create THEN 'invoice_created'
      ELSE 'invoice_updated'
    END,
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

-- New idempotent entrypoints wrap original RPCs without changing old signatures.
-- Existing RPCs and direct INSERT remain subject to DB triggers.
CREATE FUNCTION public.create_trip_idempotent(
  p_request_id uuid, p_company_id uuid, p_customer_id uuid, p_route_id uuid,
  p_driver_id uuid DEFAULT NULL, p_tractor_head_id uuid DEFAULT NULL,
  p_trailer_id uuid DEFAULT NULL, p_loading_order_number text DEFAULT NULL,
  p_waybill_number text DEFAULT NULL, p_quantity_tons text DEFAULT NULL,
  p_agreed_freight_rate_per_ton text DEFAULT NULL,
  p_commercial_amount text DEFAULT NULL,
  p_scheduled_loading_at timestamptz DEFAULT NULL,
  p_scheduled_delivery_at timestamptz DEFAULT NULL,
  p_actual_loading_at timestamptz DEFAULT NULL,
  p_actual_delivery_at timestamptz DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path=pg_catalog
AS $$
DECLARE
  v_fingerprint text;
  v_event private.company_lifetime_creation_events%ROWTYPE;
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL OR p_request_id IS NULL OR
      NOT private.has_company_role(p_company_id,
        ARRAY['owner','admin','operations']::public.company_role[]) THEN
    RAISE EXCEPTION USING ERRCODE='P3410',
      MESSAGE='trip_management_permission_denied';
  END IF;
  PERFORM 1 FROM public.companies c WHERE c.id=p_company_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2861',
      MESSAGE='quota_entitlement_unavailable';
  END IF;
  v_fingerprint := pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_array(p_company_id,p_customer_id,p_route_id,
      p_driver_id,p_tractor_head_id,p_trailer_id,p_loading_order_number,
      p_waybill_number,p_quantity_tons,p_agreed_freight_rate_per_ton,
      p_commercial_amount,p_scheduled_loading_at,p_scheduled_delivery_at,
      p_actual_loading_at,p_actual_delivery_at,p_notes)::text,'UTF8')),'hex');
  SELECT * INTO v_event FROM private.company_lifetime_creation_events e
  WHERE e.company_id=p_company_id AND e.resource='lifetime_trips'
    AND e.request_id=p_request_id;
  IF FOUND THEN
    IF v_event.payload_fingerprint IS DISTINCT FROM v_fingerprint THEN
      RAISE EXCEPTION USING ERRCODE='P2865',
        MESSAGE='quota_idempotency_payload_conflict';
    END IF;
    v_result := private.trip_snapshot_json(p_company_id,v_event.entity_id::uuid);
    IF v_result IS NULL THEN
      RAISE EXCEPTION USING ERRCODE='P2866',
        MESSAGE='quota_idempotent_record_unavailable';
    END IF;
    RETURN v_result;
  END IF;
  PERFORM pg_catalog.set_config('horus.creation_request_id',p_request_id::text,true);
  PERFORM pg_catalog.set_config('horus.creation_resource','lifetime_trips',true);
  PERFORM pg_catalog.set_config('horus.creation_payload_fingerprint',v_fingerprint,true);
  v_result := public.create_trip_atomic(
    p_company_id,p_customer_id,p_route_id,p_driver_id,p_tractor_head_id,
    p_trailer_id,p_loading_order_number,p_waybill_number,p_quantity_tons,
    p_agreed_freight_rate_per_ton,p_commercial_amount,p_scheduled_loading_at,
    p_scheduled_delivery_at,p_actual_loading_at,p_actual_delivery_at,p_notes);
  RETURN v_result;
END;
$$;

CREATE FUNCTION public.create_invoice_draft_idempotent(
  p_request_id uuid, p_company_id uuid, p_customer_id uuid, p_trip_ids uuid[],
  p_discount_minor_units bigint, p_tax_rate_basis_points integer,
  p_issue_date date, p_due_date date, p_notes text
)
RETURNS uuid
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path=pg_catalog
AS $$
DECLARE
  v_fingerprint text;
  v_event private.company_lifetime_creation_events%ROWTYPE;
  v_invoice_id uuid;
BEGIN
  IF auth.uid() IS NULL OR p_request_id IS NULL OR
      NOT private.has_company_role(p_company_id,
        ARRAY['owner','admin','accountant']::public.company_role[]) THEN
    RAISE EXCEPTION USING ERRCODE='P2610',
      MESSAGE='invoice_permission_denied';
  END IF;
  PERFORM 1 FROM public.companies c WHERE c.id=p_company_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2861',
      MESSAGE='quota_entitlement_unavailable';
  END IF;
  v_fingerprint := pg_catalog.encode(pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_array(p_company_id,p_customer_id,p_trip_ids,
      p_discount_minor_units,p_tax_rate_basis_points,
      p_issue_date,p_due_date,p_notes)::text,'UTF8')),'hex');
  SELECT * INTO v_event FROM private.company_lifetime_creation_events e
  WHERE e.company_id=p_company_id AND e.resource='lifetime_invoices'
    AND e.request_id=p_request_id;
  IF FOUND THEN
    IF v_event.payload_fingerprint IS DISTINCT FROM v_fingerprint THEN
      RAISE EXCEPTION USING ERRCODE='P2865',
        MESSAGE='quota_idempotency_payload_conflict';
    END IF;
    SELECT i.id INTO v_invoice_id FROM public.invoices i
    WHERE i.company_id=p_company_id AND i.id=v_event.entity_id::uuid;
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE='P2866',
        MESSAGE='quota_idempotent_record_unavailable';
    END IF;
    RETURN v_invoice_id;
  END IF;
  PERFORM pg_catalog.set_config('horus.creation_request_id',p_request_id::text,true);
  PERFORM pg_catalog.set_config('horus.creation_resource','lifetime_invoices',true);
  PERFORM pg_catalog.set_config('horus.creation_payload_fingerprint',v_fingerprint,true);
  v_invoice_id := public.create_invoice_draft(
    p_company_id,p_customer_id,p_trip_ids,p_discount_minor_units,
    p_tax_rate_basis_points,p_issue_date,p_due_date,p_notes);
  RETURN v_invoice_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_trip_idempotent(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,text,text,text,text,text,
  timestamptz,timestamptz,timestamptz,timestamptz,text)
  FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_trip_idempotent(
  uuid,uuid,uuid,uuid,uuid,uuid,uuid,text,text,text,text,text,
  timestamptz,timestamptz,timestamptz,timestamptz,text)
  TO authenticated;
REVOKE ALL ON FUNCTION public.create_invoice_draft_idempotent(
  uuid,uuid,uuid,uuid[],bigint,integer,date,date,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_invoice_draft_idempotent(
  uuid,uuid,uuid,uuid[],bigint,integer,date,date,text) TO authenticated;

-- Fail closed: no unauthenticated/external access to private quota helpers.
REVOKE ALL ON FUNCTION private.company_quota_used(uuid,text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.assert_company_quota_capacity(uuid,text,integer)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.persist_invoice_draft(
 uuid,uuid,uuid,uuid[],bigint,integer,date,date,text)
 FROM PUBLIC,anon,authenticated;

COMMIT;
