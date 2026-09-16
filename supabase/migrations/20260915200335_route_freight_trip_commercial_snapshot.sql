-- Issue #231 / PC-07 - Route freight pricing + immutable Trip commercial snapshot.
--
-- Physical compatibility is intentional:
--   * routes.default_freight_price remains the persisted Route default rate per ton.
--   * trips.freight_price remains the persisted Trip commercial amount.
-- Existing invoice/report functions depend on those physical column names.
-- The new agreed_freight_rate_per_ton column records the historical Trip rate.

ALTER TABLE public.trips
  ADD COLUMN IF NOT EXISTS agreed_freight_rate_per_ton numeric;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.routes'::regclass
      AND conname = 'routes_default_freight_price_nonnegative'
  ) THEN
    ALTER TABLE public.routes
      ADD CONSTRAINT routes_default_freight_price_nonnegative
      CHECK (
        default_freight_price IS NULL
        OR default_freight_price >= 0
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.routes'::regclass
      AND conname = 'routes_default_freight_price_scale'
  ) THEN
    ALTER TABLE public.routes
      ADD CONSTRAINT routes_default_freight_price_scale
      CHECK (
        default_freight_price IS NULL
        OR scale(default_freight_price) <= 4
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.trips'::regclass
      AND conname = 'trips_quantity_tons_nonnegative'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_quantity_tons_nonnegative
      CHECK (quantity_tons IS NULL OR quantity_tons >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.trips'::regclass
      AND conname = 'trips_quantity_tons_scale'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_quantity_tons_scale
      CHECK (quantity_tons IS NULL OR scale(quantity_tons) <= 3);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.trips'::regclass
      AND conname = 'trips_freight_price_nonnegative'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_freight_price_nonnegative
      CHECK (freight_price IS NULL OR freight_price >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.trips'::regclass
      AND conname = 'trips_freight_price_scale'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_freight_price_scale
      CHECK (freight_price IS NULL OR scale(freight_price) <= 4);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.trips'::regclass
      AND conname = 'trips_agreed_freight_rate_nonnegative'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_agreed_freight_rate_nonnegative
      CHECK (
        agreed_freight_rate_per_ton IS NULL
        OR agreed_freight_rate_per_ton >= 0
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.trips'::regclass
      AND conname = 'trips_agreed_freight_rate_scale'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_agreed_freight_rate_scale
      CHECK (
        agreed_freight_rate_per_ton IS NULL
        OR scale(agreed_freight_rate_per_ton) <= 4
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.trips'::regclass
      AND conname = 'trips_commercial_snapshot_components'
  ) THEN
    ALTER TABLE public.trips
      ADD CONSTRAINT trips_commercial_snapshot_components
      CHECK (
        agreed_freight_rate_per_ton IS NULL
        OR (quantity_tons IS NOT NULL AND freight_price IS NOT NULL)
      );
  END IF;
END $$;

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
      SELECT 1
      FROM public.expense_ledger_entries AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.company_expenses AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_financial_movements AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_advances AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_deductions AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_settlements AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.driver_settlement_items AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.invoices AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.invoice_lines AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.payments AS row
      WHERE row.company_id = p_company_id
    )
    OR EXISTS (
      SELECT 1
      FROM public.trips AS row
      WHERE row.company_id = p_company_id
        AND (
          coalesce(row.freight_price, 0::numeric) <> 0
          OR coalesce(row.agreed_freight_rate_per_ton, 0::numeric) <> 0
          OR coalesce(row.total_expenses, 0::numeric) <> 0
        )
    )
    OR EXISTS (
      SELECT 1
      FROM public.routes AS row
      WHERE row.company_id = p_company_id
        AND coalesce(row.default_freight_price, 0::numeric) <> 0
    )
    OR EXISTS (
      SELECT 1
      FROM public.customers AS row
      WHERE row.company_id = p_company_id
        AND coalesce(row.credit_limit, 0::numeric) <> 0
    );
END;
$function$;

COMMENT ON COLUMN public.routes.default_freight_price IS
  'Default freight rate per ton in the company base currency. Physical name retained for compatibility.';

COMMENT ON COLUMN public.trips.freight_price IS
  'Historical Trip commercial amount in the company base currency. Physical name retained for compatibility.';

COMMENT ON COLUMN public.trips.agreed_freight_rate_per_ton IS
  'Historical agreed freight rate per ton in the company base currency. NULL for legacy Trips without authoritative rate history.';
