-- H.O.R.U.S System — Issue #196 account deletion lifecycle
-- Account identity deletion is distinct from company membership and company data.
-- Requests are self-only and server-authoritative. Final Auth deletion is performed
-- by a privileged server finalizer after the cooling-off period.

BEGIN;

CREATE TYPE public.account_deletion_request_status AS ENUM ('pending', 'cancelled', 'finalized');

CREATE TABLE public.account_deletion_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status public.account_deletion_request_status NOT NULL DEFAULT 'pending',
  requested_at timestamptz NOT NULL DEFAULT now(),
  scheduled_for timestamptz NOT NULL,
  cancelled_at timestamptz,
  finalized_at timestamptz,
  CONSTRAINT account_deletion_schedule_valid CHECK (scheduled_for >= requested_at),
  CONSTRAINT account_deletion_terminal_state_valid CHECK (
    (status = 'pending' AND cancelled_at IS NULL AND finalized_at IS NULL)
    OR (status = 'cancelled' AND cancelled_at IS NOT NULL AND finalized_at IS NULL)
    OR (status = 'finalized' AND finalized_at IS NOT NULL)
  )
);

CREATE UNIQUE INDEX account_deletion_one_pending_per_user
ON public.account_deletion_requests(user_id)
WHERE status = 'pending';

ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY account_deletion_select_self
ON public.account_deletion_requests
FOR SELECT TO authenticated
USING (user_id = auth.uid());

REVOKE INSERT, UPDATE, DELETE ON public.account_deletion_requests FROM authenticated;
GRANT SELECT ON public.account_deletion_requests TO authenticated;

-- A deleted inviter must not block Auth deletion. The invitation remains a
-- company record; the actor's durable name is preserved separately.
ALTER TABLE public.company_invitations
  ADD COLUMN invited_by_display_name text;

UPDATE public.company_invitations invitation
SET invited_by_display_name = COALESCE(
  NULLIF(trim(profile.full_name), ''),
  NULLIF(trim(audit.actor_display_name), '')
)
FROM auth.users auth_user
LEFT JOIN public.user_profiles profile ON profile.id = auth_user.id
LEFT JOIN LATERAL (
  SELECT log.actor_display_name
  FROM public.audit_logs log
  WHERE log.actor_user_id = auth_user.id
    AND log.actor_display_name IS NOT NULL
  ORDER BY log.created_at DESC
  LIMIT 1
) audit ON true
WHERE invitation.invited_by_user_id = auth_user.id
  AND invitation.invited_by_display_name IS NULL;

ALTER TABLE public.company_invitations
  ALTER COLUMN invited_by_user_id DROP NOT NULL,
  DROP CONSTRAINT company_invitations_invited_by_user_id_fkey,
  ADD CONSTRAINT company_invitations_invited_by_user_id_fkey
    FOREIGN KEY (invited_by_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION private.account_deletion_assert_eligible(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.company_users membership
    WHERE membership.user_id = p_user_id
      AND membership.is_active = true
      AND membership.role = 'owner'::public.company_role
      AND NOT EXISTS (
        SELECT 1
        FROM public.company_users other_owner
        WHERE other_owner.company_id = membership.company_id
          AND other_owner.user_id <> p_user_id
          AND other_owner.is_active = true
          AND other_owner.role = 'owner'::public.company_role
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P1961',
      MESSAGE = 'account_deletion_sole_owner';
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION private.account_deletion_assert_eligible(uuid) FROM PUBLIC;

CREATE OR REPLACE FUNCTION public.get_my_account_deletion_status()
RETURNS TABLE(status text, requested_at timestamptz, scheduled_for timestamptz)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
  SELECT
    request.status::text,
    request.requested_at,
    request.scheduled_for
  FROM public.account_deletion_requests request
  WHERE request.user_id = auth.uid()
    AND request.status = 'pending'
  ORDER BY request.requested_at DESC
  LIMIT 1;
$function$;

CREATE OR REPLACE FUNCTION public.request_my_account_deletion()
RETURNS TABLE(status text, requested_at timestamptz, scheduled_for timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_request public.account_deletion_requests%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P1960', MESSAGE = 'account_deletion_auth_required';
  END IF;

  PERFORM private.account_deletion_assert_eligible(v_user_id);

  SELECT request.*
  INTO v_request
  FROM public.account_deletion_requests request
  WHERE request.user_id = v_user_id AND request.status = 'pending'
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.account_deletion_requests(user_id, scheduled_for)
    VALUES (v_user_id, pg_catalog.now() + interval '7 days')
    RETURNING * INTO v_request;
  END IF;

  RETURN QUERY SELECT v_request.status::text, v_request.requested_at, v_request.scheduled_for;
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_my_account_deletion()
RETURNS TABLE(status text, requested_at timestamptz, scheduled_for timestamptz)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_request public.account_deletion_requests%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P1960', MESSAGE = 'account_deletion_auth_required';
  END IF;

  SELECT request.*
  INTO v_request
  FROM public.account_deletion_requests request
  WHERE request.user_id = v_user_id AND request.status = 'pending'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  UPDATE public.account_deletion_requests request
  SET status = 'cancelled', cancelled_at = pg_catalog.now()
  WHERE request.id = v_request.id
  RETURNING * INTO v_request;

  RETURN QUERY SELECT v_request.status::text, v_request.requested_at, v_request.scheduled_for;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_my_account_deletion_status() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.request_my_account_deletion() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.cancel_my_account_deletion() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_account_deletion_status() TO authenticated;
GRANT EXECUTE ON FUNCTION public.request_my_account_deletion() TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_my_account_deletion() TO authenticated;

COMMIT;
