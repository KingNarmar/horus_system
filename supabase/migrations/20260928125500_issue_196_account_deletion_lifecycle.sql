-- H.O.R.U.S System — Issue #196 account deletion lifecycle
-- Account identity deletion is independent from company-owned business history.
-- Requests are self-service, server-authoritative, cancellable during a 7-day
-- cooling-off period, and finalized only by a privileged server worker.

BEGIN;

CREATE TYPE public.account_deletion_status AS ENUM (
  'pending',
  'cancelled',
  'finalized'
);

CREATE TABLE public.account_deletion_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status public.account_deletion_status NOT NULL DEFAULT 'pending',
  requested_at timestamptz NOT NULL DEFAULT now(),
  eligible_after timestamptz NOT NULL,
  cancelled_at timestamptz,
  finalized_at timestamptz,
  CONSTRAINT account_deletion_request_timestamps_valid CHECK (
    (status = 'pending' AND cancelled_at IS NULL AND finalized_at IS NULL)
    OR (status = 'cancelled' AND cancelled_at IS NOT NULL AND finalized_at IS NULL)
    OR (status = 'finalized' AND finalized_at IS NOT NULL)
  )
);

CREATE UNIQUE INDEX account_deletion_requests_one_pending_per_user
ON public.account_deletion_requests(user_id)
WHERE status = 'pending';

CREATE INDEX account_deletion_requests_due_idx
ON public.account_deletion_requests(eligible_after)
WHERE status = 'pending';

ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY account_deletion_requests_select_self
ON public.account_deletion_requests
FOR SELECT TO authenticated
USING (user_id = auth.uid());

REVOKE ALL ON TABLE public.account_deletion_requests FROM PUBLIC, anon;
GRANT SELECT ON TABLE public.account_deletion_requests TO authenticated;

-- Invitation history must not prevent Auth deletion. Historical accountability
-- is carried by immutable audit actor snapshots, not a live Auth FK.
ALTER TABLE public.company_invitations
  ALTER COLUMN invited_by_user_id DROP NOT NULL;

ALTER TABLE public.company_invitations
  DROP CONSTRAINT company_invitations_invited_by_user_id_fkey;

