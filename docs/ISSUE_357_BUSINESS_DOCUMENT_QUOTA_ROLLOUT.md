# Issue #357 — Business-document quota rollout and recovery plan

**Status:** source-only draft, not approved for hosted deployment.  
**Branch:** `feature/357-business-document-quota-lifecycle`.  
**Parent:** [#191](https://github.com/KingNarmar/horus_system/issues/191).  
**Contract:** [#207](https://github.com/KingNarmar/horus_system/issues/207).

## Counted resources (per company)

One successfully committed **live attachment slot** counts as one document: a live Trip document, active Fleet-license file/side, signed Driver-compensation contract reference, or current Driver licence/national-ID image (front or back). Driver profile pictures, company branding/logo, and generated invoice/report exports are excluded. Replacing one occupied slot does not increase the count. Historic Trip/Fleet references remain in private Storage but are not charged when removed. Compensation revisions have no delete lifecycle: retained contract references continue to count.

Backfill needs no quota counter migration because committed usage is calculated from existing company-scoped metadata. On the 2026-11-14 Development read-only baseline, 48 objects comprised 44 referenced paths (24 live, 20 historical), 4 unreferenced legacy national-ID objects, and 3 profile images among the live set; proposed live charged occupancy totals 21 across 5 companies. The legacy four must not be automatically deleted based on this snapshot alone.

## Ownership and write boundary

- Domain: reusable file-location references and typed business-document failures, with feature-owned use cases/permissions left intact.
- Data: per-tenant reservation RPC + Storage bytes upload + feature-specific metadata commit; no Storage or SQL in Cubits.
- DB migration 1: `20261114103000_issue_357_document_quota_reservations.sql` creates private reservations, aggregate projection and quota assertion, protected reserve/release, restrictive Storage INSERT/UPDATE gate.
- DB migration 2: `20261114104000_issue_357_document_commit_guards_cleanup.sql` consumes reservation inside the same metadata transaction, protects historical references from direct Storage deletion, gates restores, supports secure cleanup claims.
- Server cleanup: `supabase/functions/business-document-cleanup/index.ts` uses a server-side service-role key **only** after a private scheduler authenticates with `HORUS_DOCUMENT_CLEANUP_SECRET`; deletes via Storage API and marks a lease cleaned only when the object is gone and not referenced.

The DB ledger is authoritative for pending operations; only committed metadata counts permanently. One company-row lock serializes new lease reservations with existing quota producers, while the metadata commit exchanges the pending slot for the live slot within one DB transaction. Database transactions cannot cover Storage bytes: after error or crashed client, the deferred server worker reconciles safely.

## Hosted rollout: blocked until separate approval

1. Verify migration compatibility on a disposable, isolated database with production-like schema. Review the SQL, existing role policies, grants and old-client behavior; no direct edit to hosted Supabase.
2. Apply the two versioned migrations on **Development only after specific operator approval**, in repo order. Keep Production untouched.
3. Deploy the compatible Flutter clients and the cleanup Edge Function to Development under separate deployment approval. Never store `SUPABASE_SERVICE_ROLE_KEY` or the worker secret in Flutter. The worker needs a protected private scheduler; function JWT verification configuration and scheduler secrets are deployment decisions, not implied by committing the source.
4. Run signed-JWT positive/negative controls for owner/admin/operations/accountant/viewer, anonymous/foreign-tenant/suspended, direct REST metadata, direct Storage insert/update/delete and historical read.
5. Test 49→50 and 51st rejection, two concurrent 50th uploads, repeated operation ID, replacement at 50/50, cancellation, upload timeout, metadata commit timeout, app crash, expiration, cleanup retry and tenant-scoped audit/realtime.
6. Test EN/AR RTL UX and Android/Windows; include iOS before release gate #202. Run `flutter pub get`, `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` and `git diff --check`.
7. Align #362 minimum-client-version/update enforcement before introducing restrictive Storage policies in Production; old binaries may otherwise be unable to upload. Obtain fresh Production pre-deploy backup and **separate explicit Production approval**, preserve historic bytes, confirm rollback strategy.
8. Never mark #357 complete or merge without the above evidence, review and approval. Previous closed quota issues #354/#32/#355/#356 remain closed.

## Recovery behavior

Failed/cancelled operations must release capacity immediately when possible. For ambiguous client/network outcomes, only server-side cleanup after lease expiry/grace may delete an object; it checks **all** live and historical metadata references first. Removal of an object referenced by Trip/Fleet/Driver metadata is forbidden. Cleanup failures remain retriable; no direct `DELETE FROM storage.objects`. Pre-existing unreferenced objects without a matching ledger entry require a separately audited manual review.

## Known preflight gates

- Flutter SDK, Dart analyzer and signed-JWT integration tests are not available in the current connector-only execution environment; source creation alone is not verification.
- The Edge cleanup source has no configured invocation schedule or deployment yet.
- Migration and strict RLS changes are not backward-compatible with older upload clients; rollout is staged.
- The source is still **work in progress** until code review and acceptance tests pass; do not deploy these migration drafts as-is.
