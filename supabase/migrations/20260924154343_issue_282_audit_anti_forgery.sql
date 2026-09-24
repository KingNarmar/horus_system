-- H.O.R.U.S System — Issue #282 / Issue #197 follow-up
-- Harden audit integrity by moving legacy client-authored audit events to
-- server-authoritative database triggers.
--
-- Security contract:
-- - authenticated clients cannot INSERT/UPDATE/DELETE audit rows directly;
-- - audit actor identity/role/display snapshots come from private.write_audit_event;
-- - audit semantic fields are derived from successful business mutations;
-- - Flutter audit access becomes read-only; no client audit-write RPC exists;
-- - existing audit read policies remain unchanged.

BEGIN;

CREATE OR REPLACE FUNCTION private.audit_pick_fields(
  p_row jsonb,
  p_fields text[]
)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog
AS $function$
  SELECT COALESCE(
    pg_catalog.jsonb_object_agg(field_name, p_row -> field_name),
    '{}'::jsonb
  )
  FROM pg_catalog.unnest(p_fields) AS field_name;
$function$;

REVOKE ALL ON FUNCTION private.audit_pick_fields(jsonb, text[])
  FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.mark_fleet_document_audit_context()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog
AS $function$
BEGIN
  PERFORM pg_catalog.set_config(
    'horus.fleet_document_mutation',
    'on',
    true
  );
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.mark_fleet_document_audit_context()
  FROM PUBLIC;

DROP TRIGGER IF EXISTS fleet_license_document_files_mark_audit_context
ON public.fleet_license_document_files;
CREATE TRIGGER fleet_license_document_files_mark_audit_context
AFTER INSERT ON public.fleet_license_document_files
FOR EACH ROW
EXECUTE FUNCTION private.mark_fleet_document_audit_context();

