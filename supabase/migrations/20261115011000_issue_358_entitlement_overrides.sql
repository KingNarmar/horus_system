-- Issue #358. Operator-only, versioned, scoped entitlements and creation
-- capacity. SOURCE ONLY. No hosted project has been changed by this commit.
BEGIN;

CREATE TABLE private.platform_entitlement_overrides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  scope_kind text NOT NULL CHECK (scope_kind IN ('resource','feature')),
  scope_key text NOT NULL,
  override_value jsonb NOT NULL,
  effective_at timestamptz NOT NULL,
  expires_at timestamptz,
  granted_by uuid NOT NULL,
  granted_reason text NOT NULL CHECK(length(btrim(granted_reason)) BETWEEN 8 AND 500),
  granted_at timestamptz NOT NULL DEFAULT now(),
  created_revision integer NOT NULL CHECK (created_revision>0),
  revoked_at timestamptz,
  revoked_by uuid,
  revoke_reason text,
  revoked_revision integer,
  CONSTRAINT platform_override_dates CHECK(
    expires_at IS NULL OR expires_at>effective_at
  ),
  CONSTRAINT platform_override_revocation_pair CHECK(
    (revoked_at IS NULL AND revoked_by IS NULL AND revoke_reason IS NULL AND revoked_revision IS NULL)
    OR (revoked_at IS NOT NULL AND revoked_by IS NOT NULL
        AND revoke_reason IS NOT NULL
        AND length(btrim(revoke_reason)) BETWEEN 8 AND 500
        AND revoked_revision IS NOT NULL)
  ),
  CONSTRAINT platform_override_known_scope CHECK (
    (
      scope_kind='resource'
      AND scope_key IN (
        'company_users','combined_vehicles','customers','drivers','routes',
        'lifetime_trips','lifetime_invoices','business_documents'
      )
      AND (
        (jsonb_typeof(override_value)='number'
          AND override_value::text ~ '^(0|[1-9][0-9]*)$')
        OR override_value='"unlimited"'::jsonb
      )
    ) OR (
      scope_kind='feature'
      AND scope_key IN (
        'driver_app','advanced_reports','maintenance',
        'whatsapp_notifications'
      )
      AND override_value='true'::jsonb
    )
  )
);
CREATE INDEX platform_overrides_company_scope_idx
  ON private.platform_entitlement_overrides
  (company_id,scope_kind,scope_key,effective_at,expires_at)
  WHERE revoked_at IS NULL;
CREATE INDEX platform_overrides_timeline_idx
  ON private.platform_entitlement_overrides
  (company_id,granted_at DESC,id DESC);
ALTER TABLE private.platform_entitlement_overrides ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.platform_entitlement_overrides
  FROM PUBLIC,anon,authenticated;

-- No direct DML/SELECT on these tables is granted to a distributed client.
-- All writes go through independently authenticated, scoped RPCs.

