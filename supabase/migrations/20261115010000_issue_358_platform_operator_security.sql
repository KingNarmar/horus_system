-- Issue #358: operator trust boundary. Source-only: DO NOT apply to hosted
-- Development or Production without separate migration approval.
BEGIN;

-- Platform privileges are not company memberships. No client can write this
-- registry; initial trusted operators require an independently reviewed,
-- audited operator-provisioning migration.
CREATE TABLE private.platform_operator_access (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id),
  permissions text[] NOT NULL,
  approved_reason text NOT NULL CHECK (
    length(btrim(approved_reason)) BETWEEN 8 AND 500
  ),
  approved_at timestamptz NOT NULL DEFAULT now(),
  approved_by uuid,
  revoked_at timestamptz,
  revised_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT platform_operator_permissions_nonempty
    CHECK (array_length(permissions, 1) > 0),
  CONSTRAINT platform_operator_permissions_known CHECK (
    permissions <@ ARRAY[
      'tenant_read','usage_read','override_read','override_write',
      'creation_grant_write','audit_read','membership_recovery',
      'operator_manage'
    ]::text[]
  )
);
CREATE INDEX platform_operator_access_active_idx
  ON private.platform_operator_access (user_id) WHERE revoked_at IS NULL;
ALTER TABLE private.platform_operator_access ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.platform_operator_access FROM PUBLIC, anon, authenticated;

-- Write-once platform audit, separate from company audit. Operator identity
-- provisioning and grant transactions must never depend on client audit writes.
CREATE TABLE private.platform_operator_audit (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid,
  target_user_id uuid,
  actor_user_id uuid,
  actor_session_id uuid,
  action text NOT NULL,
  reason text NOT NULL CHECK (length(btrim(reason)) BETWEEN 8 AND 500),
  request_id uuid,
  request_fingerprint text,
  old_values jsonb,
  new_values jsonb,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT platform_operator_audit_request_pair CHECK (
    (request_id IS NULL AND request_fingerprint IS NULL)
    OR (request_id IS NOT NULL AND request_fingerprint IS NOT NULL)
  ),
  CONSTRAINT platform_operator_audit_actor_request_unique
    UNIQUE (actor_user_id, request_id)
);
CREATE INDEX platform_operator_audit_company_idx
  ON private.platform_operator_audit (company_id, occurred_at DESC, id DESC);
CREATE INDEX platform_operator_audit_target_user_idx
  ON private.platform_operator_audit (target_user_id, occurred_at DESC);
ALTER TABLE private.platform_operator_audit ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.platform_operator_audit FROM PUBLIC, anon, authenticated;

CREATE FUNCTION private.reject_platform_operator_audit_changes()
RETURNS trigger LANGUAGE plpgsql SET search_path = pg_catalog
AS $$
BEGIN
  RAISE EXCEPTION USING ERRCODE='P3580',
    MESSAGE='platform_audit_immutable';
END;
$$;
CREATE TRIGGER platform_operator_audit_append_only
BEFORE UPDATE OR DELETE ON private.platform_operator_audit
FOR EACH ROW EXECUTE FUNCTION private.reject_platform_operator_audit_changes();

-- Platform operator bootstrap / revocation is DB-owner-only by design.
-- Even privileged maintenance writes to the registry must produce an audit.
CREATE FUNCTION private.audit_platform_operator_access()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO private.platform_operator_audit (
      target_user_id,actor_user_id,actor_session_id,action,reason,
      old_values,new_values
    ) VALUES (
      NEW.user_id,auth.uid(),
      CASE WHEN (auth.jwt()->>'session_id') ~*
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        THEN (auth.jwt()->>'session_id')::uuid ELSE NULL END,
      'operator_access_created',NEW.approved_reason,NULL,
      jsonb_build_object('permissions',NEW.permissions,
        'revoked_at',NEW.revoked_at)
    );
  ELSE
    INSERT INTO private.platform_operator_audit (
      target_user_id,actor_user_id,actor_session_id,action,reason,
      old_values,new_values
    ) VALUES (
      NEW.user_id,auth.uid(),
      CASE WHEN (auth.jwt()->>'session_id') ~*
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        THEN (auth.jwt()->>'session_id')::uuid ELSE NULL END,
      CASE WHEN NEW.revoked_at IS NOT NULL AND OLD.revoked_at IS NULL
        THEN 'operator_access_revoked' ELSE 'operator_access_updated' END,
      NEW.approved_reason,
      jsonb_build_object('permissions',OLD.permissions,
        'revoked_at',OLD.revoked_at),
      jsonb_build_object('permissions',NEW.permissions,
        'revoked_at',NEW.revoked_at)
    );
  END IF;
  RETURN NULL;
END;
$$;
CREATE TRIGGER platform_operator_access_audit
AFTER INSERT OR UPDATE ON private.platform_operator_access
FOR EACH ROW EXECUTE FUNCTION private.audit_platform_operator_access();

