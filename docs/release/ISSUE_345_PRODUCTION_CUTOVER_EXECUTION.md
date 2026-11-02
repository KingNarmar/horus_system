# Issue #345 — Production cutover execution and release evidence

**CURRENT STATUS — 2026-11-02:** Application schema cutover was **COMMITTED**
to the existing Production project. The pre-cutover test Auth identities were
deleted. Three Production-specific ACL repair migrations were applied,
and the Production database was independently verified against Development.
Production remains a **QA environment, not commercially released**.
Cron is intentionally **PAUSED**. PR #346 remains DRAFT until migration
portability, repository history and release documentation are validated.

> **DO NOT RE-RUN THE DESTRUCTIVE CUTOVER.**
> The original pre-impact guard, dependency detachment, object drop/rebuild,
> migration-history rebaseline and frozen Development restore scripts below
> were **one-time execution artifacts** for the PREVIOUS Production state.
> Their preconditions no longer match current Production. These instructions
> are archived for audit only, **not** an operator task or release checklist.
> No repeat export, Docker recovery-stack replacement or Development
> business-data copy is authorized.

## Completed Production cutover (actual outcomes)

- Existing project ref `rkhmfbxlduuovlbsxhgy` preserved; Development source
  `zwnfmszssxtfxkaofnhq` not overwritten.
- 2026-10-30 frozen public/private schema, SHA-256
  `6090529D9F2DE7E01408557AB80EFF50064EFEF5D470AEF11011CC1312EA411B`,
  was applied in one guarded transaction; SQL operator transcript reported
  `APPLICATION SCHEMA + MIGRATION METADATA TRANSACTION COMMITTED`.
- Five **original, disposable** Production Auth identities were removed via
  supported Auth Admin UI after the structural cutover. New QA accounts were
  created later; don't confuse these with the original identities.
- Dev-equivalent application inventory independently verified: **37 tables**
  (all RLS enabled), **137 functions**, **70 triggers**, **74 public RLS
  policies**, **13 Storage policies** and **15 Realtime policies**.
- Production-only grants were narrower after repair. Applied migration
  versions: `20261101150237` (functions), `20261101152235` (tables),
  `20261101155147` (columns). Function, table, column and default-privilege
  parity with the Development baseline was independently verified.
- `supabase_migrations.schema_migrations` has **159** applied versions:
  156 source baseline versions + 3 Production-only repairs. This is
  intentional provenance metadata, not a claim that the 156 historical SQL
  files were replayed one by one.
- `send-company-invitation` Edge Function on Production is ACTIVE at version
  2, with `verify_jwt=true`, deployed from the reviewed Development source.
  The stale account-deletion-finalizer Edge Function was **not** deployed.
- Original Production-specific invitation confirmation digest was preserved;
  private `business-documents` and `driver-documents` buckets retained.
- Preserved backup `HORUS_Production_PreCutover_FINAL_v2.7z` passed local
  archive test and its off-site copy was verified by file existence/size.
  No post-cutover restore rehearsal is claimed.

## Bounded release-gate evidence (not repeated full-feature QA)

| Gate | Verified | Remaining / qualification |
| --- | --- | --- |
| A. Structural security | Table/function/trigger counts, RLS, Storage/Realtime policy inventory and ACL parity PASS; no anon-executable public SECURITY DEFINER RPCs after repair | Repo migration portability must be verified before PR merge |
| B. Auth and onboarding | New Owner account, invoice-ready company defaults and Admin invitation/acceptance confirmed | Hosted SMTP/redirect/Cloudflare configuration not independently re-read in this pass |
| C. SaaS finance/audit | Cross-account trip create, Fuel expense, stored 100.00 AED freight, 20.00 AED expense, 80.00 AED derived profit and structured audit PASS; earlier Development tenant/RLS contracts PASS | Production nonmember signed-JWT denial not independently demonstrated; SQL-simulated nonmember Storage SELECT returns zero |
| D. Integrated behavior | Windows/Android cross-user Realtime for Company Expenses, Routes, Trips, Trip Expenses PASS; private Storage upload and driver details display PASS; invitation acceptance PASS | Signed URL negative test not independently demonstrated; Cron remains intentionally inactive pending explicit activation decision |

