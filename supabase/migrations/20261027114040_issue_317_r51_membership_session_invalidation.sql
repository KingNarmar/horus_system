-- Issue #317 R5.1: personal, minimal membership invalidation hints.
-- This migration is staged for Development verification; Production is untouched.
-- Realtime authorization is bound to auth.uid(), NOT membership (which can
-- be revoked/reinstated). No role, company data, or audit snapshots are sent.
BEGIN;

CREATE POLICY horus_user_membership_realtime_receive
ON realtime.messages
FOR SELECT TO authenticated
USING (
  extension = 'broadcast'
  AND realtime.topic() = (
    'horus:user:' || (SELECT auth.uid())::text || ':membership'
  )
);

-- Authenticated clients receive only their own hints; they cannot send them.
-- The trigger is server-owned and its private function is non-executable
-- directly by anonymous or authenticated API clients.
CREATE FUNCTION private.broadcast_company_membership_invalidation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_user_id uuid;
BEGIN
  IF TG_OP = 'UPDATE'
    AND NEW.role IS NOT DISTINCT FROM OLD.role
    AND NEW.is_active IS NOT DISTINCT FROM OLD.is_active
    AND NEW.user_id IS NOT DISTINCT FROM OLD.user_id
    AND NEW.company_id IS NOT DISTINCT FROM OLD.company_id THEN
    RETURN NULL;
  END IF;

  v_user_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.user_id ELSE NEW.user_id END;

  PERFORM realtime.send(
    pg_catalog.jsonb_build_object(
      'user_id', v_user_id,
      'resource', 'membership'
    ),
    'changed',
    'horus:user:' || v_user_id::text || ':membership',
    true
  );

  -- If a Platform Admin moves an identity to another user, invalidate both.
  IF TG_OP = 'UPDATE' AND OLD.user_id IS DISTINCT FROM NEW.user_id THEN
    PERFORM realtime.send(
      pg_catalog.jsonb_build_object(
        'user_id', OLD.user_id,
        'resource', 'membership'
      ),
      'changed',
      'horus:user:' || OLD.user_id::text || ':membership',
      true
    );
  END IF;

  RETURN NULL; -- AFTER trigger; does not change the business record.
END;
$function$;

REVOKE ALL ON FUNCTION private.broadcast_company_membership_invalidation()
FROM PUBLIC, anon, authenticated;

CREATE TRIGGER company_users_membership_session_invalidation
AFTER INSERT OR DELETE OR UPDATE OF role, is_active, user_id, company_id
ON public.company_users
FOR EACH ROW
EXECUTE FUNCTION private.broadcast_company_membership_invalidation();

COMMIT;
