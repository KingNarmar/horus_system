# Issue #357 — Business-document quota rollout and recovery plan

**Status:** #357 quota/guard migrations deployed on Development (169 migrations). Cleanup scheduler rollout is in progress on Development only. PR remains Draft; Production untouched.  
**Branch:** `feature/357-business-document-quota-lifecycle`.  
**Parent:** [#191](https://github.com/KingNarmar/horus_system/issues/191).  
**Contract:** [#207](https://github.com/KingNarmar/horus_system/issues/207).

## Counted resources (per company)

One successfully committed **live attachment slot** counts as one document: a live Trip document, active Fleet-license file/side, signed Driver-compensation contract reference, or current Driver licence/national-ID image (front or back). Driver profile pictures, company branding/logo, and generated invoice/report exports are excluded. Replacing one occupied slot does not increase the count. Historic Trip/Fleet references remain in private Storage but are not charged when removed. Compensation revisions have no delete lifecycle: retained contract references continue to count.

Backfill needs no quota counter migration because committed usage is calculated from existing company-scoped metadata. On the 2026-11-14 Development read-only baseline, 48 objects comprised 44 referenced paths (24 live, 20 historical), 4 unreferenced legacy national-ID objects, and 3 profile images among the live set; proposed live charged occupancy totals 21 across 5 companies. The legacy four must not be automatically deleted based on this snapshot alone.

## Ownership and write boundary

- Domain: reusable file-location references and typed business-document failures, with feature-owned use cases/permissions left intact.
- Data: per-tenant reservation RPC + Storage bytes upload + feature-specific metadata commit; no Storage or SQL in Cubits.
- DB migration 1: `20261114103000_issue_357_document_quota_reservations.sql` creates private reservations, aggregate projection and quota assertion, protected reserve/release. **It does not tighten Storage policies**, so a partial rollout cannot block old upload clients.
- DB migration 2: `20261114104000_issue_357_document_commit_guards_cleanup.sql` consumes reservation inside the same metadata transaction, protects historical references from direct Storage deletion, gates restores, supports secure cleanup claims, and **atomically installs the restrictive Storage INSERT/UPDATE policies only after the metadata guards**.
- Server cleanup: `supabase/functions/business-document-cleanup/index.ts` uses the injected service-role key **only on the server**, after a 256-bit random Vault token is verified by a **service_role-only RPC**. The Edge endpoint sets `verify_jwt=false` intentionally so its own private scheduler token (not a user JWT) can authenticate. Unauthenticated or invalid-token calls return 401; missing backend configuration fails closed.
- DB migration 3: `20261114160000_issue_357_vault_cleanup_scheduler.sql` enables `pg_net`, generates the token inside Vault without returning its value, and creates the trusted authorization RPC. Scheduling is environment-specific: only when `horus.cleanup.url` is supplied in the **same migration transaction** does it create a Vault-held function URL and `*/15 * * * *` Cron job. A standard local migration replay deliberately omits the setting and creates no network job. No Development project reference or credential belongs in reusable source SQL.

The DB ledger is authoritative for pending operations; only committed metadata counts permanently. One company-row lock serializes new lease reservations with existing quota producers, while the metadata commit exchanges the pending slot for the live slot within one DB transaction. Database transactions cannot cover Storage bytes: after error or crashed client, the deferred server worker reconciles safely.

## Hosted rollout and approval boundaries

1. Verify migration compatibility on a disposable, isolated database with production-like schema. Review the SQL, existing role policies, grants and old-client behavior; no direct edit to hosted Supabase.
2. The first two migrations have been explicitly approved and applied to **Development only**. Do not reapply, edit them in place, or touch Production.
3. The owner separately approved the **Development cleanup deployment and secure schedule**. Run the third migration with the verified public Development cleanup URL injected by `SET LOCAL horus.cleanup.url` in the same transaction, verify Vault secret exists **without reading its contents**, and confirm the cron job is bound to the Development endpoint. Then deploy the matching Edge function with `verify_jwt=false`; its handler validates the private Vault token before any service-role mutation. No secret is visible in Flutter, Git, tools output or `cron.job.command`.
4. Trigger one smoke invocation from SQL using `net.http_post` with the Vault token inside the database; inspect `net._http_response` and function logs for a successful zero-claim run. Test unauthenticated access returns 401 and no object was modified. Check scheduled job status/runs. No injection of secret into model output.
5. Run signed-JWT positive/negative controls for owner/admin/operations/accountant/viewer, anonymous/foreign-tenant/suspended, direct REST metadata, direct Storage insert/update/delete and historical read.
6. Test 49→50 and 51st rejection, two concurrent 50th uploads, repeated operation ID, replacement at 50/50, cancellation, upload timeout, metadata commit timeout, app crash, expiration, cleanup retry and tenant-scoped audit/realtime.
7. Test EN/AR RTL UX and Android/Windows; include iOS before release gate #202. Run `flutter pub get`, `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` and `git diff --check`.
8. Align #362 minimum-client-version/update enforcement before introducing restrictive Storage policies in Production; old binaries may otherwise be unable to upload. Obtain fresh Production pre-deploy backup and **separate explicit Production approval**, preserve historic bytes, confirm rollback strategy.
9. Never mark #357 complete or merge without the above evidence, review and approval. Previous closed quota issues #354/#32/#355/#356 remain closed.

## Recovery behavior

Failed/cancelled operations must release capacity immediately when possible. For ambiguous client/network outcomes, only server-side cleanup after lease expiry/grace may delete an object; it checks **all** live and historical metadata references first. Removal of an object referenced by Trip/Fleet/Driver metadata is forbidden. Cleanup failures remain retriable; no direct `DELETE FROM storage.objects`. Pre-existing unreferenced objects without a matching ledger entry require a separately audited manual review.

## Known preflight gates

- Full CI has verified Flutter formatting, analyze, tests, Windows/Android builds, signed JWT/Storage tests and the prior migration replay; rerun after changes to the scheduler migration and Edge source.
- The initial Development Edge v1 was safely deployed without a schedule. The revised Vault-authenticated v2 and 15-minute schedule must pass isolated tests before hosted activation.
- Migration and strict RLS changes are not backward-compatible with older upload clients; rollout is staged.
- #357 remains **work in progress** until Development recovery, audit/realtime and client manual smoke tests pass and a separate merge authorization is given.
