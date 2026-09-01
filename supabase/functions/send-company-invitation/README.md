# send-company-invitation

Server-side delivery adapter for Issue #203 company invitations.

## Security contract

- The Flutter client calls this Edge Function with the signed-in user's JWT.
- The function forwards that same user authorization to the invitation RPCs.
- It never uses `service_role` to bypass tenant or role authorization.
- The raw invitation token is generated in the function, is never returned to Flutter, and is never persisted or audited.
- The database stores only the SHA-256 token hash.
- A successful external email send followed by an uncertain delivery-confirmation RPC returns `company_invitation_delivery_confirmation_unknown`; the function does not automatically resend.

## Required configuration

The Supabase runtime supplies `SUPABASE_URL` and a publishable/anon key. Configure:

- `HORUS_INVITATION_APP_URL` — public website origin used to build `/horus/invitation?token=...` handoff links.
- `HORUS_INVITATION_EMAIL_WEBHOOK_URL` — HTTPS email transport webhook endpoint.
- `HORUS_INVITATION_EMAIL_WEBHOOK_KEY` — bearer credential for that server-to-server webhook.
- `HORUS_INVITATION_EMAIL_FROM` — verified sender identity accepted by the transport.

For the current King Narmar deployment, `HORUS_INVITATION_APP_URL` should be `https://kingnarmar.com`. The public handoff page only presents the invitation token and instructions; invitation authorization and acceptance remain inside H.O.R.U.S System.

If the transport settings are missing, the function fails closed with `company_invitation_delivery_not_configured` before preparing a database invitation.

## Transport boundary

The function intentionally depends on a small webhook contract instead of a vendor SDK. The configured webhook receives JSON with:

- `from`
- `to`
- `subject`
- `text`
- `html`

A non-2xx webhook response is treated as `company_invitation_delivery_failed`.

Provider credentials belong only in server-side secrets. Never add them to Flutter `.env`, repository files, audit logs, or database invitation rows.
