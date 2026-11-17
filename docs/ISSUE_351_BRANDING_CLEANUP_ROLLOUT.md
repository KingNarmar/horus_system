# Issue #351 — Company-branding Storage cleanup (source-only rollout contract)

**Status (2026-11-17):** Approved Development-only managed migration `20261117121333_issue_351_branding_cleanup` **applied and verified** on `zwnfmszssxtfxkaofnhq`. The six retired logos remain in Storage (0 deletions, 0 cleanup claims); the hosted `business-document-cleanup` Edge Function is still v2, and the new branding worker is **NOT DEPLOYED**. Production, PR merge and automatic cleanup activation remain separate gates.

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

## Mandatory verification before hosting

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
6. Run a separately approved Development Edge runtime smoke with a single
   disposable retired test logo **before allowing any automatic cleanup**;
   then review ledger outcomes, 0 newly orphaned objects, audit and
   company isolation. Do not touch Production as part of this check.
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

PR #385 (backend) and stacked PR #386 (Flutter) remain DRAFT until evidence
and explicit merge approval. Applying a migration or deploying any hosted Edge
Function requires **separate owner approval for Development and Production**.
