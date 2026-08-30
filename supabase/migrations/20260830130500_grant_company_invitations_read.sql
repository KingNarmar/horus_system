-- H.O.R.U.S System — Issue #203 Company invitations and membership lifecycle
-- Allow authenticated clients to read invitations only through RLS.

BEGIN;

GRANT SELECT ON TABLE public.company_invitations TO authenticated;

COMMIT;
