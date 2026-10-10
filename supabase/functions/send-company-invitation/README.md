# send-company-invitation

Server-side delivery adapter for Issue #203 company invitations.

## Security contract

- The Flutter client calls this Edge Function with the signed-in user's JWT.
- The function forwards that same user authorization to the invitation RPCs.
- It never uses `service_role` to bypass tenant or role authorization.
- The raw invitation token is generated in the function, is never returned to Flutter, and is never persisted or audited.
- The database stores only the SHA-256 token hash.
- A successful external email send followed by an uncertain delivery-confirmation RPC returns `company_invitation_delivery_confirmation_unknown`; the function does not automatically resend.

## Email delivery architecture

Email delivery is separated into a provider-neutral `CompanyInvitationEmailSender` port and a Brevo-specific adapter. The invitation lifecycle does not depend on Brevo-specific headers or payloads, so changing providers later only requires a new adapter and composition change rather than a refactor of the invitation flow.

The current provider is Brevo Transactional Email using `POST https://api.brevo.com/v3/smtp/email` with the provider-specific `api-key` authentication header.

## Required configuration

The Supabase runtime supplies `SUPABASE_URL` and a publishable/anon key. Configure these server-side secrets:

- `HORUS_INVITATION_APP_URL` — public website origin used to build `/horus/invitation?token=...` handoff links.
- `HORUS_INVITATION_BREVO_API_KEY` — Brevo API credential used only by the server-side adapter.
- `HORUS_INVITATION_EMAIL_FROM_EMAIL` — verified sender email accepted by Brevo.
- `HORUS_INVITATION_EMAIL_FROM_NAME` — display name for the H.O.R.U.S invitation sender.
- `HORUS_INVITATION_CONFIRMATION_SECRET` — 32+ character server-only secret used to sign confirmation/rejection attempts. The database stores only its SHA-256 digest in the private confirmation guard table; provision the matching digest securely outside source control.

For the current King Narmar deployment, `HORUS_INVITATION_APP_URL` should be `https://kingnarmar.com`. The public handoff page only presents the invitation token and instructions; invitation authorization and acceptance remain inside H.O.R.U.S System.

If any required email-provider setting is missing, the function fails closed with `company_invitation_delivery_not_configured` before preparing a database invitation.

## Provider boundary

`BrevoCompanyInvitationEmailSender` owns all Brevo-specific transport details:

- Brevo endpoint
- `api-key` authentication
- provider request headers
- `sender` payload mapping
- recipient array mapping
- HTML body mapping
- non-success/network failure sanitization

The invitation service only depends on `CompanyInvitationEmailSender` and stable typed delivery failures. A Brevo non-2xx response or network failure is mapped to `company_invitation_delivery_failed`; provider response bodies and credentials are not exposed to Flutter or persisted.

Provider credentials belong only in Supabase Edge Function secrets. Never add them to Flutter `.env`, repository files, audit logs, or database invitation rows.

## Issue #314 release blocker

**Production deployment is blocked** until the resend token-rotation contract is fixed and its negative-path tests pass. The current `prepare_company_invitation_resend` RPC rotates the usable token before Brevo accepts the replacement message. This can invalidate a previously emailed invitation on delivery failure. See [`docs/release/ISSUE_314_RESEND_PROTOCOL_DESIGN.md`](../../../docs/release/ISSUE_314_RESEND_PROTOCOL_DESIGN.md) and [`docs/release/COMPANY_INVITATIONS_DELIVERY.md`](../../../docs/release/COMPANY_INVITATIONS_DELIVERY.md). A green Flutter CI build is not permission to deploy this function.

Delivery confirmation and definite-rejection RPCs require an action-scoped HMAC proof. Direct authenticated calls without the Edge secret must fail, even for a company owner. Never log the raw secret, signature, or raw invitation token.
