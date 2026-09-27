# Production Supabase Security and Data-Protection Audit

Issue: #197  
Parent: #191  
Audit date: 2026-09-27  
Repository baseline: `b49e56e046a9730ea4989058e110708871a5115f`

This document records the final launch-readiness security audit for the
dedicated H.O.R.U.S production Supabase environment.

It is a verification record, not a substitute for the canonical migrations,
RLS policies, server-side authorization, or the backup/recovery runbook. The
audit intentionally reuses valid evidence from completed focused security work
instead of repeating destructive or redundant verification.

## Scope and rules

The audit covers:

1. schema and company ownership;
2. RLS enabled state;
3. RLS policies and role boundaries;
4. schema, table, sequence, and function grants;
5. functions, RPCs, triggers, `SECURITY DEFINER`, and `search_path`;
6. private Storage buckets and object policies;
7. seed/default data;
8. cross-tenant negative tests;
9. role negative tests;
10. audit integrity and anti-forgery;
11. Auth/client-secret security;
12. backup, retention, and recovery readiness.

Production remains a separate environment from development. No development
business data is used as production data, and no privileged Supabase credential
is permitted in Flutter client configuration.

## Final result

The Issue #197 production security and data-protection audit is satisfied for
the current launch baseline. No unresolved database security implementation gap
was identified by the final review.

The remaining Supabase Security Advisor findings are either intentional
server-side API boundaries or internal/retired tables whose client access is
blocked by RLS and grants. They are documented below and must be reconsidered if
their access model changes.

## Schema and tenant ownership

Production contains 35 public tables. RLS is enabled on all 35.

Company-owned business tables use the established `company_id` tenant
ownership contract. Tables whose identity is intentionally not a company-owned
business row, including `companies`, `user_profiles`, and
`subscription_plans`, follow their dedicated ownership/access contracts.

The canonical fresh-project migration history was restored under Issue #197.
See `PRODUCTION_DATABASE_BOOTSTRAP.md`.

## RLS and policies

RLS is enabled on every public table.

The policy-free public tables are intentionally non-client boundaries:

- `invoice_sequences`: server-internal invoice numbering;
- `trip_sequences`: server-internal Trip numbering;
- `trip_expenses`: retired legacy table; canonical expense reads use the
  expense ledger.

These tables remain RLS-enabled and expose no client CRUD path. The
RLS-enabled/no-policy Security Advisor entries are therefore informational for
the current architecture rather than missing-policy defects.

Client-facing tables retain company/role-scoped policies. The role-alignment
hardening completed during PC-17 removed the prior same-tenant Driver-role read
bypass.

## Grants and anonymous access

Canonical production migration
`20260925174900_issue_243_revoke_anon_public_access.sql` revokes anonymous
public-table DML, public-sequence access, and unintended public-function
execution.

Final production/recovery evidence confirms:

- zero anonymous public-table DML grants;
- no anonymous callable public `SECURITY DEFINER` API boundary;
- protected audit data cannot be directly mutated by authenticated clients;
- server-internal sequence tables expose no client CRUD path.

The Flutter application uses only client-safe publishable configuration.
Database passwords, service-role/admin credentials, secret keys, and signing
secrets are not client configuration.

## Functions, RPCs, and triggers

Authenticated `SECURITY DEFINER` application RPCs are intentional server-side
API boundaries. Their authorization and tenant checks were reviewed during the
focused Supabase security hardening and subsequent feature security
verification.

The final production review found 40 authenticated-callable public
`SECURITY DEFINER` application RPCs and no anonymous-callable
`SECURITY DEFINER` RPC.

Client-callable privileged RPCs use the hardened search-path contract. Protected
infrastructure helpers are not directly executable by `anon` or
`authenticated`.

The company default-expense-category seed helper remains an infrastructure
trigger function rather than a client API. It is not executable by
`PUBLIC`, `anon`, or `authenticated`; client roles also have no CREATE
privilege on the public schema. Its current `search_path=public` therefore
does not create a client-controlled object-shadowing path under the verified
production grants. Any future change that grants public-schema CREATE or direct
execution must reopen this review.

The `ensure_rls` event-trigger guard is part of the canonical migration and
recovery contract.

## Storage

The production business-document buckets are:

- `business-documents` — private;
- `driver-documents` — private.

Storage object policies enforce company-scoped paths and role checks. Trip and
Fleet document policies additionally validate the referenced tenant-owned
business entity. Driver-role document reads remain denied according to the
established server-side role matrix.

Issue #287 recovery verification exercised both buckets with isolated synthetic
objects, including authorized signed access, byte-equality recovery, delete
behavior, and cross-tenant denial. No private bucket was made public.

