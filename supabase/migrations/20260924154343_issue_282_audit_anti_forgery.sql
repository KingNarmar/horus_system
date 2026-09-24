-- H.O.R.U.S System — Issue #282
-- Harden audit integrity by making legacy business-table audit events
-- server-authored and removing direct authenticated INSERT on audit_logs.
--
-- Security contract:
-- - clients mutate authorized business tables only through their existing RLS/grants;
-- - AFTER triggers derive audit semantics from the committed row transition;
-- - private.write_audit_event resolves the authenticated actor server-side;
-- - authenticated clients cannot INSERT audit_logs directly;
-- - maintenance/backfill writes without auth.uid() are not blocked by audit triggers.

BEGIN;

CREATE OR REPLACE FUNCTION private.legacy_audit_snapshot(
  p_table_name text,
  p_row jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SET search_path = pg_catalog
AS $$
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
      ]::text[]

    WHEN 'routes' THEN
      (
        p_row - ARRAY[
          'default_freight_price',
          'created_by',
          'updated_by'
        ]::text[]
      )
      || pg_catalog.jsonb_build_object(
        'default_freight_rate_per_ton',
        p_row ->> 'default_freight_price'
      )

    WHEN 'drivers' THEN
      p_row - ARRAY[
        'name',
        'license_type',
        'status',
        'created_by',
        'updated_by'
      ]::text[]

    WHEN 'tractor_heads' THEN
      p_row - ARRAY['created_by', 'updated_by']::text[]

    WHEN 'trailers' THEN
      p_row - ARRAY['created_by', 'updated_by']::text[]

    WHEN 'payment_methods' THEN
      p_row

    WHEN 'company_expenses' THEN
      p_row - ARRAY['created_by', 'updated_by']::text[]

    WHEN 'driver_financial_movements' THEN
      p_row - ARRAY['created_by', 'updated_by']::text[]

    WHEN 'driver_compensation_revisions' THEN
      pg_catalog.jsonb_build_object(
        'amount_minor_units', p_row -> 'amount_minor_units',
        'currency_code', p_row -> 'currency_code',
        'currency_fraction_digits', p_row -> 'currency_fraction_digits',
        'effective_from', p_row -> 'effective_from',
        'effective_to', p_row -> 'effective_to',
        'contract_reference', p_row -> 'contract_reference',
        'contract_document_attached',
          (p_row ->> 'contract_document_reference') IS NOT NULL
      )

    WHEN 'driver_settlements' THEN
      p_row

    ELSE
      p_row
  END;
END;
$$;

REVOKE ALL ON FUNCTION private.legacy_audit_snapshot(text, jsonb)
  FROM PUBLIC;

CREATE OR REPLACE FUNCTION private.write_legacy_table_audit_event()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_old_values jsonb;
  v_new_values jsonb;
  v_module text;
  v_entity_type text;
  v_entity_id text;
  v_entity_display_name text;
  v_action text;
  v_event text;
  v_metadata jsonb := '{}'::jsonb;
