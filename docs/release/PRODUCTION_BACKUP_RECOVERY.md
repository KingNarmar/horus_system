# Production Backup and Recovery

Issue: #287  
Parent: #191

This runbook defines the production backup, retention, restore-rehearsal, and
recovery-verification contract for H.O.R.U.S.

It applies to the dedicated production Supabase project. Development is not a
restore target and must not be overwritten or repurposed for disaster-recovery
testing.

## Recovery objectives

Initial launch targets:

- Recovery Point Objective (RPO): at most 24 hours.
- Recovery Time Objective (RTO): 4 hours.

These are H.O.R.U.S operational targets, not Supabase service guarantees.
Measure both during every rehearsal. If the measured process cannot satisfy
either target, the release gate remains open until the procedure, plan, or
infrastructure is changed and rehearsed again.

Take an additional backup immediately before any approved high-impact
production database migration.

## Recovery set

A recoverable H.O.R.U.S backup is a set, not a single database file.

Each backup set must contain:

1. database roles dump;
2. database schema dump;
3. database data dump;
4. captured migration-history evidence;
5. Storage object bytes for every production business-document bucket;
6. Storage inventory evidence sufficient to compare object counts/paths;
7. a manifest containing timestamps, source project identity, tool versions,
   file sizes, and SHA-256 checksums.

Database backups do not restore Storage object bytes. Storage must therefore be
backed up and restored independently.

Do not commit backup artifacts, customer data, credentials, database passwords,
service-role keys, S3 access keys, or restore secrets to Git.

## Backup frequency and retention

Until a stronger managed-backup plan is approved:

- create one complete backup set every 24 hours;
- create an additional set before high-impact production database migrations;
- keep at least 7 daily recovery sets;
- keep at least 4 weekly recovery sets;
- keep at least 3 monthly recovery sets;
- store at least one encrypted copy outside the Supabase project/account
  failure boundary.

Retention is a minimum. Legal, contractual, or customer requirements may
require longer retention and take precedence when approved.

A scheduled job is not evidence of a backup. A backup is successful only when
all expected artifacts exist, checksums are recorded, and the manifest is
complete.

## Secret handling

Use environment variables or an approved secret manager for privileged
credentials. Never place secrets directly in scripts, command history that will
be shared, documentation, screenshots, tickets, or repository files.

Backup artifacts may contain authentication and customer data. Encrypt them at
rest and restrict access to explicitly authorized operators.

Do not use Flutter client credentials for backup or restore operations.

## Database backup procedure

Run from a trusted operator workstation with the Supabase CLI version recorded
in the manifest.

Use the production project only as the backup source. The commands below use
placeholders deliberately.

```powershell
$BackupRoot = "<secure-offsite-staging-path>"
$Timestamp = Get-Date -Format "yyyyMMddTHHmmssZ"
$Set = Join-Path $BackupRoot "horus-prod-$Timestamp"
New-Item -ItemType Directory -Path $Set | Out-Null

npx supabase db dump --linked -f (Join-Path $Set "roles.sql") --role-only
npx supabase db dump --linked -f (Join-Path $Set "schema.sql")
npx supabase db dump --linked -f (Join-Path $Set "data.sql") --data-only --use-copy
```

Before running a linked command, verify that the CLI is linked to the production
project. Never assume the active link.

Capture the production migration list separately as evidence. Repository
migration filenames and versions are part of the H.O.R.U.S provisioning
contract established by Issue #197. Do not repair, rewrite, or invent migration
versions during backup.

If the CLI reports an error, the database backup is failed. Do not publish an
incomplete set as recoverable.

## Storage backup procedure

The production private business-document buckets currently include:

- `business-documents`
- `driver-documents`

Before each backup, inventory all production buckets. A newly introduced
business bucket must be added to this runbook in the same change that introduces
its production dependency.

Export the actual object bytes with a supported Supabase Storage/S3-compatible
bulk-transfer method to a bucket-specific directory inside the recovery set.
Preserve object paths exactly.

Record, per bucket:

- bucket name and privacy state;
- object count;
- total exported bytes;
- object-path inventory;
- export completion result.

Do not treat rows in `storage.objects` as a backup of the files themselves.

## Manifest and integrity

After database and Storage exports complete, generate SHA-256 checksums for all
backup artifacts and save them in the recovery set.

PowerShell example:

```powershell
Get-ChildItem -Path $Set -File -Recurse |
  Get-FileHash -Algorithm SHA256 |
  Select-Object Path, Hash |
  Export-Csv -NoTypeInformation (Join-Path $Set "sha256.csv")
```

The manifest must record:

- source environment: production;
- production project ref;
- backup start/end UTC timestamps;
- Supabase CLI version;
- PostgreSQL client version where applicable;
- repository `main` commit SHA;
- latest expected repository migration version;
- database artifact names and sizes;
- Storage bucket inventory/counts;
- checksum-file name;
- operator;
- success/failure status.

Never put passwords or secret keys in the manifest.