CREATE OR REPLACE FUNCTION private.audit_master_data_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_new_row jsonb := pg_catalog.to_jsonb(NEW);
  v_old_row jsonb :=
    CASE WHEN TG_OP = 'UPDATE' THEN pg_catalog.to_jsonb(OLD) END;
  v_fields text[];
  v_module text;
  v_entity_type text;
  v_entity_display_name text;
  v_created_event text;
  v_updated_event text;
  v_deactivated_event text;
  v_reactivated_event text;
  v_action text;
  v_event text;
  v_old_values jsonb;
  v_new_values jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_TABLE_NAME IN ('tractor_heads', 'trailers')
     AND pg_catalog.current_setting(
       'horus.fleet_document_mutation',
       true
     ) = 'on' THEN
    RETURN NEW;
  END IF;

  CASE TG_TABLE_NAME
    WHEN 'customers' THEN
      v_module := 'customers';
      v_entity_type := 'customer';
      v_entity_display_name := v_new_row ->> 'name';
      v_created_event := 'customer_created';
      v_updated_event := 'customer_updated';
      v_deactivated_event := 'customer_deactivated';
      v_reactivated_event := 'customer_reactivated';
      v_fields := ARRAY[
        'id', 'company_id', 'name', 'contact_person', 'phone', 'email',
        'tax_registration_number', 'address', 'city', 'country',
        'credit_limit', 'is_active', 'created_at', 'updated_at'
      ];
    WHEN 'routes' THEN
      v_module := 'routes';
      v_entity_type := 'route';
      v_entity_display_name :=
        COALESCE(v_new_row ->> 'loading_location', '')
        || ' → '
        || COALESCE(v_new_row ->> 'unloading_location', '');
      v_created_event := 'route_created';
      v_updated_event := 'route_updated';
      v_deactivated_event := 'route_deactivated';
      v_reactivated_event := 'route_reactivated';
      v_fields := ARRAY[
        'id', 'company_id', 'loading_location', 'unloading_location',
        'governorate_from', 'governorate_to', 'default_freight_price',
        'notes', 'is_active', 'created_at', 'updated_at'
      ];
    WHEN 'drivers' THEN
      v_module := 'drivers';
      v_entity_type := 'driver';
      v_entity_display_name := v_new_row ->> 'full_name';
      v_created_event := 'driver_created';
      v_updated_event := 'driver_updated';
      v_deactivated_event := 'driver_deactivated';
      v_reactivated_event := 'driver_reactivated';
      v_fields := ARRAY[
        'id', 'company_id', 'full_name', 'phone', 'national_id',
        'license_number', 'license_expiry_date', 'profile_image_path',
        'license_image_path', 'license_back_image_path',
        'national_id_image_path', 'national_id_back_image_path', 'notes',
        'is_active', 'created_at', 'updated_at'
      ];
    WHEN 'tractor_heads' THEN
      v_module := 'fleet';
      v_entity_type := 'tractor_head';
      v_entity_display_name := v_new_row ->> 'plate_number';
      v_created_event := 'tractor_head_created';
      v_updated_event := 'tractor_head_updated';
      v_deactivated_event := 'tractor_head_deactivated';
      v_reactivated_event := 'tractor_head_reactivated';
      v_fields := ARRAY[
        'id', 'company_id', 'plate_number', 'license_expiry_date',
        'expected_fuel_consumption', 'status', 'notes', 'is_active',
        'created_at', 'updated_at'
      ];
    WHEN 'trailers' THEN
      v_module := 'fleet';
      v_entity_type := 'trailer';
      v_entity_display_name := v_new_row ->> 'plate_number';
      v_created_event := 'trailer_created';
      v_updated_event := 'trailer_updated';
      v_deactivated_event := 'trailer_deactivated';
      v_reactivated_event := 'trailer_reactivated';
      v_fields := ARRAY[
        'id', 'company_id', 'plate_number', 'license_expiry_date', 'status',
        'technical_notes', 'is_active', 'created_at', 'updated_at'
      ];
    WHEN 'payment_methods' THEN
      v_module := 'company_settings';
      v_entity_type := 'payment_method';
      v_entity_display_name := v_new_row ->> 'name';
      v_created_event := 'payment_method_created';
      v_updated_event := 'payment_method_updated';
      v_deactivated_event := 'payment_method_deactivated';
      v_reactivated_event := 'payment_method_reactivated';
      v_fields := ARRAY[
        'id', 'company_id', 'name', 'code', 'is_active', 'created_by',
        'updated_by', 'created_at', 'updated_at'
      ];
    ELSE
      RAISE EXCEPTION USING
        ERRCODE = 'P2820',
        MESSAGE = 'unsupported_master_audit_table';
  END CASE;

  v_new_values := private.audit_pick_fields(v_new_row, v_fields);
  IF TG_TABLE_NAME = 'routes' THEN
    v_new_values :=
      (v_new_values - 'default_freight_price')
      || pg_catalog.jsonb_build_object(
        'default_freight_rate_per_ton',
        v_new_row -> 'default_freight_price'
      );
  END IF;

  IF TG_OP = 'INSERT' THEN
    v_action := 'created';
    v_event := v_created_event;
    v_old_values := NULL;
  ELSE
    v_old_values := private.audit_pick_fields(v_old_row, v_fields);
    IF TG_TABLE_NAME = 'routes' THEN
      v_old_values :=
        (v_old_values - 'default_freight_price')
        || pg_catalog.jsonb_build_object(
          'default_freight_rate_per_ton',
          v_old_row -> 'default_freight_price'
        );
    END IF;

    IF (v_old_row ->> 'is_active')::boolean = true
       AND (v_new_row ->> 'is_active')::boolean = false THEN
      v_action := 'deactivated';
      v_event := v_deactivated_event;
    ELSIF (v_old_row ->> 'is_active')::boolean = false
       AND (v_new_row ->> 'is_active')::boolean = true THEN
      v_action := 'reactivated';
      v_event := v_reactivated_event;
    ELSE
      v_action := 'updated';
      v_event := v_updated_event;
    END IF;
  END IF;

  PERFORM private.write_audit_event(
    (v_new_row ->> 'company_id')::uuid,
    v_module,
    v_entity_type,
    v_new_row ->> 'id',
    v_entity_display_name,
    v_action,
    v_event,
    v_old_values,
    v_new_values,
    '{}'::jsonb
  );

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.audit_master_data_mutation()
  FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.audit_company_expense_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_new_row jsonb := pg_catalog.to_jsonb(NEW);
  v_old_row jsonb :=
    CASE WHEN TG_OP = 'UPDATE' THEN pg_catalog.to_jsonb(OLD) END;
  v_fields text[] := ARRAY[
    'id', 'company_id', 'category_id', 'driver_id', 'tractor_head_id',
    'trailer_id', 'trip_id', 'amount', 'expense_date', 'reference_number',
    'notes', 'is_voided', 'voided_at', 'voided_by', 'void_reason',
    'created_at', 'updated_at'
  ];
  v_action text;
  v_event text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    v_action := 'created';
    v_event := 'company_expense_created';
  ELSIF (v_old_row ->> 'is_voided')::boolean = false
     AND (v_new_row ->> 'is_voided')::boolean = true THEN
    v_action := 'status_changed';
    v_event := 'company_expense_voided';
  ELSE
    v_action := 'updated';
    v_event := 'company_expense_updated';
  END IF;

  PERFORM private.write_audit_event(
    NEW.company_id,
    'expenses',
    'expense',
    NEW.id::text,
    'company_expense',
    v_action,
    v_event,
    CASE
      WHEN TG_OP = 'UPDATE'
        THEN private.audit_pick_fields(v_old_row, v_fields)
      ELSE NULL
    END,
    private.audit_pick_fields(v_new_row, v_fields),
    pg_catalog.jsonb_build_object(
      'audit_event', v_event,
      'amount', v_new_row -> 'amount',
      'category_id', v_new_row -> 'category_id',
      'driver_id', v_new_row -> 'driver_id',
      'tractor_head_id', v_new_row -> 'tractor_head_id',
      'trailer_id', v_new_row -> 'trailer_id',
      'trip_id', v_new_row -> 'trip_id'
    )
  );

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.audit_company_expense_mutation()
  FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.audit_driver_financial_movement_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_row jsonb := pg_catalog.to_jsonb(NEW);
  v_values jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  v_values := private.audit_pick_fields(
    v_row,
    ARRAY[
      'id', 'company_id', 'driver_id', 'trip_id', 'movement_type', 'amount',
      'amount_minor_units', 'currency_code', 'currency_fraction_digits',
      'movement_date', 'notes', 'created_at', 'updated_at'
    ]
  );

  PERFORM private.write_audit_event(
    NEW.company_id,
    'drivers',
    'driver',
    NEW.driver_id::text,
    'driver_financial_movement',
    'created',
    'driver_finance_movement_added',
    NULL,
    v_values,
    pg_catalog.jsonb_build_object(
      'audit_event', 'driver_finance_movement_added',
      'movement_id', NEW.id,
      'movement_type', NEW.movement_type,
      'amount', NEW.amount,
      'amount_minor_units', NEW.amount_minor_units,
      'currency_code', NEW.currency_code,
      'currency_fraction_digits', NEW.currency_fraction_digits,
      'trip_id', NEW.trip_id
    )
  );

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.audit_driver_financial_movement_insert()
  FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.driver_settlement_audit_values(
  p_row jsonb
)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog
AS $function$
  SELECT private.audit_pick_fields(
    p_row,
    ARRAY[
      'id', 'company_id', 'driver_id', 'period_start', 'period_end',
      'compensation_revision_id', 'currency_code', 'currency_fraction_digits',
      'opening_driver_balance', 'opening_driver_balance_minor_units',
      'advances_total', 'advances_total_minor_units',
      'driver_paid_trip_expenses_total',
      'driver_paid_trip_expenses_total_minor_units',
      'returned_cash_total', 'returned_cash_total_minor_units',
      'deductions_total', 'deductions_total_minor_units',
      'settlement_deductions_total',
      'settlement_deductions_total_minor_units',
      'gross_salary', 'gross_salary_minor_units',
      'salary_deductions_total', 'salary_deductions_total_minor_units',
      'balance_deduction_applied', 'balance_deduction_applied_minor_units',
      'net_salary_payable', 'net_salary_payable_minor_units',
      'closing_driver_balance', 'closing_driver_balance_minor_units',
      'status', 'notes', 'finalized_at', 'finalized_by', 'voided_at',
      'voided_by', 'void_reason', 'created_by', 'updated_by', 'created_at',
      'updated_at'
    ]
  );
