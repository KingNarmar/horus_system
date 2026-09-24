-- H.O.R.U.S System — Issue #197
-- Make legacy client-audited mutations server-owned and non-forgeable.
--
-- Security contract:
-- - business mutations remain authorized by their existing grants/RLS;
-- - audit actor identity/role is resolved server-side by private.write_audit_event;
-- - audit rows are written inside the same PostgreSQL transaction as the
--   successful business mutation;
-- - authenticated clients lose direct INSERT access to public.audit_logs;
-- - existing semantic event keys and timeline payload keys are preserved.

BEGIN;

CREATE OR REPLACE FUNCTION private.legacy_audit_row_values(
  p_table_name text,
  p_row jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path TO 'pg_catalog'
AS $function$
BEGIN
  IF p_row IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN CASE p_table_name
    WHEN 'customers' THEN
      p_row - ARRAY[
        'governorate',
        'payment_terms',
        'notes',
        'created_by',
        'updated_by'
      ]
    WHEN 'drivers' THEN
      p_row - ARRAY[
        'name',
        'license_type',
        'status',
        'created_by',
        'updated_by'
      ]
    WHEN 'tractor_heads' THEN
      p_row - ARRAY['created_by', 'updated_by']
    WHEN 'trailers' THEN
      p_row - ARRAY['created_by', 'updated_by']
    WHEN 'routes' THEN
      (
        p_row - ARRAY[
          'default_freight_price',
          'created_by',
          'updated_by'
        ]
      )
      || pg_catalog.jsonb_build_object(
        'default_freight_rate_per_ton',
        p_row -> 'default_freight_price'
      )
    WHEN 'company_expenses' THEN
      p_row - ARRAY['created_by', 'updated_by']
    WHEN 'driver_financial_movements' THEN
      p_row - ARRAY['created_by', 'updated_by']
    WHEN 'driver_compensation_revisions' THEN
      pg_catalog.jsonb_build_object(
        'amount_minor_units', p_row -> 'amount_minor_units',
        'currency_code', p_row -> 'currency_code',
        'currency_fraction_digits', p_row -> 'currency_fraction_digits',
        'effective_from', p_row -> 'effective_from',
        'effective_to', p_row -> 'effective_to',
        'contract_reference', p_row -> 'contract_reference',
        'contract_document_attached',
          pg_catalog.coalesce(
            pg_catalog.nullif(
              pg_catalog.btrim(p_row ->> 'contract_document_reference'),
              ''
            ),
            ''
          ) <> ''
      )
    ELSE p_row
  END;
END;
$function$;

REVOKE ALL
ON FUNCTION private.legacy_audit_row_values(text, jsonb)
FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.audit_legacy_business_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_old_row jsonb;
  v_new_row jsonb;
  v_company_id uuid;
  v_module text;
  v_entity_type text;
  v_entity_id text;
  v_entity_display_name text;
  v_action text;
  v_event text;
  v_metadata jsonb := '{}'::jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    v_old_row := NULL;
    v_new_row := pg_catalog.to_jsonb(NEW);
    v_company_id := NEW.company_id;
  ELSE
    v_old_row := pg_catalog.to_jsonb(OLD);
    v_new_row := pg_catalog.to_jsonb(NEW);
    v_company_id := NEW.company_id;
  END IF;

  CASE TG_TABLE_NAME
    WHEN 'customers' THEN
      v_module := 'customers';
      v_entity_type := 'customer';
      v_entity_id := v_new_row ->> 'id';
      v_entity_display_name := v_new_row ->> 'name';
      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'customer_created';
      ELSIF (v_old_row ->> 'is_active')::boolean
        AND NOT (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'deactivated';
        v_event := 'customer_deactivated';
      ELSIF NOT (v_old_row ->> 'is_active')::boolean
        AND (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'reactivated';
        v_event := 'customer_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'customer_updated';
      END IF;

    WHEN 'drivers' THEN
      v_module := 'drivers';
      v_entity_type := 'driver';
      v_entity_id := v_new_row ->> 'id';
      v_entity_display_name := v_new_row ->> 'full_name';
      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'driver_created';
      ELSIF (v_old_row ->> 'is_active')::boolean
        AND NOT (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'deactivated';
        v_event := 'driver_deactivated';
      ELSIF NOT (v_old_row ->> 'is_active')::boolean
        AND (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'reactivated';
        v_event := 'driver_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'driver_updated';
      END IF;

    WHEN 'tractor_heads' THEN
      v_module := 'fleet';
      v_entity_type := 'tractor_head';
      v_entity_id := v_new_row ->> 'id';
      v_entity_display_name := v_new_row ->> 'plate_number';
      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'tractor_head_created';
      ELSIF (v_old_row ->> 'is_active')::boolean
        AND NOT (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'deactivated';
        v_event := 'tractor_head_deactivated';
      ELSIF NOT (v_old_row ->> 'is_active')::boolean
        AND (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'reactivated';
        v_event := 'tractor_head_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'tractor_head_updated';
      END IF;

    WHEN 'trailers' THEN
      v_module := 'fleet';
      v_entity_type := 'trailer';
      v_entity_id := v_new_row ->> 'id';
      v_entity_display_name := v_new_row ->> 'plate_number';
      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'trailer_created';
      ELSIF (v_old_row ->> 'is_active')::boolean
        AND NOT (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'deactivated';
        v_event := 'trailer_deactivated';
      ELSIF NOT (v_old_row ->> 'is_active')::boolean
        AND (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'reactivated';
        v_event := 'trailer_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'trailer_updated';
      END IF;

    WHEN 'routes' THEN
      v_module := 'routes';
      v_entity_type := 'route';
      v_entity_id := v_new_row ->> 'id';
      v_entity_display_name :=
        pg_catalog.coalesce(v_new_row ->> 'loading_location', '')
        || ' → '
        || pg_catalog.coalesce(v_new_row ->> 'unloading_location', '');
      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'route_created';
      ELSIF (v_old_row ->> 'is_active')::boolean
        AND NOT (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'deactivated';
        v_event := 'route_deactivated';
      ELSIF NOT (v_old_row ->> 'is_active')::boolean
        AND (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'reactivated';
        v_event := 'route_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'route_updated';
      END IF;

    WHEN 'payment_methods' THEN
      v_module := 'company_settings';
      v_entity_type := 'payment_method';
      v_entity_id := v_new_row ->> 'id';
      v_entity_display_name := v_new_row ->> 'name';
      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'payment_method_created';
      ELSIF (v_old_row ->> 'is_active')::boolean
        AND NOT (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'deactivated';
        v_event := 'payment_method_deactivated';
      ELSIF NOT (v_old_row ->> 'is_active')::boolean
        AND (v_new_row ->> 'is_active')::boolean THEN
        v_action := 'reactivated';
        v_event := 'payment_method_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'payment_method_updated';
      END IF;

    WHEN 'company_expenses' THEN
      v_module := 'expenses';
      v_entity_type := 'expense';
      v_entity_id := v_new_row ->> 'id';
      v_entity_display_name := 'company_expense';
      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'company_expense_created';
      ELSIF NOT (v_old_row ->> 'is_voided')::boolean
        AND (v_new_row ->> 'is_voided')::boolean THEN
        v_action := 'status_changed';
        v_event := 'company_expense_voided';
      ELSE
        v_action := 'updated';
        v_event := 'company_expense_updated';
      END IF;
      v_metadata := pg_catalog.jsonb_build_object(
        'amount', v_new_row -> 'amount',
        'category_id', v_new_row -> 'category_id',
        'driver_id', v_new_row -> 'driver_id',
        'tractor_head_id', v_new_row -> 'tractor_head_id',
        'trailer_id', v_new_row -> 'trailer_id',
        'trip_id', v_new_row -> 'trip_id'
      );

    WHEN 'driver_financial_movements' THEN
      IF TG_OP <> 'INSERT' THEN
        RETURN NEW;
      END IF;
      v_module := 'drivers';
      v_entity_type := 'driver';
      v_entity_id := v_new_row ->> 'driver_id';
      v_entity_display_name := 'driver_financial_movement';
      v_action := 'created';
      v_event := 'driver_finance_movement_added';
      v_metadata := pg_catalog.jsonb_build_object(
        'movement_id', v_new_row -> 'id',
        'movement_type', v_new_row -> 'movement_type',
        'amount', v_new_row -> 'amount',
        'amount_minor_units', v_new_row -> 'amount_minor_units',
        'currency_code', v_new_row -> 'currency_code',
        'currency_fraction_digits', v_new_row -> 'currency_fraction_digits',
        'trip_id', v_new_row -> 'trip_id'
      );

    WHEN 'driver_settlements' THEN
      v_module := 'drivers';
      v_entity_type := 'driver';
      v_entity_id := v_new_row ->> 'driver_id';
      v_entity_display_name := 'driver_settlement';
      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'driver_settlement_created';
      ELSIF v_new_row ->> 'status' = 'finalized'
        AND v_old_row ->> 'status' IS DISTINCT FROM 'finalized' THEN
        v_action := 'status_changed';
        v_event := 'driver_settlement_finalized';
      ELSIF v_new_row ->> 'status' = 'voided'
        AND v_old_row ->> 'status' IS DISTINCT FROM 'voided' THEN
        v_action := 'status_changed';
        v_event := 'driver_settlement_voided';
      ELSE
        RETURN NEW;
      END IF;
      v_metadata := pg_catalog.jsonb_build_object(
        'settlement_id', v_new_row -> 'id',
        'driver_id', v_new_row -> 'driver_id',
        'status', v_new_row -> 'status',
        'period_start', v_new_row -> 'period_start',
        'period_end', v_new_row -> 'period_end',
        'compensation_revision_id', v_new_row -> 'compensation_revision_id',
        'currency_code', v_new_row -> 'currency_code',
        'currency_fraction_digits', v_new_row -> 'currency_fraction_digits',
        'closing_driver_balance', v_new_row -> 'closing_driver_balance',
        'closing_driver_balance_minor_units',
          v_new_row -> 'closing_driver_balance_minor_units',
        'net_salary_payable', v_new_row -> 'net_salary_payable',
        'net_salary_payable_minor_units',
          v_new_row -> 'net_salary_payable_minor_units',
        'gross_salary_minor_units', v_new_row -> 'gross_salary_minor_units'
      );

    ELSE
      RAISE EXCEPTION 'Unsupported legacy audit table: %', TG_TABLE_NAME
        USING ERRCODE = '22023';
  END CASE;

  PERFORM private.write_audit_event(
    v_company_id,
    v_module,
    v_entity_type,
    v_entity_id,
    v_entity_display_name,
    v_action,
    v_event,
    private.legacy_audit_row_values(TG_TABLE_NAME, v_old_row),
    private.legacy_audit_row_values(TG_TABLE_NAME, v_new_row),
    v_metadata
  );

  RETURN NEW;
END;
$function$;

REVOKE ALL
ON FUNCTION private.audit_legacy_business_mutation()
FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.audit_driver_compensation_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_old_values jsonb;
  v_new_values jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  v_old_values := private.legacy_audit_row_values(
    'driver_compensation_revisions',
    CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE pg_catalog.to_jsonb(OLD) END
  );
  v_new_values := private.legacy_audit_row_values(
    'driver_compensation_revisions',
    pg_catalog.to_jsonb(NEW)
  );

  IF TG_OP = 'INSERT' THEN
    PERFORM private.write_audit_event(
      NEW.company_id,
      'drivers',
      'driver_compensation_revision',
      NEW.id::text,
      NULL,
      'created',
      'driver_compensation_revision_created',
      NULL,
      v_new_values,
      pg_catalog.jsonb_build_object(
        'driver_id', NEW.driver_id,
        'compensation_revision_id', NEW.id
      )
    );
    RETURN NEW;
  END IF;

  IF OLD.effective_to IS DISTINCT FROM NEW.effective_to
    AND OLD.effective_to IS NULL THEN
    PERFORM private.write_audit_event(
      NEW.company_id,
      'drivers',
      'driver_compensation_revision',
      NEW.id::text,
      NULL,
      'updated',
      'driver_compensation_revision_ended',
      v_old_values,
      v_new_values,
      pg_catalog.jsonb_build_object(
        'driver_id', NEW.driver_id,
        'compensation_revision_id', NEW.id
      )
    );
  END IF;

  IF OLD.contract_document_reference
    IS DISTINCT FROM NEW.contract_document_reference
    AND OLD.contract_document_reference IS NULL
    AND NEW.contract_document_reference IS NOT NULL THEN
    PERFORM private.write_audit_event(
      NEW.company_id,
      'drivers',
      'driver_compensation_revision',
      NEW.id::text,
      NULL,
      'updated',
      'driver_compensation_contract_attached',
      v_old_values,
      v_new_values,
      pg_catalog.jsonb_build_object(
        'driver_id', NEW.driver_id,
        'compensation_revision_id', NEW.id
      )
    );
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL
ON FUNCTION private.audit_driver_compensation_mutation()
FROM PUBLIC, anon, authenticated, service_role;

DROP TRIGGER IF EXISTS customers_audit_server_owned ON public.customers;
CREATE TRIGGER customers_audit_server_owned
AFTER INSERT OR UPDATE ON public.customers
FOR EACH ROW EXECUTE FUNCTION private.audit_legacy_business_mutation();

DROP TRIGGER IF EXISTS drivers_audit_server_owned ON public.drivers;
CREATE TRIGGER drivers_audit_server_owned
AFTER INSERT OR UPDATE ON public.drivers
FOR EACH ROW EXECUTE FUNCTION private.audit_legacy_business_mutation();

DROP TRIGGER IF EXISTS tractor_heads_audit_server_owned ON public.tractor_heads;
CREATE TRIGGER tractor_heads_audit_server_owned
AFTER INSERT OR UPDATE ON public.tractor_heads
FOR EACH ROW EXECUTE FUNCTION private.audit_legacy_business_mutation();

DROP TRIGGER IF EXISTS trailers_audit_server_owned ON public.trailers;
CREATE TRIGGER trailers_audit_server_owned
AFTER INSERT OR UPDATE ON public.trailers
FOR EACH ROW EXECUTE FUNCTION private.audit_legacy_business_mutation();

DROP TRIGGER IF EXISTS routes_audit_server_owned ON public.routes;
CREATE TRIGGER routes_audit_server_owned
AFTER INSERT OR UPDATE ON public.routes
FOR EACH ROW EXECUTE FUNCTION private.audit_legacy_business_mutation();

DROP TRIGGER IF EXISTS payment_methods_audit_server_owned
ON public.payment_methods;
CREATE TRIGGER payment_methods_audit_server_owned
AFTER INSERT OR UPDATE ON public.payment_methods
FOR EACH ROW EXECUTE FUNCTION private.audit_legacy_business_mutation();

DROP TRIGGER IF EXISTS company_expenses_audit_server_owned
ON public.company_expenses;
CREATE TRIGGER company_expenses_audit_server_owned
AFTER INSERT OR UPDATE ON public.company_expenses
FOR EACH ROW EXECUTE FUNCTION private.audit_legacy_business_mutation();

DROP TRIGGER IF EXISTS driver_financial_movements_audit_server_owned
ON public.driver_financial_movements;
CREATE TRIGGER driver_financial_movements_audit_server_owned
AFTER INSERT ON public.driver_financial_movements
FOR EACH ROW EXECUTE FUNCTION private.audit_legacy_business_mutation();

DROP TRIGGER IF EXISTS driver_settlements_audit_server_owned
ON public.driver_settlements;
CREATE TRIGGER driver_settlements_audit_server_owned
AFTER INSERT OR UPDATE ON public.driver_settlements
FOR EACH ROW EXECUTE FUNCTION private.audit_legacy_business_mutation();

DROP TRIGGER IF EXISTS driver_compensation_revisions_audit_server_owned
ON public.driver_compensation_revisions;
CREATE TRIGGER driver_compensation_revisions_audit_server_owned
AFTER INSERT OR UPDATE ON public.driver_compensation_revisions
FOR EACH ROW EXECUTE FUNCTION private.audit_driver_compensation_mutation();

DROP POLICY IF EXISTS audit_logs_insert_company_members
ON public.audit_logs;

REVOKE INSERT, UPDATE, DELETE
ON TABLE public.audit_logs
FROM PUBLIC, anon, authenticated;

COMMIT;
