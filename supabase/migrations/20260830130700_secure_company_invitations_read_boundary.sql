-- H.O.R.U.S System — Issue #203 Company invitations and membership lifecycle
-- Keep credential-derived token hashes server-side and expose a sanitized manager read RPC.

BEGIN;

REVOKE SELECT ON TABLE public.company_invitations FROM authenticated;

CREATE OR REPLACE FUNCTION public.list_company_invitations(
  p_company_id uuid
)
RETURNS TABLE (
  invitation_id uuid,
  company_id uuid,
  email_normalized text,
  invitation_role public.company_role,
  effective_status public.company_invitation_status,
  expires_at timestamptz,
  last_sent_at timestamptz,
  send_count integer,
  created_at timestamptz,
  accepted_at timestamptz,
  revoked_at timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_user_id uuid := auth.uid();
  v_actor_role public.company_role;
BEGIN
  IF v_actor_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P2800', MESSAGE = 'company_auth_required';
  END IF;

  SELECT company_user.role
  INTO v_actor_role
  FROM public.company_users company_user
  WHERE company_user.company_id = p_company_id
    AND company_user.user_id = v_actor_user_id
    AND company_user.is_active = true;

  IF NOT FOUND OR v_actor_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P2805',
      MESSAGE = 'company_invitation_permission_denied';
  END IF;

  RETURN QUERY
  SELECT
    invitation.id,
    invitation.company_id,
    invitation.email_normalized,
    invitation.role,
    CASE
      WHEN invitation.status = 'pending'::public.company_invitation_status
           AND invitation.expires_at <= pg_catalog.now()
        THEN 'expired'::public.company_invitation_status
      ELSE invitation.status
    END,
    invitation.expires_at,
    invitation.last_sent_at,
    invitation.send_count,
    invitation.created_at,
    invitation.accepted_at,
    invitation.revoked_at
  FROM public.company_invitations invitation
  WHERE invitation.company_id = p_company_id
  ORDER BY invitation.created_at DESC, invitation.id;
END;
$$;

REVOKE ALL ON FUNCTION public.list_company_invitations(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_company_invitations(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.list_company_invitations(uuid) TO authenticated;

COMMIT;
