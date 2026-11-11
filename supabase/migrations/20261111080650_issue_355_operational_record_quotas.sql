-- Issue #355: active operational resource limits, server-authoritative.
-- No historical records are modified. Apply on Development only after separate approval.

CREATE OR REPLACE FUNCTION private.company_quota_used(
  p_company_id uuid, p_resource text
)
RETURNS bigint
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_used bigint;
BEGIN
  IF p_resource = 'company_users' THEN
    SELECT
      (SELECT pg_catalog.count(*)
       FROM public.company_users member
       WHERE member.company_id=p_company_id AND member.is_active=true)
      +
      (SELECT pg_catalog.count(*)
       FROM public.company_invitations invitation
       WHERE invitation.company_id=p_company_id
         AND invitation.status='pending'::public.company_invitation_status
         AND GREATEST(
           invitation.expires_at,
           COALESCE(
             invitation.pending_token_expires_at, invitation.expires_at
           )
         ) > pg_catalog.now()
         AND NOT EXISTS (
           SELECT 1
           FROM public.company_users active_member
           JOIN auth.users account ON account.id=active_member.user_id
           WHERE active_member.company_id=p_company_id
             AND active_member.is_active=true
             AND pg_catalog.lower(pg_catalog.btrim(account.email)) =
               invitation.email_normalized
         )
      )
      INTO v_used;
  ELSIF p_resource = 'combined_vehicles' THEN
    SELECT
      (SELECT pg_catalog.count(*) FROM public.tractor_heads
        WHERE company_id=p_company_id AND is_active=true)
      +
      (SELECT pg_catalog.count(*) FROM public.trailers
        WHERE company_id=p_company_id AND is_active=true)
      INTO v_used;
  ELSIF p_resource IN ('customers','drivers','routes') THEN
    -- Capacity is current active records, never historical creations.
    IF p_resource='customers' THEN
      SELECT pg_catalog.count(*) INTO v_used FROM public.customers
      WHERE company_id=p_company_id AND is_active=true;
    ELSIF p_resource='drivers' THEN
      SELECT pg_catalog.count(*) INTO v_used FROM public.drivers
      WHERE company_id=p_company_id AND is_active=true;
    ELSE
      SELECT pg_catalog.count(*) INTO v_used FROM public.routes
      WHERE company_id=p_company_id AND is_active=true;
    END IF;
  ELSE
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_unsupported_resource';
  END IF;
  RETURN v_used;
END;
$$;


