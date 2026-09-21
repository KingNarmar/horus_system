-- H.O.R.U.S System — Issue #241 / PC-17
-- Align server-side read authorization with the established Domain role matrix.
--
-- Security intent:
-- - Driver remains an authenticated company member for company-context purposes.
-- - Driver must not gain read access to operational, financial, personnel, or
--   document data that Domain policies explicitly deny.
-- - Current Company bootstrap keeps self-membership access.
-- - Company Users management keeps full membership visibility for Owner/Admin.
-- - Platform-admin visibility remains unchanged.
-- - No business data is rewritten by this migration.

BEGIN;

-- Customers: remove the legacy broad member policy and make the canonical
-- SELECT policy match CustomersPermissionPolicy.canViewCustomers.
DROP POLICY IF EXISTS "Company members can read customers"
  ON public.customers;
DROP POLICY IF EXISTS customers_select_members
  ON public.customers;

CREATE POLICY customers_select_members
ON public.customers
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

-- Drivers: remove the legacy broad member policy and align visibility with
-- DriversPermissionPolicy.canViewDrivers.
DROP POLICY IF EXISTS drivers_select_company_members
  ON public.drivers;
DROP POLICY IF EXISTS drivers_select_members
  ON public.drivers;

CREATE POLICY drivers_select_members
ON public.drivers
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

-- Routes.
DROP POLICY IF EXISTS routes_select_members
  ON public.routes;

CREATE POLICY routes_select_members
ON public.routes
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

-- Trips.
DROP POLICY IF EXISTS trips_select_members
  ON public.trips;

CREATE POLICY trips_select_members
ON public.trips
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

-- Trip status history follows Trips visibility.
DROP POLICY IF EXISTS trip_status_history_select_members
  ON public.trip_status_history;

CREATE POLICY trip_status_history_select_members
ON public.trip_status_history
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

-- Expense Types.
DROP POLICY IF EXISTS expense_types_select_members
  ON public.expense_types;

CREATE POLICY expense_types_select_members
ON public.expense_types
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

-- Driver Finance read models. Grants remain an additional boundary where
-- direct table access is intentionally narrower.
DROP POLICY IF EXISTS driver_financial_movements_select_company_members
  ON public.driver_financial_movements;

CREATE POLICY driver_financial_movements_select_company_roles
ON public.driver_financial_movements
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

DROP POLICY IF EXISTS driver_advances_select_members
  ON public.driver_advances;

CREATE POLICY driver_advances_select_company_roles
ON public.driver_advances
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

DROP POLICY IF EXISTS driver_deductions_select_members
  ON public.driver_deductions;

CREATE POLICY driver_deductions_select_company_roles
ON public.driver_deductions
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

-- Company Context requires each active member to read their own membership.
-- Full company-member listing is a Company Users management capability and is
-- limited to active Owner/Admin actors (plus the existing platform-admin path).
DROP POLICY IF EXISTS company_users_select_company_members
  ON public.company_users;

CREATE POLICY company_users_select_self_managers_or_platform_admin
ON public.company_users
FOR SELECT
TO authenticated
USING (
  (
    user_id = auth.uid()
    AND is_active = true
  )
  OR private.has_company_role(
    company_id,
    ARRAY['owner', 'admin']::public.company_role[]
  )
  OR private.is_platform_admin()
);

-- Preserve own-profile access through the existing
-- user_profiles_select_own_or_platform_admin policy. Shared-company profile
-- enrichment is only required by Owner/Admin Company Users management.
DROP POLICY IF EXISTS user_profiles_select_shared_company_members
  ON public.user_profiles;

CREATE POLICY user_profiles_select_shared_company_managers
ON public.user_profiles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.company_users AS viewer_membership
    JOIN public.company_users AS target_membership
      ON target_membership.company_id = viewer_membership.company_id
    WHERE viewer_membership.user_id = auth.uid()
      AND viewer_membership.is_active = true
      AND viewer_membership.role IN (
        'owner'::public.company_role,
        'admin'::public.company_role
      )
      AND target_membership.user_id = user_profiles.id
      AND target_membership.is_active = true
  )
);

-- Driver documents are personnel documents. Visibility follows the Driver
-- feature view matrix and explicitly excludes CompanyRole.driver.
DROP POLICY IF EXISTS driver_documents_select_company_members
  ON storage.objects;

CREATE POLICY driver_documents_select_company_roles
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'driver-documents'
  AND private.has_company_role(
    private.driver_document_company_id(name),
    ARRAY[
      'owner',
      'admin',
      'operations',
      'accountant',
      'viewer'
    ]::public.company_role[]
  )
);

COMMIT;
