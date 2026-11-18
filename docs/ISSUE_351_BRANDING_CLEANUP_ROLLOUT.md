# Issue #351 — Company-branding Storage cleanup (Development verified; Production pending)

**Status (2026-11-18):** Development managed migration `20261117121333_issue_351_branding_cleanup` **APPLIED** on `zwnfmszssxtfxkaofnhq`; `business-document-cleanup` Edge Function **v3 ACTIVE**. Vault-authenticated HTTP smoke 200 cleaned six disposable, unreferenced retired logos (6/6) with 0 deferrals. Hosted authorized Windows UI smoke subsequently proved an issued invoice retains its original private logo version after the company's logo changes. PR #385 was squash-merged into `main` as `fc815d90`; PR #386 UI integration remains a separately gated merge. **Production unchanged and requires separate approval.**

**Migration-history note:** The Development-only #358 operator bootstrap `20261115114601` is intentionally stored outside the shared migrations directory, under `supabase/development_only_migrations/`; never copy it into the shared chain or use `migration repair --status reverted` to bypass history drift. The managed Development migration received version `20261117121333`, so the shared source filename was realigned without re-executing its SQL. The SQL content was retained unchanged to match the already applied migration exactly. Before future environment-specific CLI deployments, reconcile the known Development-only history safely; do not silently repair or reapply it.

## Ownership and boundaries

Company logo version selection remains an Owner/Admin operation through the existing
`set_company_brand_logo` company-scoped RPC. The branding cleanup ledger, expiry,
reference checks, lease claim and completion belong to private PostgreSQL/DB service
functions in `supabase/migrations/20261117121333_issue_351_branding_cleanup.sql`.

The existing Vault-authenticated, service-role-only `business-document-cleanup`
Edge Function orchestrates BOTH the original #357 document cleanup and this
small, isolated branding cleanup worker in `branding_cleanup.ts`. It invokes
`storage.from('company-branding').remove()` and **never** deletes storage
metadata with SQL. Company logo uploads are **not** Free Starter business documents.

No Flutter/Domain changes or alternate Cron, token, bucket or public URL.

## Eligibility / retention

- A still-`reserved` asset is eligible only after its reservation has expired
  **and** the existing #357 10-minute grace period has passed.
- A `retired` asset is eligible only after `retired_at` plus the same grace;
  already-retired assets receive `retired_at=now()` upon deploying the migration.
- `active`, `released`, `cleaned`, or **referenced** assets cannot be claimed.
  Retired logos referenced by the issuer snapshot of **any issued invoice**
  must remain available indefinitely under the current contract.
- A `cleanup_pending` lease is retried after the existing #357 retry interval
  (15 minutes). A worker crash or ambiguous result does not falsely mark a
  file as deleted. A retry may safely encounter an already-missing Storage file.
- The company ID in each canonical immutable object key must match its ledger
  `company_id`. Query and object-key boundaries are server-owned.
- All service RPCs are granted **only** to `service_role`; neither
  `authenticated` nor `anon` may claim, verify, defer or complete cleanup.
- Durable operational evidence lives in company-scoped private ledger fields:
  `cleanup_attempts`, `last_cleanup_error_code`, `cleanup_claimed_at`,
  `retired_at` and `cleaned_at`. These are not public app fields. The
  user-facing branding history is already audited by the existing RPCs.

## Shared scheduler

The existing `horus-business-document-cleanup` pg_cron job keeps its current
identity, command, Vault credentials and Dubai-midnight cadence. A
`CREATE OR REPLACE` update to the **existing work predicate** allows the job
to wake on either original #357 due work or new #351 due work. No migration
creates/activates a Cron job; disposable migration replay is safe.

The Edge Function preserves the original #357 behavior. It processes the
branding claims separately using a fixed 25-item batch, checks current
company and issued-invoice references again before calling Storage, verifies
deletion through the completion RPC, and tracks deferred errors by stable
codes. No user secrets, Storage paths or JWTs appear in HTTP responses.

## Hosted Development rollout evidence (2026-11-17)