$function$;

REVOKE ALL ON FUNCTION private.driver_settlement_audit_values(jsonb)
  FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.audit_driver_settlement_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_new_row jsonb := pg_catalog.to_jsonb(NEW);
  v_old_row jsonb :=
    CASE WHEN TG_OP = 'UPDATE' THEN pg_catalog.to_jsonb(OLD) END;
  v_action text;
  v_event text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    v_action := 'created';
    v_event := 'driver_settlement_created';
  ELSIF OLD.status IS DISTINCT FROM NEW.status
     AND NEW.status = 'finalized'::public.driver_settlement_status THEN
    v_action := 'status_changed';
    v_event := 'driver_settlement_finalized';
  ELSIF OLD.status IS DISTINCT FROM NEW.status
     AND NEW.status = 'voided'::public.driver_settlement_status THEN
    v_action := 'status_changed';
    v_event := 'driver_settlement_voided';
  ELSE
    RETURN NEW;
  END IF;

  PERFORM private.write_audit_event(
    NEW.company_id,
    'drivers',
    'driver',
    NEW.driver_id::text,
    'driver_settlement',
    v_action,
    v_event,
    CASE
      WHEN TG_OP = 'UPDATE'
        THEN private.driver_settlement_audit_values(v_old_row)
      ELSE NULL
    END,
    private.driver_settlement_audit_values(v_new_row),
    pg_catalog.jsonb_build_object(
      'audit_event', v_event,
      'settlement_id', NEW.id,
      'driver_id', NEW.driver_id,
      'status', NEW.status,
      'period_start', NEW.period_start,
      'period_end', NEW.period_end,
      'compensation_revision_id', NEW.compensation_revision_id,
      'currency_code', NEW.currency_code,
      'currency_fraction_digits', NEW.currency_fraction_digits,
      'closing_driver_balance', NEW.closing_driver_balance,
      'closing_driver_balance_minor_units',
        NEW.closing_driver_balance_minor_units,
      'net_salary_payable', NEW.net_salary_payable,
      'net_salary_payable_minor_units', NEW.net_salary_payable_minor_units,
      'gross_salary_minor_units', NEW.gross_salary_minor_units
    )
  );

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.audit_driver_settlement_mutation()
  FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.driver_compensation_audit_values(
  p_row jsonb
)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SET search_path = pg_catalog
AS $function$
  SELECT private.audit_pick_fields(
    p_row,
    ARRAY[
      'amount_minor_units', 'currency_code', 'currency_fraction_digits',
      'effective_from', 'effective_to', 'contract_reference'
    ]
  ) || pg_catalog.jsonb_build_object(
    'contract_document_attached',
    NULLIF(p_row ->> 'contract_document_reference', '') IS NOT NULL
  );