On 2026-11-02, direct read-only Production catalog snapshot also showed two
new QA Auth identities, two QA companies, two private Storage objects, and
three subscription-plan rows with **zero placeholder monthly prices**.
These are QA records; **zero prices are not approved commercial pricing**.

## Migration-history reconciliation (Git only; no database writes)

Three original Production-only ACL repair SQL files have been copied
byte-for-byte to
`scripts/release/issue_345_applied_production_migrations/`
with provenance documented in its README. Their existing version-numbered
`supabase/migrations/` files now contain **read-only, fail-closed** assertions
of the intended Development baseline. This is a deliberate and documented
difference between the executed historical SQL and its canonical
version-number checkpoint. Production has already recorded all three
versions; Development has correct ACLs and must not run the historical
Production repair bodies.

The SQL is not yet certified replayable: prove the CLI migration plan,
a disposable local replay, and remote `--dry-run` before merging. Do not
apply any live migration or rewrite remote history to make a check pass.
If an older, unrelated historical migration-version mismatch prevents
local replay, report it as a separate blocker without destructive fixes.

## Eight historical migration filenames aligned (Git-only)

Before this correction, eight **existing** migration files in Git had a
different numeric timestamp than their corresponding *same-named* applied
versions on **both** Development and Production. The timestamp, not the
migration SQL content, was inconsistent.

The eight files below were renamed using their **existing Git blob SHA**,
with no SQL edits and no relative-order change:

| Git's former version | Applied version now used in Git | Migration |
| --- | --- | --- |
| 20260927160000 | 20260927124126 | issue_196_account_deletion_lifecycle |
| 20260927161000 | 20260927124826 | issue_196_storage_ownership_finalization |
| 20260927162000 | 20260927132441 | issue_196_automatic_finalization |
| 20260927163000 | 20260927132451 | issue_196_finalizer_observability |
| 20260927164000 | 20260927132459 | issue_196_cron_privileges |
| 20260927165000 | 20260927132508 | issue_196_remove_obsolete_finalizer_rpcs |
| 20260930160000 | 20260930160127 | issue_196_account_deletion_audit_finalizer_hardening |
| 20261009155000 | 20261009160648 | issue_314_staged_invitation_resend |

**Independent remote migration-list verification (read-only, 2026-11-02):**
Git has 159 version/name pairs; Production has **159/159 exact pairs**,
with zero local-only and zero remote-only versions. Development has **156/156
exact applied pairs** plus *only* the three expected, verification-only
2026-11-01 Production ACL checkpoint versions not yet recorded there.
The remote databases and their migration histories were **not modified**.

The three checkpoint SQL blocks each executed **successfully** in
`BEGIN READ ONLY ... ROLLBACK` transactions on both Development and
Production. This proves the existing effective catalog baseline passes
their assertions, but does **not** replace a full clean local reset or
Supabase CLI dry-run.

## Final release decisions — NOT YET AUTHORIZED

1. Verify migration history/portability and publish accurate PR evidence.
2. Confirm Production hosted Auth/SMTP/redirect settings and Cloudflare
   remain correct, without exposing credentials.
3. Decide whether accepted nonmember SQL RLS proof and Development JWT
   contracts satisfy the bounded security gate, or whether a single
   automated authenticated denial is required; **no third manual test account
   or repeated feature QA**.
4. Review the commercial subscription price placeholders before paid launch.
5. Only after explicit release approval, activate the named Cron
   `horus-account-deletion-finalizer` at `17 * * * *`, verify its state,
   and sign off the release gates.

Do not merge PR #346, enable Cron, run SQL writes or claim final release
until these decisions are recorded.

---

## HISTORICAL PRE-CUTOVER PLAN — ARCHIVED, DO NOT EXECUTE

The sections below preserve the original frozen source inventory, recovery
path and operator instructions as historical evidence only. Statements about
work being "pending" describe the **former** 2026-10-30 state, not today.

## Immutable sources and recovery