-- A signed JWT is necessary but insufficient for privileged operations.
-- Verify the *current* server-owned operator privilege, active user, live
-- session and verified MFA factor on EACH protected RPC. Sensitive mutations
-- additionally require a recent MFA challenge (not merely token refresh).
CREATE FUNCTION private.platform_operator_authorized(
  p_permission text, p_sensitive boolean DEFAULT false
)
RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_claims jsonb := auth.jwt();
  v_session_id text := auth.jwt()->>'session_id';
BEGIN
  IF v_actor IS NULL
    OR p_permission IS NULL
    OR v_session_id IS NULL
    OR v_session_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    OR v_claims->>'sub' IS DISTINCT FROM v_actor::text
    OR v_claims->>'role' IS DISTINCT FROM 'authenticated'
    OR v_claims->>'aal' IS DISTINCT FROM 'aal2'
    OR COALESCE(v_claims->>'exp','') !~ '^[0-9]+$'
    OR (v_claims->>'exp')::bigint <= extract(epoch FROM now())
  THEN
    RETURN false;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM private.platform_operator_access access
    JOIN public.user_profiles profile ON profile.id=access.user_id
    JOIN auth.users account ON account.id=access.user_id
    JOIN auth.sessions session ON session.id=v_session_id::uuid
      AND session.user_id=access.user_id
    JOIN auth.mfa_factors factor ON factor.id=session.factor_id
      AND factor.user_id=access.user_id
    WHERE access.user_id=v_actor
      AND access.revoked_at IS NULL
      AND p_permission=ANY(access.permissions)
      AND profile.is_platform_admin IS TRUE
      AND account.deleted_at IS NULL
      AND account.is_anonymous IS NOT TRUE
      AND (account.banned_until IS NULL OR account.banned_until<=now())
      AND (session.not_after IS NULL OR session.not_after>now())
      AND session.aal::text='aal2'
      AND factor.status::text='verified'
      AND (NOT p_sensitive OR (
        factor.last_challenged_at IS NOT NULL
        AND factor.last_challenged_at >= now()-interval '15 minutes'
      ))
  );
END;
$$;
REVOKE ALL ON FUNCTION private.platform_operator_authorized(text,boolean)
  FROM PUBLIC,anon,authenticated;

CREATE FUNCTION private.require_platform_operator(
  p_permission text, p_sensitive boolean DEFAULT false
)
RETURNS uuid LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path=pg_catalog
AS $$
BEGIN
  IF private.platform_operator_authorized(p_permission,p_sensitive) IS NOT TRUE
  THEN
    RAISE EXCEPTION USING ERRCODE='42501',
      MESSAGE='platform_operator_forbidden';
  END IF;
  RETURN auth.uid();
END;
$$;
REVOKE ALL ON FUNCTION private.require_platform_operator(text,boolean)
  FROM PUBLIC,anon,authenticated;

-- Preserve Issue #370's narrowly audited membership recovery RPC while
-- removing the old flag-only helper from tenant RLS and requiring fresh MFA.
CREATE OR REPLACE FUNCTION private.is_platform_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
  SELECT private.platform_operator_authorized('membership_recovery',true)
$$;
REVOKE ALL ON FUNCTION private.is_platform_admin() FROM PUBLIC,anon;
-- Existing #370 uses this helper inside SECURITY DEFINER; retain its
-- existing authenticated EXECUTE permission for compatibility.

-- An operator's tenant-directory access is a narrow DTO, not blanket
-- access to company rows, staff profiles, invitations or private files.
DROP POLICY IF EXISTS companies_select_member_or_platform_admin
  ON public.companies;
CREATE POLICY companies_select_member_or_platform_admin
  ON public.companies FOR SELECT TO authenticated
  USING (private.is_company_member(id));

DROP POLICY IF EXISTS companies_update_owner_admin_or_platform_admin
  ON public.companies;
CREATE POLICY companies_update_owner_admin_or_platform_admin
  ON public.companies FOR UPDATE TO authenticated
  USING (private.has_company_role(id,ARRAY['owner','admin']::public.company_role[]))
  WITH CHECK (private.has_company_role(id,ARRAY['owner','admin']::public.company_role[]));

DROP POLICY IF EXISTS company_subscriptions_select_owner_or_platform_admin
  ON public.company_subscriptions;
CREATE POLICY company_subscriptions_select_owner_or_platform_admin
  ON public.company_subscriptions FOR SELECT TO authenticated
  USING (private.has_company_role(company_id,ARRAY['owner']::public.company_role[]));

DROP POLICY IF EXISTS company_users_select_self_managers_or_platform_admin
  ON public.company_users;
CREATE POLICY company_users_select_self_managers_or_platform_admin
  ON public.company_users FOR SELECT TO authenticated
  USING (
    (user_id=auth.uid() AND is_active)
    OR private.has_company_role(company_id,ARRAY['owner','admin']::public.company_role[])
  );

DROP POLICY IF EXISTS company_invitations_select_managers
  ON public.company_invitations;
CREATE POLICY company_invitations_select_managers
  ON public.company_invitations FOR SELECT TO authenticated
  USING (private.has_company_role(company_id,ARRAY['owner','admin']::public.company_role[]));