$function$;

REVOKE ALL ON FUNCTION private.driver_compensation_audit_values(jsonb)
  FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.audit_driver_compensation_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_new_row jsonb := pg_catalog.to_jsonb(NEW);
  v_old_row jsonb :=
    CASE WHEN TG_OP = 'UPDATE' THEN pg_catalog.to_jsonb(OLD) END;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

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
      private.driver_compensation_audit_values(v_new_row),
      pg_catalog.jsonb_build_object(
        'audit_event', 'driver_compensation_revision_created',
        'driver_id', NEW.driver_id,
        'compensation_revision_id', NEW.id
      )
    );
    RETURN NEW;
  END IF;

  IF OLD.effective_to IS DISTINCT FROM NEW.effective_to THEN
    PERFORM private.write_audit_event(
      NEW.company_id,
      'drivers',
      'driver_compensation_revision',
      NEW.id::text,
      NULL,
      'updated',
      'driver_compensation_revision_ended',
      private.driver_compensation_audit_values(v_old_row),
      private.driver_compensation_audit_values(v_new_row),
      pg_catalog.jsonb_build_object(
        'audit_event', 'driver_compensation_revision_ended',
        'driver_id', NEW.driver_id,
        'compensation_revision_id', NEW.id
      )
    );
  END IF;

  IF OLD.contract_document_reference IS DISTINCT FROM NEW.contract_document_reference
     AND NEW.contract_document_reference IS NOT NULL THEN
    PERFORM private.write_audit_event(
      NEW.company_id,
      'drivers',
      'driver_compensation_revision',
      NEW.id::text,
      NULL,
      'updated',
      'driver_compensation_contract_attached',
      private.driver_compensation_audit_values(v_old_row),
      private.driver_compensation_audit_values(v_new_row),
      pg_catalog.jsonb_build_object(
        'audit_event', 'driver_compensation_contract_attached',
        'driver_id', NEW.driver_id,
        'compensation_revision_id', NEW.id
      )
    );
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.audit_driver_compensation_mutation()
  FROM PUBLIC;

