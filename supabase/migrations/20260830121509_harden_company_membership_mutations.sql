-- H.O.R.U.S System — Issue #203 Company invitations and membership lifecycle
-- Remove broad Owner/Admin direct membership mutations while preserving the
-- existing initial self-Owner onboarding seam and platform-admin recovery.

BEGIN;

DROP POLICY IF EXISTS company_users_insert_initial_owner_or_admin
  ON public.company_users;

CREATE POLICY company_users_insert_initial_owner_or_platform_admin
ON public.company_users
FOR INSERT
TO authenticated
WITH CHECK (
  private.is_platform_admin()
  OR (
    user_id = auth.uid()
    AND role = 'owner'::public.company_role
    AND is_active = true
    AND private.user_created_company(company_id)
  )
);

DROP POLICY IF EXISTS company_users_update_owner_admin_or_platform_admin
  ON public.company_users;

CREATE POLICY company_users_update_platform_admin_only
ON public.company_users
FOR UPDATE
TO authenticated
USING (private.is_platform_admin())
WITH CHECK (private.is_platform_admin());

COMMIT;