## Seed/default data

Company creation retains the server-side default seeding contracts for expense
types and company expense categories.

The focused security hardening verified default company expense-category
seeding at 11/11, and the final production catalog review confirmed the
corresponding company seed triggers remain attached and are not directly
client-executable.

No production business data is seeded from development.

## Tenant and role negative tests

Valid existing evidence covers the required negative boundaries:

- Company A cannot read or mutate Company B protected data;
- wrong-company server RPC calls are denied;
- Driver-role direct reads of protected operational, personnel, financial, and
  document data are denied;
- Viewer same-company read access remains available where intended while
  unauthorized mutation is denied;
- allowed roles retain their established same-company access.

The backup/recovery rehearsal subsequently reverified authenticated
cross-company isolation after restore. No later production change broadened
these boundaries, so redundant negative-test repetition was not required for
this closure audit.

## Audit integrity

Issue #282 moved audit trust to server-authoritative writers and removed the
client audit-write path.

The verified production contract includes:

- company-scoped audit rows;
- authenticated direct audit forgery denied;
- no authenticated direct audit INSERT/UPDATE/DELETE path;
- legitimate protected mutations produce structured server-side audit events;
- cross-tenant audit reads remain denied.

Issue #287 reverified audit anti-forgery after isolated recovery.

## Auth and client security

Production client builds accept only the documented client-safe Supabase
configuration and reject modern secret keys and legacy service-role JWTs.

Runtime `.env` loading and bundled environment files were removed. Release
artifact checks cover Android AAB and Windows release/MSIX output for forbidden
secret markers.

The final Production Supabase Security Advisor review does not report the
`Leaked Password Protection Disabled` warning that remains present on the
development project. Production Auth therefore does not inherit that known DEV
warning at this audit point.

Issue #287 also verified the current non-empty email/password Auth recovery path.
MFA, SSO, WebAuthn, OAuth, or SCIM require separate recovery/security review if
enabled later.

## Backup and recovery

Issue #287 and PR #290 establish the canonical backup/recovery runbook and
evidence.

Verified launch evidence includes:

- encrypted off-site production recovery copy;
- real production logical backup with integrity evidence;
- isolated database restore;
- 35/35 public tables restored with RLS enabled;
- tenant isolation and audit anti-forgery after recovery;
- private Storage recovery for both business-document buckets;
- non-empty email/password Auth recovery;
- populated circular/self-reference document recovery;
- canonical migration-history reconciliation;
- RPO evidence approximately 2 hours 40 minutes against a 24-hour target;
- measured RTO 13.79 minutes against a 4-hour target.

This audit does not repeat that rehearsal. Backup creation, retention, integrity
checks, and periodic restore rehearsals remain recurring production operations.

## Accepted Security Advisor findings

At audit closure the remaining database findings are reviewed rather than
silently ignored:

- RLS enabled/no-policy informational entries for
  `invoice_sequences`, `trip_sequences`, and retired `trip_expenses`;
- authenticated `SECURITY DEFINER` warnings for intentional application RPC
  boundaries.

A future change must reopen the relevant review if it:

- grants client access to an internal/retired table;
- adds or broadens a privileged RPC;
- changes an RPC authorization/tenant contract;
- grants CREATE on the public schema to client roles;
- makes a business Storage bucket public;
- weakens Storage company/role policies;
- adds a new Auth provider or privileged client credential;
- changes audit writers or grants;
- changes the production backup/recovery contract.

## Evidence map

Primary evidence is distributed across the focused changes that established the
current production baseline:

- Issue #197 / production database bootstrap and audit investigation;
- PR #263 / Issue #243 Supabase Security Advisor hardening;
- PR #264 / PC-17 server-side role read alignment;
- PR #278 / Issue #194 production environment and client-secret hardening;
- PR #280 / production database bootstrap-history restoration;
- Issue #282 / audit anti-forgery and server-authoritative audit writing;
- production migration
  `20260925174900_issue_243_revoke_anon_public_access.sql`;
- Issue #287 / PR #290 production backup and recovery readiness;
- `PRODUCTION_DATABASE_BOOTSTRAP.md`;
- `ENVIRONMENT_CONFIGURATION.md`;
- `PRODUCTION_BACKUP_RECOVERY.md`.

## Closure rule

This document records the verified baseline at the audit date. It does not make
security a one-time activity.

Issue #197 may close when this audit record is merged and its focused repository
quality gate passes. Any later schema, RLS, grant, RPC, Storage, Auth, audit, or
recovery change must satisfy its own security verification and must not rely on
this historical snapshot as proof of the changed state.