## Off-site storage

The authoritative recovery copy must be outside the production Supabase project
and encrypted at rest.

The off-site location must not be a Git repository. Access must be limited to
operators responsible for production recovery.

At least once per retention-policy change, verify that expired sets can be
removed without deleting sets still required by daily, weekly, or monthly
retention.

## Isolated restore rehearsal

A restore rehearsal must use a disposable isolated Supabase target created
specifically for recovery testing.

Never restore into:

- `horus-system-prod`;
- `horus-system-dev`;
- any environment containing customer or development work that must be kept.

Creating a paid project or branch requires explicit cost review/approval before
creation.

Record the target project ref and creation time in the rehearsal evidence.

## Restore order

Use the supported Supabase backup/restore workflow for the isolated target.
Restore only from a backup set whose checksums have first been verified.

Required high-level order:

1. verify artifact checksums and manifest;
2. provision the isolated target;
3. restore required roles/configuration supported by the target;
4. restore database schema;
5. restore database data;
6. reconcile/verify canonical migration history without inventing versions;
7. restore Storage object bytes to their original bucket paths;
8. verify bucket privacy and Storage policies;
9. run the recovery verification gates below;
10. record measured RPO and RTO;
11. destroy the disposable target only after evidence has been retained.

Managed Supabase schemas such as Auth and Storage require the supported restore
procedure. Do not improvise destructive SQL against them.

## Recovery verification gates

A rehearsal passes only when all applicable gates pass.

### Database and migration history

Verify:

- expected schemas and business tables exist;
- canonical repository migration versions are represented as expected;
- no unexpected migration version was invented during restore;
- required extensions, enums, constraints, indexes, functions, and triggers
  exist.

### Tenant isolation and RLS

Verify:

- every company-owned business table has the required `company_id` ownership
  invariant;
- RLS is enabled on protected tables;
- expected policies exist;
- authenticated access cannot cross company boundaries;
- UI/client filtering is not relied on as the security boundary.

Use isolated rehearsal identities/data only. Never copy development test users
into production.

### Grants and protected functions

Verify:

- schema/table/function grants match the production contract;
- protected `SECURITY DEFINER` and infrastructure functions are not executable
  by API roles unless explicitly intended;
- function `search_path` hardening remains intact;
- the `ensure_rls` defense-in-depth event trigger remains present where
  expected.

### Audit integrity

Verify:

- audit rows are company-scoped;
- direct authenticated audit forgery remains blocked;
- protected audit writer behavior and grants match Issue #282;
- restore operations did not weaken audit constraints, policies, triggers, or
  function permissions.

### Storage

Verify:

- expected private buckets exist;
- `business-documents` remains private;
- `driver-documents` remains private;
- restored object counts and paths match the backup inventory;
- sampled restored bytes match their recorded checksums where practical;
- authenticated cross-tenant object access is denied;
- signed-URL behavior works only for authorized tenant objects;
- no recovery step makes a private bucket public.

### Auth and application smoke checks

Verify the isolated target's supported Auth configuration separately from the
database dump. Confirm that recovery documentation identifies any provider,
redirect, SMTP, MFA, or other project-level settings that are not restored by
database files alone.

Where an isolated client smoke test is used, it must point only to the
disposable target and must never embed privileged credentials.

## Evidence

Store recovery evidence outside Git when it contains environment identifiers,
customer-derived metadata, or sensitive operational details.

The Issue/PR may record a sanitized summary containing:

- backup-set timestamp;
- source commit SHA;
- backup artifact/checksum success;
- Storage bucket/count verification result without customer filenames;
- disposable restore target class, not secrets;
- restore start/end and measured RTO;
- measured RPO;
- each verification gate as pass/fail;
- cleanup confirmation.

Do not close Issue #287 from documentation alone. At least one real production
backup and one isolated restore rehearsal must be completed and evidenced.


## First production rehearsal evidence — 2026-09-25

The first real production backup and isolated recovery rehearsal used backup set
`horus-prod-20260925T154336Z`, captured from repository commit
`fc9a1a980b695c50e06f1b397d3abb39fb58b8f3`. The source migration ledger ended
at `20260924154343`.

Sanitized evidence:

- `roles.sql`, `schema.sql`, `data.sql`, migration-history evidence,
  Storage inventory, manifest, and SHA-256 evidence were captured from
  production. All recorded artifact checksums were reverified before restore.
- The encrypted recovery archive was created with 7-Zip AES encryption and
  encrypted headers, passed `7z t`, and had local SHA-256
  `D74B4AED0556A2877FA3F29E7C048430386EA6182B062D0C3F750D86291E3565`.
  A restricted off-site copy was placed in the approved Google Drive location.
  The exact off-site locator and encryption secret are intentionally not stored
  in Git.
- At backup time both private document buckets contained zero production
  objects. Therefore no production Storage object bytes existed to export.
  Recovery capability for non-empty buckets was nevertheless exercised with
  synthetic isolated objects as described below.