ALTER TABLE public.company_invitations
  ADD CONSTRAINT company_invitations_invited_by_user_id_fkey
  FOREIGN KEY (invited_by_user_id)
  REFERENCES auth.users(id)
  ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION private.assert_account_deletion_ownership_continuity(
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM public.company_users mine
    WHERE mine.user_id = p_user_id
      AND mine.is_active = true
      AND mine.role = 'owner'::public.company_role
      AND NOT EXISTS (
        SELECT 1
        FROM public.company_users other_owner
        WHERE other_owner.company_id = mine.company_id
          AND other_owner.user_id <> p_user_id
          AND other_owner.is_active = true
          AND other_owner.role = 'owner'::public.company_role
      )
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2961',
      MESSAGE = 'account_deletion_ownership_transfer_required';
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION private.assert_account_deletion_ownership_continuity(uuid)
FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_my_account_deletion_status()
RETURNS TABLE (
  request_id uuid,
  request_status public.account_deletion_status,
  requested_at timestamptz,
  eligible_after timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
  SELECT request_row.id, request_row.status, request_row.requested_at,
         request_row.eligible_after
  FROM public.account_deletion_requests request_row
  WHERE request_row.user_id = auth.uid()
    AND request_row.status = 'pending'
  ORDER BY request_row.requested_at DESC
  LIMIT 1;
$function$;

REVOKE ALL ON FUNCTION public.get_my_account_deletion_status()
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_account_deletion_status()
TO authenticated;

CREATE OR REPLACE FUNCTION public.request_my_account_deletion()
RETURNS TABLE (
  request_id uuid,
  request_status public.account_deletion_status,
  requested_at timestamptz,
  eligible_after timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_request public.account_deletion_requests%ROWTYPE;
  v_company record;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2960',
      MESSAGE = 'account_deletion_auth_required';
  END IF;

  PERFORM private.assert_account_deletion_ownership_continuity(v_user_id);

  SELECT *
  INTO v_request
  FROM public.account_deletion_requests r
  WHERE r.user_id = v_user_id AND r.status = 'pending'
  ORDER BY r.requested_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    INSERT INTO public.account_deletion_requests(
      user_id, status, requested_at, eligible_after
    )
    VALUES (v_user_id, 'pending', now(), now() + interval '7 days')
    RETURNING * INTO v_request;

    FOR v_company IN
      SELECT cu.company_id, cu.role
      FROM public.company_users cu
      WHERE cu.user_id = v_user_id AND cu.is_active = true
    LOOP
      PERFORM private.write_audit_event(
        v_company.company_id,
        'account',
        'user_account',
        v_user_id::text,
        NULL,
        'deletion_requested',
        'account_deletion_requested',
        NULL,
        jsonb_build_object('status', 'pending'),
        jsonb_build_object('eligible_after', v_request.eligible_after)
      );
    END LOOP;
  END IF;

  RETURN QUERY SELECT v_request.id, v_request.status,
    v_request.requested_at, v_request.eligible_after;
END;
$function$;

REVOKE ALL ON FUNCTION public.request_my_account_deletion()
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_my_account_deletion()
TO authenticated;

CREATE OR REPLACE FUNCTION public.cancel_my_account_deletion()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_request public.account_deletion_requests%ROWTYPE;
  v_company record;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2960',
      MESSAGE = 'account_deletion_auth_required';
  END IF;

  SELECT *
  INTO v_request
  FROM public.account_deletion_requests r
  WHERE r.user_id = v_user_id AND r.status = 'pending'
  ORDER BY r.requested_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  UPDATE public.account_deletion_requests
  SET status = 'cancelled', cancelled_at = now()
  WHERE id = v_request.id;

  FOR v_company IN
    SELECT cu.company_id
    FROM public.company_users cu
    WHERE cu.user_id = v_user_id AND cu.is_active = true
  LOOP
    PERFORM private.write_audit_event(
      v_company.company_id,
      'account',
      'user_account',
      v_user_id::text,
      NULL,
      'deletion_cancelled',
      'account_deletion_cancelled',
      jsonb_build_object('status', 'pending'),
      jsonb_build_object('status', 'cancelled'),
      '{}'::jsonb
    );
  END LOOP;
END;
$function$;

REVOKE ALL ON FUNCTION public.cancel_my_account_deletion()
FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cancel_my_account_deletion()
TO authenticated;

-- Called only by service_role immediately before Auth Admin deleteUser().
-- It re-checks ownership continuity to prevent a race after request creation,
-- preserves audit display-name/role snapshots, removes unnecessary email PII,
-- and returns the due user id to the privileged finalizer.
CREATE OR REPLACE FUNCTION public.prepare_due_account_deletion(
  p_request_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
DECLARE
  v_request public.account_deletion_requests%ROWTYPE;
  v_display_name text;
BEGIN
  IF auth.role() <> 'service_role' THEN
    RAISE EXCEPTION USING ERRCODE = 'P2962',
      MESSAGE = 'account_deletion_finalizer_forbidden';
  END IF;

  SELECT * INTO v_request
  FROM public.account_deletion_requests r
  WHERE r.id = p_request_id
    AND r.status = 'pending'
    AND r.eligible_after <= now()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P2963',
      MESSAGE = 'account_deletion_not_due';
  END IF;

  PERFORM private.assert_account_deletion_ownership_continuity(v_request.user_id);

  SELECT nullif(trim(up.full_name), '')
  INTO v_display_name
  FROM public.user_profiles up
  WHERE up.id = v_request.user_id;

  UPDATE public.audit_logs al
  SET actor_display_name = coalesce(
        nullif(trim(al.actor_display_name), ''),
        v_display_name,
        nullif(trim(al.actor_role), ''),
        'Deleted user'
      ),
      actor_email = NULL
  WHERE al.actor_user_id = v_request.user_id;

  RETURN v_request.user_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.prepare_due_account_deletion(uuid)
FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.prepare_due_account_deletion(uuid)
TO service_role;

-- Called by the privileged finalizer only after Auth Admin deleteUser succeeds.
CREATE OR REPLACE FUNCTION public.mark_account_deletion_finalized(
  p_request_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF auth.role() <> 'service_role' THEN
    RAISE EXCEPTION USING ERRCODE = 'P2962',
      MESSAGE = 'account_deletion_finalizer_forbidden';
  END IF;

  UPDATE public.account_deletion_requests
  SET status = 'finalized', finalized_at = now()
  WHERE id = p_request_id AND status = 'pending';
END;
$function$;

REVOKE ALL ON FUNCTION public.mark_account_deletion_finalized(uuid)
FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mark_account_deletion_finalized(uuid)
TO service_role;

COMMIT;
