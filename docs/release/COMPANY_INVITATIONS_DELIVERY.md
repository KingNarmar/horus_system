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

## Concurrent resend integration test — two independent database sessions

The existing rollback-only SQL regression deliberately proves the sequential
state machine, not two-session concurrency. The production release gate requires
a controlled Development-only fixture and two independent authenticated clients.

1. Provision a disposable **Development** Owner-created pending invitation with
   a non-deliverable `example.invalid` address. Record the invitation UUID and
   original token hash as internal test evidence. Do not use Production.
2. Start two independent PostgreSQL connections authenticated as the same Owner.
   Arrange for both to request `prepare_company_invitation_resend` for that
   invitation, each with a distinct random SHA-256 candidate, at the same time.
   The first transaction must remain open while the second attempts the RPC;
   then commit the first.
3. Assert exactly one returned `delivery_attempt_id`; the losing transaction
   must receive the typed `P2816` rejection after waiting on the locked row.
   Verify the original token hash is unchanged, there is exactly one pending
   delivery attempt, and only one resend-prepared audit event was written.
4. Simulate definite provider rejection via signed abort to restore the pending
   invitation; assert the previous hash is unchanged. Revoke the fixture
   through the normal audited RPC, retaining immutable audit history.
5. Record both session transcripts with timestamps and sanitized identifiers,
   never token bytes, JWTs, HMAC keys or recipient information.

An executable two-session harness is provided at
`scripts/test_issue_314_concurrent_resend.py`. It uses `psycopg` 3 on a
trusted operator machine, rejects database connection identities that do not
match the H.O.R.U.S Development project, and commits one synthetic fixture
before triggering two independent transactions. It asserts exactly one winner,
`P2816` for the loser, old-token preservation, a single audit event, and
revokes its test invitation using the standard audited RPC.

Run only with a privately supplied Development database connection string,
never committed, printed or supplied through chat:

```powershell
python -m pip install "psycopg[binary]>=3,<4"
$env:HORUS_DEV_DATABASE_URL = Read-Host "Development PostgreSQL connection URI"
python scripts/test_issue_314_concurrent_resend.py
Remove-Item Env:HORUS_DEV_DATABASE_URL
```

The URI must be verified against the Development project before running.
This probe executes controlled database writes and leaves audit history; it
requires explicit authorization to run against the Development database.
Do not run against Production.

**Executed successfully in Development (2026-10-09):** The operator ran the independent-session probe on the Development Session Pooler and supplied the sanitized result: `Issue #314 two-session resend: PASS | outcomes: ['P2816', 'prepared'] | original preserved: True | audit events: 1`, followed by `Fixture revoked via audited RPC.` This is user-reported terminal evidence; the raw connection credentials were not shared or logged in this review. The two-session concurrency acceptance gate is closed. No Production test identity was created.

## Pre-deployment recovery evidence gate

The release requires an additional complete encrypted Production backup set
following `docs/release/PRODUCTION_BACKUP_RECOVERY.md`. Before approving the
migration, verify database roles/schema/data dumps, migration-history evidence,
both business-document Storage buckets and object bytes, SHA-256 manifest,
offsite copy and recoverability. A prior backup or a SQL row count is not
a substitute. The backup tooling must run in an authorized environment with
secure credentials; no secrets or dumps belong in this PR.

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