- A disposable local Supabase stack was used as the isolated recovery target
  because the Free organization project limit prevented creation of another
  cloud project. Neither production nor development was used as the restore
  target.
- Roles, schema, and data restored successfully onto a clean Supabase baseline.
  The restored snapshot contained 35 public tables; all 35 had RLS enabled.
  Public-table data counts matched the source snapshot, including three
  `subscription_plans` rows and zero rows in the remaining public business
  tables.
- RLS policy definitions matched the source snapshot (73 policy rows), trigger
  definitions matched (61 rows), and `SECURITY DEFINER` function definitions
  matched (67 rows).
- The logical dump did not recreate the Supabase migration ledger. Canonical
  repository versions through `20260924154343` were marked applied in the
  isolated target with `supabase migration repair --local --status applied`;
  migration SQL was not rerun and no version was invented.
- The raw schema restore exposed a recovery gap: the `ensure_rls` event trigger
  was not emitted by the logical schema dump, and default function privileges
  caused API-role EXECUTE drift on protected infrastructure functions. The
  isolated target was repaired from the canonical repository security contract,
  including `20260921120000_create_rls_auto_enable_guard.sql` and the expected
  protected-function revokes. A transactional probe then confirmed that a newly
  created public table automatically received RLS.
- After security reconciliation, anonymous DML access to public tables was zero.
  Production subsequently received canonical migration
  `20260925174900_issue_243_revoke_anon_public_access`; this migration was
  applied after the backup snapshot and is therefore not represented by that
  backup's migration-history evidence.
- Both expected Storage buckets were private with their expected size and MIME
  restrictions. Synthetic upload/download/delete byte round trips passed for
  both `business-documents` and `driver-documents`, including SHA-256 byte
  equality after download. No synthetic object was written to production.
- The disposable recovery stack and workspace were removed after evidence was
  captured, and the repository CLI was returned to the development project.

### Final recovery evidence — 2026-09-27

Follow-up isolated recovery verification closed the functional gaps discovered
during the first rehearsal:

- authenticated cross-company RLS isolation passed with synthetic tenant
  identities and data;
- direct authenticated audit-log forgery was denied, while a legitimate
  server-side mutation produced the expected structured audit event;
- the managed Storage policy set was reconciled from canonical repository
  migrations and verified with the expected final policy contract;
- both private document buckets passed isolated Storage API upload, authorized
  signed-URL, download byte-equality, delete, and cross-tenant denial tests;
- a non-empty synthetic email/password Auth account and identity were restored,
  including preservation of the password hash, and post-restore sign-in passed.
  This proves the current email/password recovery path; MFA, SSO, WebAuthn,
  OAuth, and SCIM require separate rehearsal if enabled later;
- the post-snapshot anonymous-access hardening migration was applied to the
  recovery baseline; anonymous public-table DML and public-sequence privileges
  verified as zero;
- populated synthetic rows for `trip_documents`,
  `fleet_license_documents`, and `fleet_license_document_files` were
  restored in a clean isolated Supabase target using the tested
  trigger-suppression recovery path. All three replacement self-references
  remained intact, no public user trigger remained disabled, and no public
  foreign key remained unvalidated.

The production backup completed at `2026-09-25T16:05:21Z`. Recovery work
started approximately 2 hours 40 minutes later, so the tested recovery point was
inside the 24-hour RPO target.

A final uninterrupted timed recovery rehearsal ran on 2026-09-27 from
`10:25:03.4106819Z` to `10:38:50.9464431Z`. Total measured RTO was
13 minutes 47.536 seconds (13.79 minutes), comfortably inside the 4-hour launch
target. The final gate verified 35 public tables, RLS enabled on all 35,
zero anonymous public-table DML grants, zero disabled public user triggers, and
zero unvalidated public foreign keys.

The RPO and RTO targets are therefore demonstrated for the current launch
recovery procedure. This evidence does not remove the requirement for recurring
backups, retention, integrity checks, and periodic restore rehearsals after
launch.
## Failure handling

If any backup component fails:

- mark the entire recovery set failed;
- do not delete the last known-good recovery set;
- correct the cause and create a new complete set.

If restore or verification fails:

- preserve sanitized diagnostics;
- do not weaken RLS, grants, tenant isolation, audit protections, or Storage
  privacy to make the rehearsal pass;
- fix the procedure or underlying reproducible infrastructure through a focused
  reviewed change;
- create a fresh isolated target and rehearse again.

## Release gate

Before customer data is introduced into production, Issue #287 remains blocked
until all of the following are true:

- this runbook is merged;
- a real production database backup exists;
- production Storage object bytes have a defined and executed backup path;
- the complete set has integrity evidence;
- an isolated restore rehearsal succeeds;
- migration history, RLS, grants, tenant isolation, audit integrity, and Storage
  privacy are verified after restore;
- measured RPO/RTO satisfy the approved launch targets or the targets are
  explicitly revised and approved.

After launch, backup success and restore rehearsals become recurring operations,
not a one-time release task.