BEGIN
  -- Do not block migrations, maintenance, or trusted server-side backfills.
  IF v_actor_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    v_old_values := private.legacy_audit_snapshot(
      TG_TABLE_NAME,
      pg_catalog.to_jsonb(OLD)
    );
  END IF;

  v_new_values := private.legacy_audit_snapshot(
    TG_TABLE_NAME,
    pg_catalog.to_jsonb(NEW)
  );

  CASE TG_TABLE_NAME
    WHEN 'customers' THEN
      v_module := 'customers';
      v_entity_type := 'customer';
      v_entity_id := NEW.id::text;
      v_entity_display_name := NEW.name;

      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'customer_created';
      ELSIF OLD.is_active AND NOT NEW.is_active THEN
        v_action := 'deactivated';
        v_event := 'customer_deactivated';
      ELSIF NOT OLD.is_active AND NEW.is_active THEN
        v_action := 'reactivated';
        v_event := 'customer_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'customer_updated';
      END IF;

    WHEN 'routes' THEN
      v_module := 'routes';
      v_entity_type := 'route';
      v_entity_id := NEW.id::text;
      v_entity_display_name :=
        NEW.loading_location || ' → ' || NEW.unloading_location;

      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'route_created';
      ELSIF OLD.is_active AND NOT NEW.is_active THEN
        v_action := 'deactivated';
        v_event := 'route_deactivated';
      ELSIF NOT OLD.is_active AND NEW.is_active THEN
        v_action := 'reactivated';
        v_event := 'route_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'route_updated';
      END IF;

    WHEN 'drivers' THEN
      v_module := 'drivers';
      v_entity_type := 'driver';
      v_entity_id := NEW.id::text;
      v_entity_display_name := NEW.full_name;

      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'driver_created';
      ELSIF OLD.is_active AND NOT NEW.is_active THEN
        v_action := 'deactivated';
        v_event := 'driver_deactivated';
      ELSIF NOT OLD.is_active AND NEW.is_active THEN
        v_action := 'reactivated';
        v_event := 'driver_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'driver_updated';
      END IF;

    WHEN 'tractor_heads' THEN
      v_module := 'fleet';
      v_entity_type := 'tractor_head';
      v_entity_id := NEW.id::text;
      v_entity_display_name := NEW.plate_number;

      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'tractor_head_created';
      ELSIF OLD.is_active AND NOT NEW.is_active THEN
        v_action := 'deactivated';
        v_event := 'tractor_head_deactivated';
      ELSIF NOT OLD.is_active AND NEW.is_active THEN
        v_action := 'reactivated';
        v_event := 'tractor_head_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'tractor_head_updated';
      END IF;

    WHEN 'trailers' THEN
      v_module := 'fleet';
      v_entity_type := 'trailer';
      v_entity_id := NEW.id::text;
      v_entity_display_name := NEW.plate_number;

      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'trailer_created';
      ELSIF OLD.is_active AND NOT NEW.is_active THEN
        v_action := 'deactivated';
        v_event := 'trailer_deactivated';
      ELSIF NOT OLD.is_active AND NEW.is_active THEN
        v_action := 'reactivated';
        v_event := 'trailer_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'trailer_updated';
      END IF;

    WHEN 'payment_methods' THEN
      v_module := 'company_settings';
      v_entity_type := 'payment_method';
      v_entity_id := NEW.id::text;
      v_entity_display_name := NEW.name;

      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'payment_method_created';
      ELSIF OLD.is_active AND NOT NEW.is_active THEN
        v_action := 'deactivated';
        v_event := 'payment_method_deactivated';
      ELSIF NOT OLD.is_active AND NEW.is_active THEN
        v_action := 'reactivated';
        v_event := 'payment_method_reactivated';
      ELSE
        v_action := 'updated';
        v_event := 'payment_method_updated';
      END IF;

    WHEN 'company_expenses' THEN
      v_module := 'expenses';
      v_entity_type := 'expense';
      v_entity_id := NEW.id::text;
      v_entity_display_name := 'company_expense';

      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'company_expense_created';
      ELSIF NOT OLD.is_voided AND NEW.is_voided THEN
        v_action := 'status_changed';
        v_event := 'company_expense_voided';
      ELSE
        v_action := 'updated';
        v_event := 'company_expense_updated';
      END IF;

      v_metadata := pg_catalog.jsonb_build_object(
        'amount', NEW.amount,
        'category_id', NEW.category_id,
        'driver_id', NEW.driver_id,
        'tractor_head_id', NEW.tractor_head_id,
        'trailer_id', NEW.trailer_id,
        'trip_id', NEW.trip_id
      );

    WHEN 'driver_financial_movements' THEN
      IF TG_OP <> 'INSERT' THEN
        RETURN NEW;
      END IF;

      v_module := 'drivers';
      v_entity_type := 'driver';
      v_entity_id := NEW.driver_id::text;
      v_entity_display_name := 'driver_financial_movement';
      v_action := 'created';
      v_event := 'driver_finance_movement_added';
      v_metadata := pg_catalog.jsonb_build_object(
        'movement_id', NEW.id,
        'movement_type', NEW.movement_type,
        'amount', NEW.amount,
        'amount_minor_units', NEW.amount_minor_units,
        'currency_code', NEW.currency_code,
        'currency_fraction_digits', NEW.currency_fraction_digits,
        'trip_id', NEW.trip_id
      );

    WHEN 'driver_compensation_revisions' THEN
      v_module := 'drivers';
      v_entity_type := 'driver_compensation_revision';
      v_entity_id := NEW.id::text;

      IF TG_OP = 'INSERT' THEN
        v_action := 'created';
        v_event := 'driver_compensation_revision_created';
      ELSIF OLD.effective_to IS DISTINCT FROM NEW.effective_to
        AND NEW.effective_to IS NOT NULL THEN
        v_action := 'updated';
        v_event := 'driver_compensation_revision_ended';
      ELSIF OLD.contract_document_reference IS DISTINCT FROM
          NEW.contract_document_reference
        AND NEW.contract_document_reference IS NOT NULL THEN
        v_action := 'updated';
        v_event := 'driver_compensation_contract_attached';
      ELSE
        RETURN NEW;
      END IF;

      v_metadata := pg_catalog.jsonb_build_object(
        'driver_id', NEW.driver_id,
        'compensation_revision_id', NEW.id
      );

    WHEN 'driver_settlements' THEN
      v_module := 'drivers';
      v_entity_type := 'driver';
      v_entity_id := NEW.driver_id::text;
      v_entity_display_name := 'driver_settlement';

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

      -- Settlement items are inserted after the settlement row on create.
      -- Avoid recording a false zero item count in the creation snapshot.
      -- On status changes the item set is already complete and stable.
      IF TG_OP = 'UPDATE' THEN
        v_new_values := v_new_values
          || pg_catalog.jsonb_build_object(
            'items_count',
            (
              SELECT pg_catalog.count(*)
              FROM public.driver_settlement_items AS item_row
              WHERE item_row.company_id = NEW.company_id
                AND item_row.settlement_id = NEW.id
            )
          );

        IF v_old_values IS NOT NULL THEN
          v_old_values := v_old_values
            || pg_catalog.jsonb_build_object(
              'items_count',
              (
                SELECT pg_catalog.count(*)
                FROM public.driver_settlement_items AS item_row
                WHERE item_row.company_id = OLD.company_id
                  AND item_row.settlement_id = OLD.id
              )
            );
        END IF;
      END IF;

      v_metadata := pg_catalog.jsonb_build_object(
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
        'net_salary_payable_minor_units',
          NEW.net_salary_payable_minor_units,
        'gross_salary_minor_units', NEW.gross_salary_minor_units
      );

    ELSE
      RAISE EXCEPTION USING
        ERRCODE = 'P2820',
        MESSAGE = 'unsupported_legacy_audit_table';
  END CASE;

  PERFORM private.write_audit_event(
    NEW.company_id,
    v_module,
    v_entity_type,
    v_entity_id,
    v_entity_display_name,
    v_action,
    v_event,
    v_old_values,
    v_new_values,
    v_metadata
  );

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.write_legacy_table_audit_event()
  FROM PUBLIC;

