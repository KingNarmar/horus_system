# Issue #358 — Development-only first operator provisioning

**Scope:** explicitly approved operator bootstrap for H.O.R.U.S **Development only**
(project `zwnfmszssxtfxkaofnhq`, `horus-system-dev`). This is an
**operational data migration**, not a new tenant role or a Flutter feature.
Production project `rkhmfbxlduuovlbsxhgy` is explicitly excluded.

**Approved:** 2026-11-15 by the platform owner in the project conversation.
**Operator identity:** validated against the Development-only
`auth.users` ID/email tuple via a deterministic identity fingerprint.
No email, auth UID, password, TOTP secret or service-role key is embedded
in the SQL file.

## Source-of-truth and placement

- SQL artifact: `supabase/development_only_migrations/20261115_issue_358_dev_operator_bootstrap.sql`
- Managed operation name: `issue_358_dev_only_operator_bootstrap_20261115`
- The SQL is intentionally outside **`supabase/migrations/`**: never copy it
  into the shared automatic migration chain, CI replay or Production deploy.
- Execute only via an operator-authenticated managed Supabase **migration**
  action with `project_id=zwnfmszssxtfxkaofnhq` explicitly selected.
  Never via the client Flutter SDK, anonymous/authenticated REST DML,
  an ad hoc SQL Editor write, or a generic `db push`.
- The managed Development migration history records this one-off operation.
  This Dev-only record intentionally differs from the shared cross-environment
  history. **Before future Dev migration pushes, compare remote/local history
  and reconcile the Dev-only version against the archived SQL artifact.**
  Never rewrite, remove or fake historical versions solely to bypass drift.
- Before executing, verify the account exists, email confirmed, is active,
  is not anonymous, has the expected existing 2 company memberships
  (1 active), is not already an operator and has its protected profile flag off.
  The SQL independently enforces every one of these conditions and fails closed.

## Exact changes and unchanged data

**Only two mutations**, performed atomically by trusted PostgreSQL owner:

1. `public.user_profiles.is_platform_admin` becomes `true` for the
   verified approved account.
2. Insert the least-privilege private `platform_operator_access` registry
   row with scopes:
   `tenant_read`, `usage_read`, `override_read`,
   `override_write`, `creation_grant_write`, `audit_read`,
   `membership_recovery`.

**Excluded:** `operator_manage`, any implicit company-wide RLS bypass,
tenant role changes, membership changes, customer data, quota overrides,
subscription changes and all Production writes.

The existing `platform_operator_access_audit` trigger records an
append-only `operator_access_created` event with actor/reason/permissions.
Trusted database-owner execution has **no signed end-user session**;
`actor_user_id` remains `NULL` intentionally. Never forge an
authenticated session just to attribute a database-owner action.

## Mandatory security gate

Provisioning **does not grant working operator access without real Supabase
Authenticator (TOTP) MFA**. #358 validates a signed GoTrue JWT, active session,
stored factor, AAL2 and recent same-session TOTP challenge for sensitive
writes. An operator with AAL1 still gets denied. Enrollment and verification
must happen through a real account-owned Supabase Auth session, not by
writing factor rows or inventing a token in SQL.

First hosted Development smoke gate: enroll/verify MFA with approved account,
obtain AAL2, read one minimal operator RPC, confirm a normal company user is
denied, then confirm tenant boundaries. Avoid unnecessary write probes.
Do not mark #358 fully operational until this passes.

## Verification and recovery

After the migration, run one focused **read-only** verification:
profile flag ON, exact 7 active scopes, `operator_manage` absent,
new immutable audit event present and existing company-membership counts
unchanged. Confirm no other operator was provisioned. Do not repeat already
green schema/RLS/GRANT/CI tests.

For revocation, use a separately approved, versioned Development-only
migration that sets `revoked_at` and disables the protected profile flag
within one transaction, preserving the audit and membership history.
Never delete the append-only audit trail.

**No Production migration/rollout or `main` merge is authorized by this
Development-only provisioning approval.**
