-- H.O.R.U.S Issue #358 — DEVELOPMENT-ONLY privileged operator provisioning.
-- Versioned operational migration, deliberately OUTSIDE supabase/migrations/.
-- Authorized destination ONLY: Supabase project zwnfmszssxtfxkaofnhq (horus-system-dev).
-- NEVER run this file against Production or include it in shared db push/replay.
-- Execute via a controlled, authenticated DB-owner migration action explicitly
-- targeted at the Development project. The project ID is verified by the caller,
-- not inferred from PostgreSQL: Supabase PG does not expose a reliable project ref.
--
-- Identity selector is the MD5 of "<auth_user_uuid>:<lowercase_email>" as read
-- from Development's auth.users. This guards against provisioning the wrong
-- identity without publishing an email or auth-user UUID in repository source.
-- It is an identity MATCH guard, not a password, authenticator or access token.
-- Full trusted SQL audit comes from the existing access registry trigger.
--
-- Approval: explicitly authorized by the platform owner on 2026-11-15 for
-- adlymina99@gmail.com, DEVELOPMENT ONLY, retaining all tenant memberships.
-- Scope: tenant_read, usage_read, override_read, override_write,
-- creation_grant_write, audit_read and membership_recovery.
-- Deliberately EXCLUDES operator_manage.
-- Operator RPCs still require verified real GoTrue MFA AAL2; merely
-- provisioned access must NOT bypass MFA or grant tenant-table reads.
--
-- Rollback of this granted privilege: separately approved, audited
-- versioned revocation migration (set revoked_at; disable protected profile
-- flag). Never delete the immutable audit history or manually alter RLS.

DO $issue_358_dev_operator_bootstrap$
DECLARE
  v_user_id uuid;
  v_permissions text[] := ARRAY[
    'tenant_read',
    'usage_read',
    'override_read',
    'override_write',
    'creation_grant_write',
    'audit_read',
    'membership_recovery'
  ]::text[];
  v_reason text := 'Development-only operator bootstrap approved by platform owner for Issue #358 on 2026-11-15; database-owner migration, not Production';
  v_changed integer;
BEGIN
  IF current_user <> 'postgres' THEN
    RAISE EXCEPTION USING ERRCODE = 'P3581',
      MESSAGE = 'operator_bootstrap_requires_trusted_db_owner';
  END IF;

  -- Fail closed if the reviewed Development identity, its protected flag,
  -- account health, or current membership profile no longer match.
  SELECT u.id INTO STRICT v_user_id
  FROM auth.users u
  JOIN public.user_profiles p ON p.id = u.id
  WHERE md5(u.id::text || ':' || lower(u.email)) =
          'c03ef3afe8cc3462d574379194e2b49a'
    AND u.email_confirmed_at IS NOT NULL
    AND u.deleted_at IS NULL
    AND (u.banned_until IS NULL OR u.banned_until <= now())
    AND COALESCE(u.is_anonymous, false) IS FALSE
    AND p.is_platform_admin IS FALSE
    AND (SELECT count(*) FROM public.company_users cu
         WHERE cu.user_id = u.id) = 2
    AND (SELECT count(*) FROM public.company_users cu
         WHERE cu.user_id = u.id AND cu.is_active) = 1
  FOR UPDATE OF u, p;

  IF EXISTS (
    SELECT 1 FROM private.platform_operator_access
    WHERE user_id = v_user_id
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3581',
      MESSAGE = 'operator_bootstrap_existing_registry_requires_review';
  END IF;

  UPDATE public.user_profiles
  SET is_platform_admin = TRUE
  WHERE id = v_user_id AND is_platform_admin IS FALSE;

  GET DIAGNOSTICS v_changed = ROW_COUNT;
  IF v_changed <> 1 THEN
    RAISE EXCEPTION USING ERRCODE = 'P3581',
      MESSAGE = 'operator_bootstrap_profile_update_failed';
  END IF;

  INSERT INTO private.platform_operator_access (
    user_id, permissions, approved_reason, approved_by
  ) VALUES (v_user_id, v_permissions, v_reason, NULL);

  -- INSERT trigger provides immutable operator_access_created audit.
  -- DB-owner execution has no signed user JWT, so actor_user_id remains
  -- NULL intentionally; NEVER impersonate an actor via forged JWT claims.
  IF NOT EXISTS (
    SELECT 1 FROM private.platform_operator_audit a
    WHERE a.target_user_id = v_user_id
      AND a.action = 'operator_access_created'
      AND a.reason = v_reason
      AND a.new_values->'permissions' = to_jsonb(v_permissions)
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3581',
      MESSAGE = 'operator_bootstrap_missing_immutable_audit';
  END IF;
END;
$issue_358_dev_operator_bootstrap$;