- Production project: `rkhmfbxlduuovlbsxhgy` (must remain the same hosted project).
- Development source: `zwnfmszssxtfxkaofnhq` (read-only).
- `main` source commit: `2559a4cdcd15f6dd8eca63a8ebbe77a38313f91c`.
- Existing frozen `public,private` schema-only SQL (workstation only): `HORUS-Production-Cutover-Source-Freeze/DevFreeze_20261030_142052_469/development_current_public_private.sql`
- Exactly 570,819 bytes; SHA-256 `6090529D9F2DE7E01408557AB80EFF50064EFEF5D470AEF11011CC1312EA411B`.
- Production pre-cutover rollback source (do not overwrite): `HORUS-Production-Backups/HORUS_Production_PreCutover_FINAL_v2.7z`; 59,664 encrypted bytes; six original files, 7-Zip test PASS. Offsite: [Drive](https://drive.google.com/file/d/1MAoZEMuse4mDO3s5j6ceWpKLb_9i1Ddg/view).
- The local backup contains production `roles.sql`, `schema.sql`, `data.sql`, manifest/checksums and 123 verified migration records. No repeated export, archive test, or Docker change required.

## Direct read-only managed-schema comparison, 2026-10-30

| Object | Development | Production | Cutover action |
|---|---|---|---|
| Application RLS tables | 37 | 37 | Restore exact Dev definitions |
| Application functions | 137 | 110 | Replace owned implementation only |
| Application triggers | 70 | 49 | Restore exact Dev definitions |
| Realtime app policies | 15 | 1 | Restore all 15 source definitions |
| Storage app policies | 13 | 13 | Detach/recreate **only if** application function replacement requires it |
| Private Storage buckets | 2 | 2 | Preserve; exact settings already match |
| Storage objects | 47 disposable | 0 | Do not copy Dev object bytes |
| Auth test users | 17 | 5 | Delete only Production test identities via supported Auth Admin API |
| App invitation digest rows | 1 | 1 | Preserve **Production** digest, never Dev |
| Auth profile trigger | present | present | Restore when app function replacement requires detachment |
| `ensure_rls` event trigger | present | present | Restore after `public.rls_auto_enable` replacement |
| `horus-account-deletion-finalizer` Cron | active, 17 * * * * | active, 17 * * * * | Pause for cutover and resume after release checks |

**Verified dependency hazard:** Production has 42 dependency records from managed Storage/Realtime policies to application-owned functions, plus an Auth trigger bound to `public.handle_new_user_profile()` and an event trigger bound to `public.rls_auto_enable()`. Blind schema dropping, bulk truncation and removing managed schemas are prohibited.

## Source-controlled cutover building blocks

0. `scripts/release/issue_345_preimpact_guard.sql` — pinned pre-impact SQL guard before any write; checks the expected Production migration count/version and Auth/Storage/Cron state.
1. `scripts/release/issue_345_preserve_prod_key.sql` — snapshots Production's single confirmation digest into `pg_temp` **inside one DB session and transaction**; no digest printed, exported or committed.
2. `scripts/release/issue_345_detach_managed_dependencies.sql` — detaches only H.O.R.U.S-owned policies and the two H.O.R.U.S-owned triggers; it refuses to run without the preserved temp digest.
3. `scripts/release/issue_345_replace_app_objects.sql` — guarded, RESTRICT-only removal of the exact 37 app tables, 110 current functions and 13 enum types; pre-removes the seven tracked RPC-to-rowtype dependencies, and fails closed on any unexpected external dependency. **Source dump MUST then replay in the same transaction**, restoring 137 functions, 70 app triggers, grants and RLS. This driver is unexecuted and has not had a live rollback rehearsal.
4. `scripts/release/issue_345_storage_policy_restore.sql` — 13 exact Development Storage policy definitions from `pg_policies`, H.O.R.U.S-owned only.
5. `scripts/release/issue_345_realtime_policy_restore.sql` — 15 exact Development Realtime policy definitions from `pg_policies`.
6. `scripts/release/issue_345_restore_prod_integrations.sql` — restores **Production's** saved digest, verifies equality without revealing its value, re-creates the Auth profile trigger and RLS event trigger.
7. `scripts/release/issue_345_reference_seed.sql` — three plan capability references (Basic, Pro, Enterprise), **fresh server-generated UUIDs only**. Development `monthly_price = 0` is preserved as an explicit *temporary placeholder* and is NOT commercial release pricing approval.
8. `scripts/release/issue_345_rebaseline_migration_history.sql` — version/name metadata is synchronized **in the same transaction** to the 156 confirmed frozen Development applied versions after full schema replacement. No old SQL is replayed; it matches Supabase CLI `migration repair --status applied` tracking semantics. Original migration SQL remains in Git; `statements` metadata is intentionally empty for repaired rows. Prod's previous 123 entries are protected by the original pre-cutover backup.
9. `scripts/release/issue_345_assert_before_commit.sql` — fail-closed structural and empty-business-data assertions, plus migration-version parity, before commit.
10. Hosted integration restore: preserve Production Auth Site URL/SMTP/templates/redirects, publishable keys, existing Cloudflare configuration and five invitation Edge secret names/values; deploy reviewed current `send-company-invitation` only **after** DB RPC compatibility, never the stale `account-deletion-finalizer` Edge function.

Steps 1–9 (including the frozen schema file) are parts of a **single transaction and single PostgreSQL session**; do not run separately with disconnected SQL tool calls. The source SQL, object cleanup, migration provenance mapping and managed sidecars must pass review *before* opening the maintenance gate. No credentials or raw digest values may appear in logs, GitHub or chat.

## Execution boundaries

- Confirm source hash and project target independently from the operator's connection; fail closed on mismatch.
- Put application clients into a verified maintenance/no-write state; pause the named Cron before disruptive changes. No app sessions should write during policy detachment.
- Delete all five disposable Production Auth users using supported administrative API, not blind edits of managed Auth tables, **after** the schema transaction but **before reopening Production traffic**. Storage object count is currently zero; confirm again before cleanup.
- Use an explicitly transaction-wrapped, `ON_ERROR_STOP` restore with the exact frozen schema, audited dependency drop list and managed sidecars. If any SQL operation fails, rollback the **whole database transaction**.
- Never substitute Dev's invitation digest, Dev's `auth.users`, test companies, operational/financial rows or Storage object bytes.
- Migration history: Prod 123 entries, Dev 156; eight historic migration version mismatches. The verified frozen full schema is restored first, then all 156 exact applied Dev version/name pairs are reconciled atomically inside the same transaction (never blindly `db push`, never replay individual historic migration scripts). This is an intentional tracked-metadata repair, not evidence that each individual historic migration executed on Production.
- Re-enable Cron only after operational integrity checks. The old Docker backup/recovery stacks and volumes are out of scope.

## Four bounded release gates

A. **Structure and isolation:** schema function/trigger/table inventories; schema, column, default ACLs and managed-policy definition parity; RLS and tenant guard, migration provenance; no unexpected privileged grants.

B. **Auth/company onboarding:** one new Production test account confirms email, logs in, establishes Owner membership and fully invoice-ready company defaults. Verify no former Production/Development test company remains.

C. **Core SaaS financial contract:** one representative tenant/role denial and a successful scoped audit + trip financial flow. Do not repeat the legacy exhaustive JWT suites.

D. **Integrated behavior:** private bucket access/isolation, Realtime event across two clients, company invitation delivery/acceptance using Production secret/digest, named Cron active with expected schedule. Confirm hosted Auth configuration/Cloudflare unaffected.

A failed gate **blocks release**. Capture sanitized evidence, re-close maintenance, and use the existing preserved rollback set; do not repeatedly try ad-hoc repair scripts.

## Superseded pre-cutover dependency (historical only)

The frozen Development SQL **was attached and independently SHA-256 verified** in the 2026-10-30 continuation: exactly 570,819 bytes, matching the prior freeze. Offline static inspection confirmed 37 app tables, 137 function definitions, 70 app-owned trigger definitions, 13 enum types and 74 public policies, with no table-data COPY/INSERT section. The uploaded file is *not* committed to public GitHub. The restore step mentioned in this original plan was completed on 2026-10-31/2026-11-01; this paragraph is retained only to preserve the original plan. NEVER execute it again on the current Production database.

## Reference

- [Issue #345](https://github.com/KingNarmar/horus_system/issues/345)
- [Supabase CLI migration/restore guide](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore)
- [H.O.R.U.S backup/recovery](./PRODUCTION_BACKUP_RECOVERY.md)
- [Production Auth configuration](./SUPABASE_AUTH_CONFIGURATION.md)
- [Company invitations](./COMPANY_INVITATIONS_DELIVERY.md)