- **Database:** Managed migration version `20261117121333`, already aligned with its shared source filename; existing Development-only #358 history preserved without repair.
- **Deployment:** Edge Function `business-document-cleanup` updated from v2 to v3 with `verify_jwt=false` unchanged. Both hosted file contents verified byte-for-byte against the reviewed PR A sources; Vault Bearer-token authorization and service-role RPC checks are retained.
- **Smoke:** A single explicitly authorized Development-only invocation using the existing pg_cron Vault endpoint/token returned HTTP **200**: `status=completed`, `inspected=0`, `cleaned=0`, `deferred=0`, `branding_inspected=6`, `branding_cleaned=6`, `branding_deferred=0`. The six existing retired logos were all known disposable test assets; the owner explicitly confirmed their loss was acceptable, so a single-asset-only smoke was replaced with this six-asset controlled smoke.
- **Post-run verification:** All six records moved to `cleaned` with non-null `cleaned_at`; 0 `retired`/`cleanup_pending`, 0 pending errors, 0 still-present Storage objects, 0 cleaned records referenced by active company branding or issued invoices, 0 active logo rows at the time of this verification. No hosted active-logo or issued-invoice fixture existed to exercise that preservation end-to-end; mandatory protection continues to be covered by isolated CI and the DB reference checks.
- **Scheduler:** Existing `horus-business-document-cleanup` remains active at `0 20 * * *` in GMT (Dubai midnight). Command, username, Vault references and HTTP endpoint unchanged. **No Cron was created, disabled, rescheduled or replaced.**
- **Regression/CI:** PR A's 13 GitHub workflow runs all succeeded at head `3cb7ccd5`; stacked PR B's UI Quality run succeeded at head `33ce5e23`. Automated #357 signed-JWT and Storage contract regressions passed. The hosted smoke had 0 due #357 documents, so no document deletions were attempted.
- **Scope / remaining gates:** No Production deployment, no PR merge, no source changes to app code; next actions require a separate review of PR readiness, user-facing smoke as relevant, and explicit approvals for merges and later Production rollout.

## Hosted immutable invoice-logo preservation (2026-11-18)

- **Real authorized Windows + Development test:** The Owner uploaded the first company logo, issued invoice `f7dd98af-7be4-43b0-93de-e74518780708` in `HORUS 354 Free Starter Test`, then replaced the company's current logo with a second version using the normal app UI.
- **Read-only PostgreSQL evidence:** Invoice remained `issued` with `issuer_snapshot_source='issuance'` and stored old immutable `issuer_logo_path` ending `cb2ae31c-c066-47a6-b163-89ea81ce66d4.png`, while current `public.companies.logo_url` points to the new `bd911689-e0e9-4000-a48e-e30c2ae61e1e.png` version.
- **Storage and lifecycle:** Both files are physically present in the private company-branding bucket; new company logo ledger state = `active`; original invoice-logo ledger state = `retired`. Both are referenced/protected according to `private.company_branding_logo_is_referenced`, with **zero protected cleaned** records.
- **Boundary:** No hosted post-grace cleanup invocation was made against these protected fixtures. Negative claims/nondeletions were tested in passing isolated signed-JWT and Storage contract CI. This verification does not constitute PDF preview/print output testing; that is Issue #352.
- **GitHub:** PR #385 merged into `main` at `fc815d90`; PR #386 retargeted to `main` for an independent UI-only diff and required CI. **Production not modified.**

## Mandatory verification before Production

1. CI: full migration replay, #351 signed-JWT baseline, new cleanup contract
   with a disposable local Supabase stack and real Storage REST DELETE,
   plus #357 signed-JWT regression and Flutter quality gates.
2. Verify `claim_*`, `verify_*`, `defer_*`, `complete_*` granted only to
   `service_role`; private ledger RLS and no client table grants.
3. Confirm the previously uploaded 6 retired Development logo objects:
   none linked to issued invoices; no deletion before migration approval and
   the post-rollout grace. Preserve the object IDs and checksums for rollback.
4. Confirm reference preservation for active brand and immutable issued
   invoices; role and cross-tenant negative cases; expired reservations and
   both successful and failed/retried Storage deletion.
5. Confirm existing #357 Cron command, schedule, status and Vault token are
   unchanged by the migration. If inactive, it must remain inactive.
6. Development Edge runtime smoke completed using all six expressly disposable
   retired test logos after explicit owner confirmation (see evidence above).
   Revalidate new active-logo and issued-invoice cases before any Production rollout.
7. Separately review Production backups, storage reference counts, schema/
   migration alignment, old-client compatibility and an operational rollback
   before Production changes or store release.

### Development read-only checks (after separately approved deployment)

```sql
SELECT state, count(*) AS total,
       count(*) FILTER (WHERE cleaned_at IS NOT NULL) AS completed,
       sum(cleanup_attempts) AS attempts
FROM private.company_branding_uploads GROUP BY state ORDER BY state;
```

Use **one verification SQL block at a time** and wait for the operator response
for any hosted deployment. No SQL from this document is authorized for write.

## Rollback strategy

- Stop/revert only the Edge extension if it behaves incorrectly. Original
  #357 document cleanup must continue with its existing Vault and Cron gate.
- Do not delete private ledger columns or force the state to `cleaned`.
  Source code can be reverted without losing lease/operational evidence.
- An installed combined work predicate will still wake the old #357 handler
  on due branding work, but the prior handler will not remove branding assets.
  If recurring wakeups become problematic, deploy a separate, reviewed
  forward migration restoring the old predicate, without touching tenant data.
- Restoring deleted objects requires previously backed-up bytes; deletion is
  irreversible. Never delete an asset referenced by an issued invoice.

## Current issue gates

PR #385 (backend) was squash-merged to `main` after Development verification;
PR #386 (Flutter) is a separate UI PR with owner approval conditional on
required GitHub checks. Production database migration and Edge deployment remain
separate, explicit owner-approval gates. No merger authorizes Production rollout.