DROP TRIGGER IF EXISTS customers_server_audit ON public.customers;
CREATE TRIGGER customers_server_audit
AFTER INSERT OR UPDATE ON public.customers
FOR EACH ROW EXECUTE FUNCTION private.write_legacy_table_audit_event();

DROP TRIGGER IF EXISTS routes_server_audit ON public.routes;
CREATE TRIGGER routes_server_audit
AFTER INSERT OR UPDATE ON public.routes
FOR EACH ROW EXECUTE FUNCTION private.write_legacy_table_audit_event();

DROP TRIGGER IF EXISTS drivers_server_audit ON public.drivers;
CREATE TRIGGER drivers_server_audit
AFTER INSERT OR UPDATE ON public.drivers
FOR EACH ROW EXECUTE FUNCTION private.write_legacy_table_audit_event();

DROP TRIGGER IF EXISTS tractor_heads_server_audit ON public.tractor_heads;
CREATE TRIGGER tractor_heads_server_audit
AFTER INSERT OR UPDATE ON public.tractor_heads
FOR EACH ROW EXECUTE FUNCTION private.write_legacy_table_audit_event();

DROP TRIGGER IF EXISTS trailers_server_audit ON public.trailers;
CREATE TRIGGER trailers_server_audit
AFTER INSERT OR UPDATE ON public.trailers
FOR EACH ROW EXECUTE FUNCTION private.write_legacy_table_audit_event();

DROP TRIGGER IF EXISTS payment_methods_server_audit ON public.payment_methods;
CREATE TRIGGER payment_methods_server_audit
AFTER INSERT OR UPDATE ON public.payment_methods
FOR EACH ROW EXECUTE FUNCTION private.write_legacy_table_audit_event();

DROP TRIGGER IF EXISTS company_expenses_server_audit ON public.company_expenses;
CREATE TRIGGER company_expenses_server_audit
AFTER INSERT OR UPDATE ON public.company_expenses
FOR EACH ROW EXECUTE FUNCTION private.write_legacy_table_audit_event();

DROP TRIGGER IF EXISTS driver_financial_movements_server_audit
  ON public.driver_financial_movements;
CREATE TRIGGER driver_financial_movements_server_audit
AFTER INSERT ON public.driver_financial_movements
FOR EACH ROW EXECUTE FUNCTION private.write_legacy_table_audit_event();

DROP TRIGGER IF EXISTS driver_compensation_revisions_server_audit
  ON public.driver_compensation_revisions;
CREATE TRIGGER driver_compensation_revisions_server_audit
AFTER INSERT OR UPDATE ON public.driver_compensation_revisions
FOR EACH ROW EXECUTE FUNCTION private.write_legacy_table_audit_event();

DROP TRIGGER IF EXISTS driver_settlements_server_audit
  ON public.driver_settlements;
CREATE TRIGGER driver_settlements_server_audit
AFTER INSERT OR UPDATE ON public.driver_settlements
FOR EACH ROW EXECUTE FUNCTION private.write_legacy_table_audit_event();

DROP POLICY IF EXISTS audit_logs_insert_company_members
  ON public.audit_logs;

REVOKE INSERT ON TABLE public.audit_logs FROM authenticated;

COMMIT;
