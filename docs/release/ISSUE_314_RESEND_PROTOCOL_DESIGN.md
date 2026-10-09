# Issue #314 — Safe invitation resend protocol (design review)

Status: **Proposed, not implemented or deployed**. This design is a prerequisite to Production Edge Function deployment.

## Verified defect

The existing `prepare_company_invitation_resend` overwrites `company_invitations.token_hash` and the expiry **before** calling Brevo. If Brevo rejects or times out, the last delivered invitation URL can be invalidated. UI-only locking does not protect against two devices, requests or workers.

## Design invariants

1. Never invalidate a previously delivered, unexpired token solely because an attempted resend failed.
2. Never treat Brevo HTTP 2xx as mailbox delivery; distinguish submitted, confirmed in DB, and independently observed provider delivery.
3. A timeout after request dispatch is **uncertain**, not definitely unsent; no automatic replay.
4. Authorize every invitation transition with `auth.uid()`, active company membership, company-scoped invitation ID, and owner/admin target-role rules on the server.
5. No raw token storage, service-role client secret, or recipient/token/credential logging.
6. Acceptance is transactional and idempotent for the same verified recipient. All token hashes for that invitation are invalid after successful acceptance.
7. Audit events describe meaningful state changes and are written by DB-side trusted operations only.
8. Client display must not claim delivery until server confirmation. Retry must refresh authoritative state first.

## Recommended persistence

Use an isolated `company_invitation_delivery_attempts` company-owned table with `company_id`, `invitation_id`, `attempt_id`, `token_hash` (bytea, unique), `expires_at`, `state`, `created_by`, `created_at`, `updated_at`; define an RLS/grants boundary that denies direct anon/authenticated table access. Keep the existing `company_invitations.token_hash` as the previously committed usable token until an explicit finalization policy is approved.

A candidate token is recorded by a scoped preparation RPC. Prepare must atomically reject a second unresolved attempt for the same invitation. Store only its hash. Never rotate the committed token at prepare time.

### Proposed lifecycle

| Event | Durable state | Effect on old token | Effect on candidate |
|---|---|---|---|
| prepare | pending attempt | unchanged | staged |
| Brevo returns 2xx | provider accepted (not delivered) | unchanged | candidate remains staged |
| confirmation RPC commits | confirmed attempt; audit; send_count update | **choose explicit overlap policy** | valid |
| provider returns definitive non-2xx | failed attempt; audit | unchanged | invalidated |
| provider network timeout/unknown | uncertain attempt; requires reconciliation | unchanged | do not blindly resend |
| invitation accepted/revoked/expired | terminal invitation | invalid | invalid |

### Critical unresolved choice

If Brevo accepted but the confirmation RPC fails, the new email may arrive containing the candidate token. Therefore a design that makes staged tokens unusable until confirmation can still generate broken links. Candidate tokens must either be independently redeemable while their attempt is in an explicitly bounded `sent_or_unknown` state, or there must be a documented reconciliation endpoint that safely activates a specific attempt without re-sending email. Any such acceptance logic must validate the verified recipient email and original company scope.

Do **not** promote a candidate and immediately invalidate the old token. An overlap/revocation rule must be consciously selected, tested and audited. Avoid silent token invalidation due to timeout or concurrent resend.

## Transactional review checklist

- Same company owner resends once; scoped staging created without replacing live token.
- Email rejected: old link works; new link cannot be used; audit states failed.
- Brevo accepts and confirm succeeds: new link works, old link behavior matches approved overlap policy.
- Brevo accepts then confirmation times out: recovered new link works after bounded reconciliation; old link not prematurely broken.
- Two simultaneous resend requests: only one active attempt, no duplicate provider calls.
- Different company/user replay cannot finalize or read another tenant's attempt.
- Admin cannot resend an invitation assigning admin; unauthorized/anonymous attempts fail.
- Accepting one token atomically consumes all associated tokens; no duplicate company membership.
- Revoke/expiry invalidates candidate and old link.
- No direct SELECT/INSERT/UPDATE grants for anon/authenticated on attempt table.
- No raw token or credentials in audit, RPC responses to Flutter, or logs.
- Migration compatibility with existing pending Production invitations is verified.
- After migration, verify grants, function signatures, RLS and audit with **one read-only SQL block at a time**.

## Implementation boundary

A new migration must be created using the repository's Supabase CLI workflow and reviewed offline. The Edge Function should depend on a focused delivery-attempt protocol, not expose DB state transitions to Flutter. Flutter's Domain policies, repositories and current company DI remain unchanged unless explicitly necessary. Add SQL integration and Deno mock-provider tests before deployment.

No SQL change from this proposal may be executed on Production without separate permission.
