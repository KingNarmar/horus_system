# Company invitation delivery — production release gate (Issue #314)

This runbook governs the `send-company-invitation` Edge Function. It does not change Supabase Auth SMTP or the app store submissions.

## Current architecture

- Flutter uses an authenticated `functions.invoke('send-company-invitation')` call from Company Data only.
- The Edge Function forwards the user's bearer token to PostgREST RPCs; no service-role key is used.
- `prepare_company_invitation` persists a scoped pending row and an audit event before provider submission.
- Brevo's 2xx response means **provider accepted the API request**, not verified recipient delivery.
- `confirm_company_invitation_delivery` marks the attempt as confirmed and increments `send_count`.
- Token generation and raw token transport stay server-side and email-only.

## Required preflight (no secrets in chat, commits, client builds or logs)

1. Verify Edge Function bundle imports and Deno tests offline, including token generation, email templates and sender failure behavior.
2. Verify that the intended Supabase project is `rkhmfbxlduuovlbsxhgy`; do not deploy until explicitly approved.
3. Confirm server secret **presence**, not values: `HORUS_INVITATION_APP_URL`, `HORUS_INVITATION_BREVO_API_KEY`, `HORUS_INVITATION_EMAIL_FROM_EMAIL`, `HORUS_INVITATION_EMAIL_FROM_NAME`.
4. Confirm sender domain and from-address are accepted by Brevo and that Transactional Email API access is active. Auth SMTP credentials must not be substituted for the Brevo API key.
5. Validate `https://kingnarmar.com/horus/invitation` handoff and its URL-token handling without leaking actual tokens.
6. Inspect production database policies, RPC EXECUTE grants, live SECURITY DEFINER bodies and server-side audit invariants. Run one read-only SQL block at a time.
7. Obtain separate explicit authorization to deploy the reviewed artifact. Document exact source commit and deployed function version.

## Mandatory unresolved resend gate

**Do not deploy the current resend implementation before this gate is resolved.**

`prepare_company_invitation_resend` immediately replaces `token_hash`, `expires_at` and `delivery_attempt_id`, *before* the Brevo request. On provider rejection or an indeterminate timeout, the previous link can be invalidated even though no usable replacement is confirmed. Concurrent resends may also rotate multiple times.

Design and test a server-authoritative state transition that preserves the previously valid token until a replacement is safely committed, or an explicitly reviewed equivalent. A unique client submission alone is not a distributed idempotency guarantee. Confirm callback idempotence, role checks, timeout behavior, recovery and audit semantics. Any database change must be a versioned migration reviewed before applying.

## Acceptance and monitoring

- Owner invites Admin; database shows one pending company-scoped row and expected server audit event.
- Provider shows accepted/processed outcome; inbox arrival is checked separately.
- Invitation link accepts with the intended verified email exactly once; an accepted replay returns the established idempotent state.
- Admin cannot invite Admin/Owner; unauthorized user, cross-company user and anonymous caller all fail.
- Duplicate/timeout/failed-send/resend tests retain safe token behavior without producing duplicate messages or inaccurate success claims.
- Desktop/mobile/tablet invitation list can be reloaded from authoritative RPC state.
- Collect only sanitized status codes and non-sensitive request identifiers in logs; never expose raw invitation tokens, credentials or recipient addresses.

## Deployment and rollback

- Roll out to a non-production environment first when available, run Deno/unit/integration tests and read-only verification.
- Edge Function is deployed with JWT verification enabled and server-only secrets; never deploy by disabling authentication or RLS.
- Smoke test uses an approved controlled test mailbox; check Brevo events and DB state.
- On failure, stop new sends, preserve audit and invitation state, and roll back to the previously reviewed backend version if one exists. As Production currently has no deployed invitation function, disabling/removing this isolated function restores the prior availability state but does not undo any attempted invitations or database migrations.
- Do not merge PR #315 or close Issue #314 until all quality, security, delivery and acceptance gates have evidence.
