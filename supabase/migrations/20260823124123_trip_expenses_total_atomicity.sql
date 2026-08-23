-- H.O.R.U.S System — Issue #135
-- Keep trips.total_expenses as a DB-owned derived cache of trip_expenses.amount.
--
-- The one-time reconciliation establishes the invariant for existing data.
-- The trigger then maintains the cache with atomic deltas so concurrent expense
-- writes cannot lose each other's committed changes.

BEGIN;

WITH expected_totals AS (
  SELECT
    trip_row.company_id,
    trip_row.id AS trip_id,
    COALESCE(pg_catalog.sum(expense_row.amount), 0::numeric) AS total_expenses
  FROM public.trips AS trip_row
  LEFT JOIN public.trip_expenses AS expense_row
    ON expense_row.company_id = trip_row.company_id
   AND expense_row.trip_id = trip_row.id
  GROUP BY trip_row.company_id, trip_row.id
)
UPDATE public.trips AS trip_row
SET total_expenses = expected_row.total_expenses
FROM expected_totals AS expected_row
WHERE trip_row.company_id = expected_row.company_id
  AND trip_row.id = expected_row.trip_id
  AND trip_row.total_expenses IS DISTINCT FROM expected_row.total_expenses;

CREATE OR REPLACE FUNCTION private.maintain_trip_expense_total()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.trips AS trip_row
    SET total_expenses = trip_row.total_expenses + NEW.amount
    WHERE trip_row.company_id = NEW.company_id
      AND trip_row.id = NEW.trip_id;

    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    UPDATE public.trips AS trip_row
    SET total_expenses = trip_row.total_expenses - OLD.amount
    WHERE trip_row.company_id = OLD.company_id
      AND trip_row.id = OLD.trip_id;

    RETURN OLD;
  END IF;

  IF OLD.company_id = NEW.company_id
     AND OLD.trip_id = NEW.trip_id THEN
    IF OLD.amount IS DISTINCT FROM NEW.amount THEN
      UPDATE public.trips AS trip_row
      SET total_expenses =
        trip_row.total_expenses + (NEW.amount - OLD.amount)
      WHERE trip_row.company_id = NEW.company_id
        AND trip_row.id = NEW.trip_id;
    END IF;

    RETURN NEW;
  END IF;

  -- A moved expense touches two parent rows. Acquire those row locks in a stable
  -- tenant/trip order to avoid opposite-direction moves deadlocking each other.
  IF (OLD.company_id, OLD.trip_id) < (NEW.company_id, NEW.trip_id) THEN
    UPDATE public.trips AS trip_row
    SET total_expenses = trip_row.total_expenses - OLD.amount
    WHERE trip_row.company_id = OLD.company_id
      AND trip_row.id = OLD.trip_id;

    UPDATE public.trips AS trip_row
    SET total_expenses = trip_row.total_expenses + NEW.amount
    WHERE trip_row.company_id = NEW.company_id
      AND trip_row.id = NEW.trip_id;
  ELSE
    UPDATE public.trips AS trip_row
    SET total_expenses = trip_row.total_expenses + NEW.amount
    WHERE trip_row.company_id = NEW.company_id
      AND trip_row.id = NEW.trip_id;

    UPDATE public.trips AS trip_row
    SET total_expenses = trip_row.total_expenses - OLD.amount
    WHERE trip_row.company_id = OLD.company_id
      AND trip_row.id = OLD.trip_id;
  END IF;

  RETURN NEW;
END;
$$;

ALTER FUNCTION private.maintain_trip_expense_total() OWNER TO postgres;

REVOKE ALL ON FUNCTION private.maintain_trip_expense_total() FROM PUBLIC;
REVOKE ALL ON FUNCTION private.maintain_trip_expense_total() FROM anon;
REVOKE ALL ON FUNCTION private.maintain_trip_expense_total() FROM authenticated;

DROP TRIGGER IF EXISTS trip_expenses_maintain_total_expenses
ON public.trip_expenses;

CREATE TRIGGER trip_expenses_maintain_total_expenses
AFTER INSERT OR UPDATE OR DELETE
ON public.trip_expenses
FOR EACH ROW
EXECUTE FUNCTION private.maintain_trip_expense_total();

COMMIT;
