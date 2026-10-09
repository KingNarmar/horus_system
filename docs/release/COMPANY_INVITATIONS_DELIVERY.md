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
3. Confirm server secret **presence**, not values: `HORUS_INVITATION_APP_URL`, `HORUS_INVITATION_BREVO_API_KEY`, `HORUS_INVITATION_EMAIL_FROM_EMAIL`, `HORUS_INVITATION_EMAIL_FROM_NAME`, `HORUS_INVITATION_CONFIRMATION_SECRET`.
4. Confirm sender domain and from-address are accepted by Brevo and that Transactional Email API access is active. Auth SMTP credentials must not be substituted for the Brevo API key.
5. Validate `https://kingnarmar.com/horus/invitation` handoff and its URL-token handling without leaking actual tokens.
6. Inspect production database policies, RPC EXECUTE grants, live SECURITY DEFINER bodies and server-side audit invariants. Run one read-only SQL block at a time.
7. Obtain separate explicit authorization to deploy the reviewed artifact. Document exact source commit and deployed function version.

## Resend safety gate — Development evidence and remaining checks

Migration `20261009155000_issue_314_staged_invitation_resend.sql` stages the replacement token, preserves the original until confirmed, and adds server-side pending-attempt locking. A definite Brevo rejection invokes a signed abort; network failures and provider 5xx remain indeterminate and do not automatically invalidate the previous token. The confirmation and abort RPCs require Edge-only HMAC proof.

**Verified in Development (2026-10-09):** successful initial send, confirmed email signup, acceptance with correct role and audit; successful resend increments `send_count` to 2, old code is rejected after successful rotation, new code previews and accepts, and the relevant created/sent/resend-prepared/resent/accepted audit events exist. Deno failure-classification tests and Flutter CI passed on PR #315 at commit `b75c208e` (Android succeeded on retry following a transient CMake ZIP download failure).

**Database protocol regression verified (Development, 2026-10-09):** `supabase/tests/issue_314_invitation_delivery_protocol.sql` was executed using one explicit SQL transaction ending with `ROLLBACK`. It asserts unauthorized Viewer resend is rejected (`P2805`), a second sequential resend is blocked (`P2816`), the old token remains intact during an indeterminate attempt, a signed definite-failure abort preserves the original token, and repeated signed confirmation is idempotent (`send_count` stays 1). No synthetic invitation persisted. The corresponding Deno tests exercise explicit provider rejection, provider 5xx, network exceptions and unknown errors. These tests do **not** establish a true two-connection concurrency result or prove provider delivery on timeout.

**Still a release gate:** demonstrate concurrent resend from two independent database sessions, the distinction between definite provider rejection and uncertain transport responses in a controlled deployment, and a production-grade pre-migration backup/recovery check. Signed-RPC replay, tenant isolation and audit must remain part of the final verification. Successful resend does not prove those failure paths. No migration or function has been deployed to Production.

Production currently has no invitation Edge Function and therefore no previous version to roll back to. A production database migration cannot be undone by simply disabling the Edge Function. Verify a fresh complete recovery set with storage inventory before any approved deployment.

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

## Confirmation proof provisioning gate

The Issue #314 database migration creates `private.company_invitation_confirmation_keys` without inserting any key or secret. Before deploying the Edge Function, independently generate a high-entropy `HORUS_INVITATION_CONFIRMATION_SECRET` (32+ characters) in a secure environment, provision it only in Supabase Edge Function secrets, and store its SHA-256 digest in the private PostgreSQL guard table by an approved, audited administrative operation. Never paste the secret into chats or commit either value. Validate that a signed confirmation succeeds with the test account and an unsigned authenticated RPC call fails. If the values do not match, the function must fail closed before preparing invitations.
