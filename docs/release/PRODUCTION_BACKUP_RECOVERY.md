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
