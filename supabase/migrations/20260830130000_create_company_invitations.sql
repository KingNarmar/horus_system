-- H.O.R.U.S System — Issue #203 Company invitations and membership lifecycle
-- Application-owned invitation persistence. Raw invitation tokens are never stored.

BEGIN;

CREATE TYPE public.company_invitation_status AS ENUM (
  'pending',
  'accepted',
  'expired',
  'revoked'
);

CREATE TABLE public.company_invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL
    REFERENCES public.companies(id) ON DELETE CASCADE,
  email_normalized text NOT NULL,
  role public.company_role NOT NULL,
  status public.company_invitation_status NOT NULL DEFAULT 'pending',
  token_hash bytea NOT NULL,
  invited_by_user_id uuid NOT NULL
    REFERENCES auth.users(id) ON DELETE RESTRICT,
  expires_at timestamptz NOT NULL,
  delivery_attempt_id uuid NOT NULL DEFAULT gen_random_uuid(),
  last_confirmed_delivery_attempt_id uuid,
  send_count integer NOT NULL DEFAULT 0,
  last_sent_at timestamptz,
  accepted_at timestamptz,
  accepted_by_user_id uuid
    REFERENCES auth.users(id) ON DELETE SET NULL,
  revoked_at timestamptz,
  revoked_by_user_id uuid
    REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT company_invitations_email_normalized_check CHECK (
    email_normalized = lower(btrim(email_normalized))
    AND char_length(email_normalized) BETWEEN 3 AND 320
    AND position('@' IN email_normalized) > 1
  ),
  CONSTRAINT company_invitations_role_check CHECK (
    role <> 'owner'::public.company_role
  ),
  CONSTRAINT company_invitations_send_count_check CHECK (
    send_count >= 0
  ),
  CONSTRAINT company_invitations_expiry_check CHECK (
    expires_at > created_at
  ),
  CONSTRAINT company_invitations_state_check CHECK (
    (
      status = 'pending'::public.company_invitation_status
      AND accepted_at IS NULL
      AND accepted_by_user_id IS NULL
      AND revoked_at IS NULL
      AND revoked_by_user_id IS NULL
    )
    OR (
      status = 'accepted'::public.company_invitation_status
      AND accepted_at IS NOT NULL
      AND accepted_by_user_id IS NOT NULL
      AND revoked_at IS NULL
      AND revoked_by_user_id IS NULL
    )
    OR (
      status = 'expired'::public.company_invitation_status
      AND accepted_at IS NULL
      AND accepted_by_user_id IS NULL
      AND revoked_at IS NULL
      AND revoked_by_user_id IS NULL
    )
    OR (
      status = 'revoked'::public.company_invitation_status
      AND accepted_at IS NULL
      AND accepted_by_user_id IS NULL
      AND revoked_at IS NOT NULL
      AND revoked_by_user_id IS NOT NULL
    )
  )
);

CREATE UNIQUE INDEX company_invitations_token_hash_uidx
  ON public.company_invitations (token_hash);

CREATE UNIQUE INDEX company_invitations_pending_company_email_uidx
  ON public.company_invitations (company_id, email_normalized)
  WHERE status = 'pending'::public.company_invitation_status;

CREATE INDEX company_invitations_company_status_created_idx
  ON public.company_invitations (company_id, status, created_at DESC);

CREATE INDEX company_invitations_expires_at_idx
  ON public.company_invitations (expires_at)
  WHERE status = 'pending'::public.company_invitation_status;

CREATE INDEX company_invitations_invited_by_idx
  ON public.company_invitations (invited_by_user_id);

CREATE INDEX company_invitations_accepted_by_idx
  ON public.company_invitations (accepted_by_user_id)
  WHERE accepted_by_user_id IS NOT NULL;

CREATE INDEX company_invitations_revoked_by_idx
  ON public.company_invitations (revoked_by_user_id)
  WHERE revoked_by_user_id IS NOT NULL;

ALTER TABLE public.company_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY company_invitations_select_managers
ON public.company_invitations
FOR SELECT
TO authenticated
USING (
  private.has_company_role(
    company_id,
    ARRAY['owner', 'admin']::public.company_role[]
  )
  OR private.is_platform_admin()
);

CREATE TRIGGER company_invitations_set_updated_at
BEFORE UPDATE ON public.company_invitations
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

REVOKE ALL ON TABLE public.company_invitations FROM PUBLIC;
REVOKE ALL ON TABLE public.company_invitations FROM anon;
REVOKE ALL ON TABLE public.company_invitations FROM authenticated;

GRANT SELECT, INSERT, UPDATE ON TABLE public.company_invitations TO service_role;

COMMIT;
