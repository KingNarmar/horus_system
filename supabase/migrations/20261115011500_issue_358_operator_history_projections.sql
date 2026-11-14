-- Issue #358: read-only history projections, separated from mutation API.
-- All access is guarded by the private, current-session operator permission gate.
BEGIN;

CREATE FUNCTION public.platform_list_entitlement_overrides(
  p_company_id uuid, p_after_id uuid DEFAULT NULL, p_page_size integer DEFAULT 25
)
RETURNS TABLE(
  override_id uuid, scope_kind text, scope_key text, override_value jsonb,
  effective_at timestamptz, expires_at timestamptz,
  granted_at timestamptz, revoked_at timestamptz, created_revision integer
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE
  v_cursor_at timestamptz;
BEGIN
  PERFORM private.require_platform_operator('override_read',false);
  IF p_company_id IS NULL OR p_page_size IS NULL
     OR p_page_size NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='platform_invalid_history_page';
  END IF;
  IF p_after_id IS NOT NULL THEN
    SELECT o.granted_at INTO v_cursor_at
    FROM private.platform_entitlement_overrides o
    WHERE o.id=p_after_id AND o.company_id=p_company_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE='22023',
        MESSAGE='platform_invalid_override_cursor';
    END IF;
  END IF;
  RETURN QUERY
    SELECT o.id,o.scope_kind,o.scope_key,o.override_value,
      o.effective_at,o.expires_at,o.granted_at,o.revoked_at,o.created_revision
    FROM private.platform_entitlement_overrides o
    WHERE o.company_id=p_company_id
      AND (p_after_id IS NULL
           OR (o.granted_at,o.id)<(v_cursor_at,p_after_id))
    ORDER BY o.granted_at DESC,o.id DESC LIMIT p_page_size;
END;
$$;
REVOKE ALL ON FUNCTION public.platform_list_entitlement_overrides(
  uuid,uuid,integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.platform_list_entitlement_overrides(
  uuid,uuid,integer) TO authenticated;

CREATE FUNCTION public.platform_list_operator_audit(
  p_company_id uuid DEFAULT NULL, p_after_id uuid DEFAULT NULL,
  p_page_size integer DEFAULT 25
)
RETURNS TABLE(
  audit_id uuid,company_id uuid,target_user_id uuid,action text,reason text,
  actor_user_id uuid,occurred_at timestamptz,old_values jsonb,new_values jsonb
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE
  v_cursor_at timestamptz;
BEGIN
  PERFORM private.require_platform_operator('audit_read',false);
  IF p_page_size IS NULL OR p_page_size NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='platform_invalid_audit_page';
  END IF;
  IF p_after_id IS NOT NULL THEN
    SELECT a.occurred_at INTO v_cursor_at
    FROM private.platform_operator_audit a
    WHERE a.id=p_after_id
      AND (p_company_id IS NULL OR a.company_id=p_company_id);
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE='22023',
        MESSAGE='platform_invalid_audit_cursor';
    END IF;
  END IF;
  RETURN QUERY
    SELECT a.id,a.company_id,a.target_user_id,a.action,a.reason,
      a.actor_user_id,a.occurred_at,a.old_values,a.new_values
    FROM private.platform_operator_audit a
    WHERE (p_company_id IS NULL OR a.company_id=p_company_id)
      AND (p_after_id IS NULL
           OR (a.occurred_at,a.id)<(v_cursor_at,p_after_id))
    ORDER BY a.occurred_at DESC,a.id DESC LIMIT p_page_size;
END;
$$;
REVOKE ALL ON FUNCTION public.platform_list_operator_audit(
  uuid,uuid,integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.platform_list_operator_audit(
  uuid,uuid,integer) TO authenticated;

COMMIT;