DROP TRIGGER IF EXISTS customers_write_server_audit
ON public.customers;
CREATE TRIGGER customers_write_server_audit
AFTER INSERT OR UPDATE ON public.customers
FOR EACH ROW
EXECUTE FUNCTION private.audit_master_data_mutation();

DROP TRIGGER IF EXISTS routes_write_server_audit
ON public.routes;
CREATE TRIGGER routes_write_server_audit
AFTER INSERT OR UPDATE ON public.routes
FOR EACH ROW
EXECUTE FUNCTION private.audit_master_data_mutation();

DROP TRIGGER IF EXISTS drivers_write_server_audit
ON public.drivers;
CREATE TRIGGER drivers_write_server_audit
AFTER INSERT OR UPDATE ON public.drivers
FOR EACH ROW
EXECUTE FUNCTION private.audit_master_data_mutation();

DROP TRIGGER IF EXISTS tractor_heads_write_server_audit
ON public.tractor_heads;
CREATE TRIGGER tractor_heads_write_server_audit
AFTER INSERT OR UPDATE ON public.tractor_heads
FOR EACH ROW
EXECUTE FUNCTION private.audit_master_data_mutation();

DROP TRIGGER IF EXISTS trailers_write_server_audit
ON public.trailers;
CREATE TRIGGER trailers_write_server_audit
AFTER INSERT OR UPDATE ON public.trailers
FOR EACH ROW
EXECUTE FUNCTION private.audit_master_data_mutation();

DROP TRIGGER IF EXISTS payment_methods_write_server_audit
ON public.payment_methods;
CREATE TRIGGER payment_methods_write_server_audit
AFTER INSERT OR UPDATE ON public.payment_methods
FOR EACH ROW
EXECUTE FUNCTION private.audit_master_data_mutation();

DROP TRIGGER IF EXISTS company_expenses_write_server_audit
ON public.company_expenses;
CREATE TRIGGER company_expenses_write_server_audit
AFTER INSERT OR UPDATE ON public.company_expenses
FOR EACH ROW
EXECUTE FUNCTION private.audit_company_expense_mutation();

DROP TRIGGER IF EXISTS driver_financial_movements_write_server_audit
ON public.driver_financial_movements;
CREATE TRIGGER driver_financial_movements_write_server_audit
AFTER INSERT ON public.driver_financial_movements
FOR EACH ROW
EXECUTE FUNCTION private.audit_driver_financial_movement_insert();

DROP TRIGGER IF EXISTS driver_settlements_write_server_audit
ON public.driver_settlements;
CREATE TRIGGER driver_settlements_write_server_audit
AFTER INSERT OR UPDATE ON public.driver_settlements
FOR EACH ROW
EXECUTE FUNCTION private.audit_driver_settlement_mutation();

DROP TRIGGER IF EXISTS driver_compensation_write_server_audit
ON public.driver_compensation_revisions;
CREATE TRIGGER driver_compensation_write_server_audit
AFTER INSERT OR UPDATE ON public.driver_compensation_revisions
FOR EACH ROW
EXECUTE FUNCTION private.audit_driver_compensation_mutation();

DROP POLICY IF EXISTS audit_logs_insert_company_members
ON public.audit_logs;

REVOKE INSERT, UPDATE, DELETE ON TABLE public.audit_logs
FROM authenticated;

COMMIT;
