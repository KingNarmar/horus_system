-- H.O.R.U.S System — Issue #272 / PC-17 follow-up
-- Preserve readable identity for inactive company members without broadening
-- generic user_profiles visibility.
--
-- Security contract:
-- - only authenticated active Owner/Admin actors of the requested company
--   may use this management projection;
-- - inactive target memberships remain readable to those authorized managers;
-- - the function returns only fields required by Company Users management;
-- - generic user_profiles RLS remains unchanged.

BEGIN;

CREATE OR REPLACE FUNCTION public.list_company_users_for_management(
  p_company_id uuid
)
RETURNS TABLE(
  membership_id uuid,
  company_id uuid,
  user_id uuid,
  member_role public.company_role,
  is_active boolean,
  full_name text,
  phone text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role public.company_role;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2830',
      MESSAGE = 'company_auth_required';
  END IF;

  SELECT company_user.role
  INTO v_actor_role
  FROM public.company_users AS company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true;

  IF NOT FOUND OR v_actor_role NOT IN (
    'owner'::public.company_role,
    'admin'::public.company_role
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2831',
      MESSAGE = 'company_users_permission_denied';
  END IF;

  RETURN QUERY
  SELECT
    company_user.id,
    company_user.company_id,
    company_user.user_id,
    company_user.role,
    company_user.is_active,
    user_profile.full_name,
    user_profile.phone
  FROM public.company_users AS company_user
  LEFT JOIN public.user_profiles AS user_profile
    ON user_profile.id = company_user.user_id
  WHERE company_user.company_id = p_company_id
  ORDER BY company_user.created_at, company_user.id;
END;
$function$;

REVOKE ALL ON FUNCTION public.list_company_users_for_management(uuid)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_company_users_for_management(uuid)
  FROM anon;
GRANT EXECUTE ON FUNCTION public.list_company_users_for_management(uuid)
  TO authenticated;

COMMIT;