DROP POLICY IF EXISTS audit_logs_select_owner_admin_or_platform_admin
  ON public.audit_logs;
CREATE POLICY audit_logs_select_owner_admin_or_platform_admin
  ON public.audit_logs FOR SELECT TO authenticated
  USING (private.has_company_role(company_id,ARRAY['owner','admin']::public.company_role[]));

DROP POLICY IF EXISTS subscription_plans_select_active_or_platform_admin
  ON public.subscription_plans;
CREATE POLICY subscription_plans_select_active_or_platform_admin
  ON public.subscription_plans FOR SELECT TO authenticated
  USING (is_active IS TRUE);

DROP POLICY IF EXISTS user_profiles_select_own_or_platform_admin
  ON public.user_profiles;
CREATE POLICY user_profiles_select_own_or_platform_admin
  ON public.user_profiles FOR SELECT TO authenticated
  USING (id=auth.uid());

DROP POLICY IF EXISTS user_profiles_update_own_or_platform_admin
  ON public.user_profiles;
CREATE POLICY user_profiles_update_own_or_platform_admin
  ON public.user_profiles FOR UPDATE TO authenticated
  USING (id=auth.uid())
  WITH CHECK (id=auth.uid());

-- Read APIs expose only deliberately selected attributes.
CREATE FUNCTION public.platform_list_tenants(
  p_search text DEFAULT NULL, p_after_company_id uuid DEFAULT NULL,
  p_page_size integer DEFAULT 25
)
RETURNS TABLE (
  company_id uuid, company_name text, company_active boolean,
  plan_code text, subscription_revision integer, created_at timestamptz
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE v_term text := NULLIF(btrim(p_search),'');
BEGIN
  PERFORM private.require_platform_operator('tenant_read',false);
  IF p_page_size IS NULL OR p_page_size NOT BETWEEN 1 AND 100
    OR (v_term IS NOT NULL AND length(v_term)>80)
  THEN
    RAISE EXCEPTION USING ERRCODE='22023',
      MESSAGE='platform_directory_invalid_filter';
  END IF;
  RETURN QUERY
    SELECT c.id,c.name,c.is_active,sp.code,cs.revision,c.created_at
    FROM public.companies c
    LEFT JOIN public.company_subscriptions cs ON cs.company_id=c.id
    LEFT JOIN public.subscription_plans sp ON sp.id=cs.plan_id
    WHERE (p_after_company_id IS NULL OR c.id>p_after_company_id)
      AND (v_term IS NULL OR position(lower(v_term) IN lower(c.name))>0)
    ORDER BY c.id
    LIMIT p_page_size;
END;
$$;
REVOKE ALL ON FUNCTION public.platform_list_tenants(text,uuid,integer)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.platform_list_tenants(text,uuid,integer)
  TO authenticated;

CREATE FUNCTION public.platform_get_company_usage(p_company_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path=pg_catalog
AS $$
DECLARE v_entitlement jsonb;
BEGIN
  PERFORM private.require_platform_operator('usage_read',false);
  IF p_company_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='22023',
      MESSAGE='platform_company_id_required';
  END IF;
  v_entitlement:=private.resolve_company_effective_entitlement(p_company_id);
  RETURN jsonb_build_object(
    'entitlement',v_entitlement,
    'usage',jsonb_build_object(
      'company_users',private.company_quota_used(p_company_id,'company_users'),
      'combined_vehicles',private.company_quota_used(p_company_id,'combined_vehicles'),
      'customers',private.company_quota_used(p_company_id,'customers'),
      'drivers',private.company_quota_used(p_company_id,'drivers'),
      'routes',private.company_quota_used(p_company_id,'routes'),
      'lifetime_trips',private.company_quota_used(p_company_id,'lifetime_trips'),
      'lifetime_invoices',private.company_quota_used(p_company_id,'lifetime_invoices'),
      'business_documents',private.company_quota_used(p_company_id,'business_documents')
    )
  );
END;
$$;
REVOKE ALL ON FUNCTION public.platform_get_company_usage(uuid)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.platform_get_company_usage(uuid)
  TO authenticated;
-- Recovery lookup is intentionally scoped to ONE known membership. It
-- replaces the legacy unrestricted Platform Admin direct membership SELECT.
CREATE FUNCTION public.platform_get_membership_for_recovery(
  p_company_id uuid, p_membership_id uuid
)
RETURNS TABLE(
  membership_id uuid,membership_role public.company_role,
  membership_active boolean,membership_updated_at timestamptz
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
BEGIN
  PERFORM private.require_platform_operator('membership_recovery',true);
  IF p_company_id IS NULL OR p_membership_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='22023',
      MESSAGE='platform_recovery_invalid_target';
  END IF;
  RETURN QUERY
  SELECT m.id,m.role,m.is_active,m.updated_at
  FROM public.company_users m
  WHERE m.company_id=p_company_id AND m.id=p_membership_id;
END;
$$;
REVOKE ALL ON FUNCTION public.platform_get_membership_for_recovery(uuid,uuid)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.platform_get_membership_for_recovery(uuid,uuid)
  TO authenticated;

COMMIT;