CREATE OR REPLACE FUNCTION private.assert_company_quota_capacity(
  p_company_id uuid, p_resource text, p_additional integer
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_entitlement jsonb;
  v_limit_text text;
  v_limit bigint;
  v_used bigint;
BEGIN
  IF p_company_id IS NULL OR p_additional IS NULL OR p_additional <= 0 THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_invalid_request';
  END IF;
  IF p_resource NOT IN ('company_users', 'combined_vehicles',
                        'customers', 'drivers', 'routes')
     OR p_resource IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_unsupported_resource';
  END IF;

  PERFORM 1 FROM public.companies company_row
  WHERE company_row.id=p_company_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P2861',
      MESSAGE='quota_entitlement_unavailable';
  END IF;

  v_entitlement := private.resolve_company_effective_entitlement(p_company_id);
  IF v_entitlement->>'status' IS DISTINCT FROM 'active' THEN
    RAISE EXCEPTION USING ERRCODE='P2861',
      MESSAGE='quota_entitlement_unavailable';
  END IF;

  v_limit_text := v_entitlement->'limits'->>p_resource;
  IF v_limit_text IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_policy_invalid';
  END IF;
  IF v_limit_text='unlimited' THEN
    RETURN;
  END IF;
  IF v_limit_text !~ '^(0|[1-9][0-9]*)$' THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_policy_invalid';
  END IF;
  v_limit := v_limit_text::bigint;
  v_used := private.company_quota_used(p_company_id,p_resource);
  IF v_used+p_additional > v_limit THEN
    RAISE EXCEPTION USING ERRCODE='P2860',
      MESSAGE=CASE p_resource
        WHEN 'company_users' THEN 'quota_company_users_reached'
        WHEN 'combined_vehicles' THEN 'quota_combined_vehicles_reached'
        WHEN 'customers' THEN 'quota_customers_reached'
        WHEN 'drivers' THEN 'quota_drivers_reached'
        WHEN 'routes' THEN 'quota_routes_reached'
      END;
  END IF;
END;
$$;


CREATE OR REPLACE FUNCTION public.get_company_quota_usage(p_company_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog
AS $$
DECLARE
  v_entitlement jsonb;
BEGIN
  IF auth.uid() IS NULL OR p_company_id IS NULL OR NOT private.has_company_role(
    p_company_id,
    ARRAY['owner'::public.company_role, 'admin'::public.company_role]
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P2863',
      MESSAGE='quota_permission_denied';
  END IF;

  v_entitlement := private.resolve_company_effective_entitlement(p_company_id);
  RETURN pg_catalog.jsonb_build_object(
    'entitlement',v_entitlement,
    'usage',pg_catalog.jsonb_build_object(
      'company_users',private.company_quota_used(p_company_id,'company_users'),
      'combined_vehicles',private.company_quota_used(p_company_id,'combined_vehicles'),
      'customers',private.company_quota_used(p_company_id,'customers'),
      'drivers',private.company_quota_used(p_company_id,'drivers'),
      'routes',private.company_quota_used(p_company_id,'routes')
    )
  );
END;
$$;


-- A server-side BEFORE guard covers direct PostgREST INSERT/UPDATE, not only UI.
-- Keep AFTER realtime/audit triggers unchanged; rejected writes never reach them.
CREATE FUNCTION private.enforce_active_operational_record_quota()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog
AS $$
DECLARE
  v_resource text;
BEGIN
  IF TG_TABLE_SCHEMA IS DISTINCT FROM 'public' THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_invalid_resource_table';
  END IF;

  v_resource := CASE TG_TABLE_NAME
    WHEN 'customers' THEN 'customers'
    WHEN 'drivers' THEN 'drivers'
    WHEN 'routes' THEN 'routes'
    ELSE NULL
  END;
  IF v_resource IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P2862',
      MESSAGE='quota_invalid_resource_table';
  END IF;

  -- Check actor authorization BEFORE inspecting tenant-specific occupancy.
  -- Internal trusted maintenance jobs use the same capacity lock/check.
  IF (auth.uid() IS NOT NULL OR
      pg_catalog.current_setting('request.jwt.claim.role', true)='authenticated'
     ) AND NOT private.has_company_role(
    NEW.company_id,
    ARRAY[
      'owner'::public.company_role,
      'admin'::public.company_role,
      'operations'::public.company_role
    ]
  ) THEN
    RAISE EXCEPTION USING ERRCODE='42501',
      MESSAGE='operational_resource_permission_denied';
  END IF;

  IF TG_OP='UPDATE' THEN
    IF NEW.company_id IS DISTINCT FROM OLD.company_id THEN
      RAISE EXCEPTION USING ERRCODE='P2864',
        MESSAGE='operational_resource_company_reassignment_denied';
    END IF;
    IF NOT OLD.is_active AND NEW.is_active THEN
      PERFORM private.assert_company_quota_capacity(
        NEW.company_id,v_resource,1
      );
    END IF;
  ELSIF TG_OP='INSERT' AND NEW.is_active THEN
    PERFORM private.assert_company_quota_capacity(
      NEW.company_id,v_resource,1
    );
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.enforce_active_operational_record_quota()
  FROM PUBLIC, anon, authenticated;

CREATE TRIGGER customers_enforce_active_quota
  BEFORE INSERT OR UPDATE OF is_active,company_id ON public.customers
  FOR EACH ROW EXECUTE FUNCTION private.enforce_active_operational_record_quota();

CREATE TRIGGER drivers_enforce_active_quota
  BEFORE INSERT OR UPDATE OF is_active,company_id ON public.drivers
  FOR EACH ROW EXECUTE FUNCTION private.enforce_active_operational_record_quota();

CREATE TRIGGER routes_enforce_active_quota
  BEFORE INSERT OR UPDATE OF is_active,company_id ON public.routes
  FOR EACH ROW EXECUTE FUNCTION private.enforce_active_operational_record_quota();

CREATE INDEX IF NOT EXISTS customers_active_quota_idx
  ON public.customers(company_id) WHERE is_active=true;
CREATE INDEX IF NOT EXISTS drivers_active_quota_idx
  ON public.drivers(company_id) WHERE is_active=true;
CREATE INDEX IF NOT EXISTS routes_active_quota_idx
  ON public.routes(company_id) WHERE is_active=true;
