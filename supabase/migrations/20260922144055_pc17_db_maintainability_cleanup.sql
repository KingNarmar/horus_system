-- H.O.R.U.S System — Issue #241 / PC-17
-- Remove confirmed redundant database objects without changing behavior.
--
-- Keep the canonical table-prefixed company indexes and the constraint-backed
-- composite unique indexes. Remove only exact duplicates that add write/storage
-- overhead.
--
-- Keep the helper-based customer mutation policies. Remove only the legacy
-- policies with identical owner/admin/operations authorization semantics.

drop index if exists public.idx_customers_company_id;
drop index if exists public.idx_drivers_company_id;
drop index if exists public.customers_company_id_id_uidx;
drop index if exists public.trips_company_id_id_uidx;

drop policy if exists "Allowed company roles can create customers"
  on public.customers;
drop policy if exists "Allowed company roles can update customers"
  on public.customers;