CREATE OR REPLACE FUNCTION private.resolve_company_effective_entitlement(p_company_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_company public.companies%ROWTYPE;
  v_grant public.company_subscriptions%ROWTYPE;
  v_plan public.subscription_plans%ROWTYPE;
  v_policy private.entitlement_policy_versions%ROWTYPE;
  v_status text;
  v_result jsonb;
  v_override private.platform_entitlement_overrides%ROWTYPE;
  v_next_change timestamptz;
BEGIN
  SELECT * INTO v_company
    FROM public.companies WHERE id = p_company_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2851',
      MESSAGE = 'entitlement_unavailable';
  END IF;

  SELECT * INTO v_grant
    FROM public.company_subscriptions WHERE company_id = p_company_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2851',
      MESSAGE = 'entitlement_unavailable';
  END IF;

  SELECT * INTO v_plan
    FROM public.subscription_plans WHERE id = v_grant.plan_id;
  SELECT * INTO v_policy
    FROM private.entitlement_policy_versions
    WHERE plan_id = v_grant.plan_id
      AND version = v_grant.policy_version;

  IF v_plan.id IS NULL OR v_policy.id IS NULL
     OR v_grant.effective_at IS NULL
     OR v_grant.policy_version IS NULL
     OR v_grant.revision <= 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P2852',
      MESSAGE = 'entitlement_integrity_error';
  END IF;

  IF v_grant.grant_source IN ('free_starter', 'legacy_backfill')
     AND (
       v_plan.code <> 'free_starter' OR v_plan.monthly_price <> 0
       OR v_grant.external_provider IS NOT NULL
       OR v_grant.external_subscription_id IS NOT NULL
       OR v_grant.trial_ends_at IS NOT NULL
     ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P2852',
      MESSAGE = 'entitlement_integrity_error';
  END IF;

  v_status := CASE
    WHEN NOT v_company.is_active THEN 'suspended'
    WHEN v_grant.effective_at > pg_catalog.now() THEN 'suspended'
    WHEN v_grant.status = 'suspended'::public.subscription_status THEN 'suspended'
    WHEN v_grant.status = 'expired'::public.subscription_status THEN 'expired'
    WHEN v_grant.status = 'cancelled'::public.subscription_status THEN 'revoked'
    WHEN v_grant.expires_at IS NOT NULL
     AND v_grant.expires_at <= now() THEN 'expired'
    WHEN v_grant.status = 'active'::public.subscription_status THEN 'active'
    ELSE 'revoked'
  END;

  v_result := pg_catalog.jsonb_build_object(
    'company_id', v_company.id,
    'plan_code', v_plan.code,
    'policy_version', v_policy.version,
    'revision', v_grant.revision,
    'effective_at', v_grant.effective_at,
    'expires_at', v_grant.expires_at,
    'status', v_status,
    'limits', v_policy.limits,
    'enabled_features', v_policy.enabled_features
  );
  -- All quota writers already consume this canonical resolver. No counter
  -- or plan-policy copy is introduced by the operator subsystem.
  FOR v_override IN
    SELECT * FROM private.platform_entitlement_overrides o
    WHERE o.company_id=p_company_id
      AND o.revoked_at IS NULL
      AND o.effective_at<=pg_catalog.now()
      AND (o.expires_at IS NULL OR o.expires_at>pg_catalog.now())
    ORDER BY o.scope_kind,o.scope_key,o.effective_at,o.id
  LOOP
    IF v_override.scope_kind='resource' THEN
      v_result := pg_catalog.jsonb_set(v_result,
        ARRAY['limits',v_override.scope_key],v_override.override_value,true);
    ELSIF NOT (
      (v_result->'enabled_features')
      @> pg_catalog.jsonb_build_array(v_override.scope_key)
    ) THEN
      v_result := pg_catalog.jsonb_set(v_result,'{enabled_features}',
        (v_result->'enabled_features')
          || pg_catalog.jsonb_build_array(v_override.scope_key),true);
    END IF;
  END LOOP;

  SELECT min(t.boundary) INTO v_next_change
  FROM (
    SELECT o.effective_at AS boundary
    FROM private.platform_entitlement_overrides o
    WHERE o.company_id=p_company_id AND o.revoked_at IS NULL
      AND o.effective_at>pg_catalog.now()
    UNION ALL
    SELECT o.expires_at
    FROM private.platform_entitlement_overrides o
    WHERE o.company_id=p_company_id AND o.revoked_at IS NULL
      AND o.expires_at>pg_catalog.now()
  ) t;
  RETURN v_result || pg_catalog.jsonb_build_object(
    'next_override_change_at',v_next_change
  );
END;
$function$;

REVOKE ALL ON FUNCTION private.resolve_company_effective_entitlement(uuid)
  FROM PUBLIC,anon,authenticated;

-- Grant one narrowly scoped override; a request-id is only reusable for
-- an IDENTICAL normalized payload. Every change and audit write is atomic.
CREATE FUNCTION public.platform_grant_entitlement_override(
  p_company_id uuid, p_scope_kind text, p_scope_key text, p_value jsonb,
  p_effective_at timestamptz, p_expires_at timestamptz,
  p_expected_revision integer, p_reason text, p_request_id uuid
)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path=pg_catalog
AS $$
DECLARE
  v_actor uuid;
  v_reason text := NULLIF(btrim(p_reason),'');
  v_effective timestamptz := COALESCE(p_effective_at,now());
  v_hash text;
  v_prior private.platform_operator_audit%ROWTYPE;
  v_subscription public.company_subscriptions%ROWTYPE;
  v_before jsonb;
  v_after jsonb;
  v_policy_limit text;
  v_revision integer;
  v_id uuid;
BEGIN
  v_actor:=private.require_platform_operator('override_write',true);
  IF p_company_id IS NULL OR p_scope_kind IS NULL OR p_scope_key IS NULL
    OR p_value IS NULL OR p_request_id IS NULL
    OR p_expected_revision IS NULL
    OR v_reason IS NULL OR length(v_reason) NOT BETWEEN 8 AND 500
    OR (p_expires_at IS NOT NULL AND p_expires_at<=v_effective)
  THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='platform_override_invalid';
  END IF;

  v_hash:=encode(extensions.digest(convert_to(jsonb_build_object(
    'op','grant','company',p_company_id,'kind',p_scope_kind,
    'key',p_scope_key,'value',p_value,'starts',p_effective_at,
    'ends',p_expires_at,'revision',p_expected_revision,
    'reason',v_reason
  )::text,'UTF8'),'sha256'),'hex');

  PERFORM 1 FROM public.companies c WHERE c.id=p_company_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P3581',MESSAGE='platform_company_not_found';
  END IF;
  IF EXISTS (SELECT 1 FROM public.company_users m
    WHERE m.company_id=p_company_id AND m.user_id=v_actor AND m.is_active)
  THEN
    RAISE EXCEPTION USING ERRCODE='42501',
      MESSAGE='platform_operator_self_grant_forbidden';
  END IF;

  SELECT * INTO v_prior FROM private.platform_operator_audit a
  WHERE a.actor_user_id=v_actor AND a.request_id=p_request_id;
  IF FOUND THEN
    IF v_prior.request_fingerprint IS DISTINCT FROM v_hash
      OR v_prior.action IS DISTINCT FROM 'entitlement_override_granted' THEN
      RAISE EXCEPTION USING ERRCODE='P3582',
        MESSAGE='platform_request_id_conflict';
    END IF;
    RETURN v_prior.new_values;
  END IF;

  SELECT * INTO v_subscription FROM public.company_subscriptions s
  WHERE s.company_id=p_company_id FOR UPDATE;
  IF NOT FOUND OR v_subscription.revision IS DISTINCT FROM p_expected_revision
  THEN
    RAISE EXCEPTION USING ERRCODE='P3583',
      MESSAGE='platform_revision_conflict';
  END IF;
  v_before:=private.resolve_company_effective_entitlement(p_company_id);
  IF v_before->>'plan_code' IS DISTINCT FROM 'free_starter'
    OR v_before->>'status' IS DISTINCT FROM 'active'
  THEN
    RAISE EXCEPTION USING ERRCODE='P3584',
      MESSAGE='platform_override_plan_unavailable';
  END IF;

  IF p_scope_kind='resource' THEN
    IF p_scope_key NOT IN (
      'company_users','combined_vehicles','customers','drivers','routes',
      'lifetime_trips','lifetime_invoices','business_documents'
    ) THEN
      RAISE EXCEPTION USING ERRCODE='22023',
        MESSAGE='platform_override_unknown_resource';
    END IF;
    SELECT ep.limits->>p_scope_key INTO v_policy_limit
    FROM private.entitlement_policy_versions ep
    WHERE ep.plan_id=v_subscription.plan_id
      AND ep.version=v_subscription.policy_version;
    IF v_policy_limit IS NULL OR v_policy_limit !~ '^[0-9]+$'
       OR NOT (
         p_value='"unlimited"'::jsonb
         OR (jsonb_typeof(p_value)='number'
           AND p_value::text ~ '^(0|[1-9][0-9]*)$'
           AND (p_value::text)::numeric >= v_policy_limit::numeric
           AND (p_value::text)::numeric <= 9223372036854775807)
       )
    THEN
      RAISE EXCEPTION USING ERRCODE='22023',
        MESSAGE='platform_override_invalid_resource_value';
    END IF;
  ELSIF p_scope_kind='feature' THEN
    IF p_scope_key NOT IN (
      'driver_app','advanced_reports','maintenance','whatsapp_notifications'
    ) OR p_value IS DISTINCT FROM 'true'::jsonb THEN
      RAISE EXCEPTION USING ERRCODE='22023',
        MESSAGE='platform_override_invalid_feature';
    END IF;
  ELSE
    RAISE EXCEPTION USING ERRCODE='22023',
      MESSAGE='platform_override_unknown_kind';
  END IF;

  -- Company lock also serializes all existing atomic quota gates.
  -- Schedules for one resource/feature may never overlap.
  IF EXISTS (
    SELECT 1 FROM private.platform_entitlement_overrides e
    WHERE e.company_id=p_company_id AND e.scope_kind=p_scope_kind
      AND e.scope_key=p_scope_key AND e.revoked_at IS NULL
      AND tstzrange(e.effective_at,COALESCE(e.expires_at,'infinity'::timestamptz),'[)')
      && tstzrange(v_effective,COALESCE(p_expires_at,'infinity'::timestamptz),'[)')
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P3585',
      MESSAGE='platform_override_schedule_conflict';
  END IF;

  INSERT INTO private.platform_entitlement_overrides(
    company_id,scope_kind,scope_key,override_value,effective_at,
    expires_at,granted_by,granted_reason,created_revision
  ) VALUES (
    p_company_id,p_scope_kind,p_scope_key,p_value,v_effective,
    p_expires_at,v_actor,v_reason,v_subscription.revision+1
  ) RETURNING id INTO v_id;

  UPDATE public.company_subscriptions
  SET revision=revision+1,updated_by=v_actor,updated_at=now()
  WHERE company_id=p_company_id
  RETURNING revision INTO v_revision;
  v_after:=private.resolve_company_effective_entitlement(p_company_id);

  INSERT INTO private.platform_operator_audit(
    company_id,actor_user_id,actor_session_id,action,reason,
    request_id,request_fingerprint,old_values,new_values
  ) VALUES (
    p_company_id,v_actor,(auth.jwt()->>'session_id')::uuid,
    'entitlement_override_granted',v_reason,p_request_id,v_hash,
    jsonb_build_object('entitlement',v_before),
    jsonb_build_object('override_id',v_id,'revision',v_revision,
      'entitlement',v_after,'scope_kind',p_scope_kind,
      'scope_key',p_scope_key,'value',p_value,'effective_at',v_effective,
      'expires_at',p_expires_at)
  );
  RETURN jsonb_build_object('override_id',v_id,'revision',v_revision,
    'entitlement',v_after,'scope_kind',p_scope_kind,'scope_key',p_scope_key,
    'value',p_value,'effective_at',v_effective,'expires_at',p_expires_at);
END;
$$;
REVOKE ALL ON FUNCTION public.platform_grant_entitlement_override(
  uuid,text,text,jsonb,timestamptz,timestamptz,integer,text,uuid
) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.platform_grant_entitlement_override(
  uuid,text,text,jsonb,timestamptz,timestamptz,integer,text,uuid
) TO authenticated;

CREATE FUNCTION public.platform_revoke_entitlement_override(
  p_company_id uuid, p_override_id uuid, p_expected_revision integer,
  p_reason text, p_request_id uuid
)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=pg_catalog
AS $$
DECLARE
  v_actor uuid;
  v_reason text := NULLIF(btrim(p_reason),'');
  v_hash text;
  v_prior private.platform_operator_audit%ROWTYPE;
  v_grant private.platform_entitlement_overrides%ROWTYPE;
  v_subscription public.company_subscriptions%ROWTYPE;
  v_before jsonb;
  v_after jsonb;
  v_revision integer;
  v_response jsonb;
BEGIN
  v_actor:=private.require_platform_operator('override_write',true);
  IF p_company_id IS NULL OR p_override_id IS NULL
    OR p_expected_revision IS NULL OR p_request_id IS NULL
    OR v_reason IS NULL OR length(v_reason) NOT BETWEEN 8 AND 500
  THEN
    RAISE EXCEPTION USING ERRCODE='22023',MESSAGE='platform_revoke_invalid';
  END IF;
  v_hash:=encode(extensions.digest(convert_to(jsonb_build_object(
    'op','revoke','company',p_company_id,'override',p_override_id,
    'revision',p_expected_revision,'reason',v_reason
  )::text,'UTF8'),'sha256'),'hex');
  PERFORM 1 FROM public.companies c WHERE c.id=p_company_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P3581',MESSAGE='platform_company_not_found';
  END IF;
  IF EXISTS (SELECT 1 FROM public.company_users m
    WHERE m.company_id=p_company_id AND m.user_id=v_actor AND m.is_active)
  THEN
    RAISE EXCEPTION USING ERRCODE='42501',
      MESSAGE='platform_operator_self_grant_forbidden';
  END IF;

  SELECT * INTO v_prior FROM private.platform_operator_audit a
  WHERE a.actor_user_id=v_actor AND a.request_id=p_request_id;
  IF FOUND THEN
    IF v_prior.request_fingerprint IS DISTINCT FROM v_hash
       OR v_prior.action IS DISTINCT FROM 'entitlement_override_revoked' THEN
      RAISE EXCEPTION USING ERRCODE='P3582',MESSAGE='platform_request_id_conflict';
    END IF;
    RETURN v_prior.new_values;
  END IF;

  SELECT * INTO v_subscription FROM public.company_subscriptions s
  WHERE s.company_id=p_company_id FOR UPDATE;
  IF NOT FOUND OR v_subscription.revision IS DISTINCT FROM p_expected_revision
  THEN
    RAISE EXCEPTION USING ERRCODE='P3583',MESSAGE='platform_revision_conflict';
  END IF;
  SELECT * INTO v_grant FROM private.platform_entitlement_overrides g
  WHERE g.id=p_override_id AND g.company_id=p_company_id FOR UPDATE;
  IF NOT FOUND OR v_grant.revoked_at IS NOT NULL THEN
    RAISE EXCEPTION USING ERRCODE='P3586',
      MESSAGE='platform_override_not_active';
  END IF;
  v_before:=private.resolve_company_effective_entitlement(p_company_id);
  UPDATE private.platform_entitlement_overrides
  SET revoked_at=now(),revoked_by=v_actor,revoke_reason=v_reason,
      revoked_revision=v_subscription.revision+1
  WHERE id=p_override_id AND company_id=p_company_id;
  UPDATE public.company_subscriptions
  SET revision=revision+1,updated_by=v_actor,updated_at=now()
  WHERE company_id=p_company_id RETURNING revision INTO v_revision;
  v_after:=private.resolve_company_effective_entitlement(p_company_id);
  v_response:=jsonb_build_object('override_id',p_override_id,
    'revision',v_revision,'entitlement',v_after,'revoked',true);
  INSERT INTO private.platform_operator_audit(
    company_id,actor_user_id,actor_session_id,action,reason,
    request_id,request_fingerprint,old_values,new_values
  ) VALUES (
    p_company_id,v_actor,(auth.jwt()->>'session_id')::uuid,
    'entitlement_override_revoked',v_reason,p_request_id,v_hash,
    jsonb_build_object('entitlement',v_before,'override_id',p_override_id,
      'scope_kind',v_grant.scope_kind,'scope_key',v_grant.scope_key,
      'value',v_grant.override_value,'effective_at',v_grant.effective_at,
      'expires_at',v_grant.expires_at),v_response
  );
  RETURN v_response;
END;
$$;
REVOKE ALL ON FUNCTION public.platform_revoke_entitlement_override(
  uuid,uuid,integer,text,uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.platform_revoke_entitlement_override(
  uuid,uuid,integer,text,uuid) TO authenticated;

COMMIT;
