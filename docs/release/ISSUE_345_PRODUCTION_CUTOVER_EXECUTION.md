# Issue #345 — Production cutover execution record

**Status:** preparation artifacts checked in; **Production database has NOT been modified** by these artifacts. The destructive cutover is approved in the 2026-10-30 conversation, but the complete restore input and dependency-safe replacement driver must be present before any destructive command.

## Immutable sources and recovery

- Production project: `rkhmfbxlduuovlbsxhgy` (must remain the same hosted project).
- Development source: `zwnfmszssxtfxkaofnhq` (read-only).
- `main` source commit: `2559a4cdcd15f6dd8eca63a8ebbe77a38313f91c`.
- Existing frozen `public,private` schema-only SQL (workstation only): `C:\Users\minab\HORUS-Production-Cutover-Source-Freeze\DevFreeze_20261030_142052_469\development_current_public_private.sql`
- Exactly 570,819 bytes; SHA-256 `6090529D9F2DE7E01408557AB80EFF50064EFEF5D470AEF11011CC1312EA411B`.
- Production pre-cutover rollback source (do not overwrite): `C:\Users\minab\HORUS-Production-Backups\HORUS_Production_PreCutover_FINAL_v2.7z`; 59,664 encrypted bytes; six original files, 7-Zip test PASS. Offsite: [Drive](https://drive.google.com/file/d/1MAoZEMuse4mDO3s5j6ceWpKLb_9i1Ddg/view).
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

1. `scripts/release/issue_345_preserve_prod_key.sql` — snapshots Production's single confirmation digest into `pg_temp` **inside one DB session and transaction**; no digest printed, exported or committed.
2. `scripts/release/issue_345_detach_managed_dependencies.sql` — detaches only H.O.R.U.S-owned policies and the two H.O.R.U.S-owned triggers; it refuses to run without the preserved temp digest.
3. Application schema replacement driver — **NOT YET GENERATED**. Must be constructed/reviewed against the frozen local schema and Production dependencies; perform dependency-ordered removal of application objects without `DROP SCHEMA CASCADE` and then restore frozen `public/private` SQL, table/column ACLs/default privileges, functions, triggers, grants and RLS. No unmanaged schema-wide deletion, and no Development test data.
4. `scripts/release/issue_345_storage_policy_restore.sql` — 13 exact Development Storage policy definitions from `pg_policies`, H.O.R.U.S-owned only.
5. `scripts/release/issue_345_realtime_policy_restore.sql` — 15 exact Development Realtime policy definitions from `pg_policies`.
6. `scripts/release/issue_345_restore_prod_integrations.sql` — restores **Production's** saved digest, verifies equality without revealing its value, re-creates the Auth profile trigger and RLS event trigger.
7. Hosted integration restore: preserve Production Auth Site URL/SMTP/templates/redirects, publishable keys, existing Cloudflare configuration and five invitation Edge secret names/values; deploy reviewed current `send-company-invitation` only **after** DB RPC compatibility, never the stale `account-deletion-finalizer` Edge function. Restore only approved reference plan records; Dev's zero-valued test pricing is not commercial pricing.

Steps 1–6 are parts of a **single transaction and single PostgreSQL session**; do not run separately with disconnected SQL tool calls. The source SQL, object cleanup, migration provenance mapping and managed sidecars must pass review *before* opening the maintenance gate. No credentials or raw digest values may appear in logs, GitHub or chat.

## Execution boundaries

- Confirm source hash and project target independently from the operator's connection; fail closed on mismatch.
- Put application clients into a verified maintenance/no-write state; pause the named Cron before disruptive changes. No app sessions should write during policy detachment.
- Delete all five disposable Production Auth users using supported administrative API, not blind edits of managed Auth tables. Storage object count is currently zero; confirm again before cleanup.
- Use an explicitly transaction-wrapped, `ON_ERROR_STOP` restore with the exact frozen schema, audited dependency drop list and managed sidecars. If any SQL operation fails, rollback the **whole database transaction**.
- Never substitute Dev's invitation digest, Dev's `auth.users`, test companies, operational/financial rows or Storage object bytes.
- Migration history: Prod 123 entries, Dev 156; eight GitHub migration version mismatches. Preserve true provenance, record baseline evidence and reconcile via reviewed supported process **after** schema parity. Do not bulk mark files applied or blindly `db push`.
- Re-enable Cron only after operational integrity checks. The old Docker backup/recovery stacks and volumes are out of scope.

## Four bounded release gates

A. **Structure and isolation:** schema function/trigger/table inventories; schema, column, default ACLs and managed-policy definition parity; RLS and tenant guard, migration provenance; no unexpected privileged grants.

B. **Auth/company onboarding:** one new Production test account confirms email, logs in, establishes Owner membership and fully invoice-ready company defaults. Verify no former Production/Development test company remains.

C. **Core SaaS financial contract:** one representative tenant/role denial and a successful scoped audit + trip financial flow. Do not repeat the legacy exhaustive JWT suites.

D. **Integrated behavior:** private bucket access/isolation, Realtime event across two clients, company invitation delivery/acceptance using Production secret/digest, named Cron active with expected schedule. Confirm hosted Auth configuration/Cloudflare unaffected.

A failed gate **blocks release**. Capture sanitized evidence, re-close maintenance, and use the existing preserved rollback set; do not repeatedly try ad-hoc repair scripts.

## Immediate remaining dependency

The frozen Development SQL is presently **only on the operator's Windows computer**, not accessible to the connected Supabase/GitHub tools. Its exact bytes are required to build and validate the dependency-ordered application replacement. Request the **existing** SQL as an attachment; do not ask for a new export, password, service-role key or backup. Until this is available and the replacement driver is reviewed, no destructive Production DB action is safe.

## Reference

- [Issue #345](https://github.com/KingNarmar/horus_system/issues/345)
- [Supabase CLI migration/restore guide](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore)
- [H.O.R.U.S backup/recovery](./PRODUCTION_BACKUP_RECOVERY.md)
- [Production Auth configuration](./SUPABASE_AUTH_CONFIGURATION.md)
- [Company invitations](./COMPANY_INVITATIONS_DELIVERY.md)
