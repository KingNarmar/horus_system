# Issue #358 — Secure Platform Operator Backend

**Status:** Draft source PR #383 for review; **NOT MERGED / NOT DEPLOYED**.
**Parent:** #191 · **Backend:** #358 · **Console:** #359 · **Release gate:** #202.
**Source branch:** `feature/358-platform-operator-backend`.

## Authorization boundary

The operator is an explicitly trusted platform actor, **not** a company
Owner/Admin and not a client-side JWT role or Company membership.

Protected operations must pass all checks **on each server request**:

1. Valid Supabase signed JWT, `authenticated` role, `auth.uid()`, subject,
   expiry and UUID `session_id`.
2. Live, matching `auth.sessions` row; not past `not_after`.
3. Account not deleted, banned or anonymous.
4. `public.user_profiles.is_platform_admin = true` (existing protected flag).
5. Independent `private.platform_operator_access` permission record,
   not revoked and containing the operation's permission.
6. JWT and stored session AAL2, verified MFA factor owned by the actor.
7. Sensitive writes and membership recovery additionally require a
   **factor challenge within the last 15 minutes**, backed by a recent
   `totp` entry in the *same signed JWT's* `amr` methods array. A challenge
   on another device/session cannot refresh this JWT's step-up privilege.

Failure is closed. A valid **stolen but still-active** AAL2 JWT within the
MFA challenge window is not mathematically impossible to abuse; protect
client storage, log out promptly, revoke server records after incident,
rotate account credentials and consider step-up/second approval for
higher-risk future releases. Token refresh by itself does not renew the
challenge window.

Operator scopes: `tenant_read`, `usage_read`, `override_read`,
`override_write`, `creation_grant_write`, `audit_read`,
`membership_recovery`, `operator_manage`. These are server-side permission
values, never Company role names.

### Controlled provisioning and revocation

The first Platform Operator must be approved and provisioned in a separately
authorized, **versioned** trusted SQL migration after checking the account.
This source does **not** auto-grant any production user or seed a default
operator. Both the existing profile flag and the private access record are
required. Never insert privilege rows from Flutter, PostgREST, a public
management page, or anonymous API credentials.

`private.platform_operator_access` is inaccessible via direct client DML.
Trusted DB-owner updates are logged by a platform-audit trigger; revocation
is immediate for the next protected RPC. Changing permissions is also logged.
`operator_manage` is reserved for a later separately reviewed lifecycle
operation; it is **not** a generic SQL editor.

**Upgrade dependency:** Existing #370 trusted membership recovery now
requires a provisioned AAL2 operator with `membership_recovery`.
Ordinary company member management RPCs are unchanged. This behavior must
be included in a coordinated Development QA/cutover before any rollout.

## No unrestricted tenant reads

Prior `is_platform_admin()` shortcuts in nine tenant-table RLS policies
were replaced with ordinary company-role/member conditions. In particular,
operator-only credentials no longer grant unrestricted direct SELECT of
`companies`, `company_users`, `user_profiles`, audit or subscriptions.

The new `platform_list_tenants` API is a page of only:
company ID/name/status, plan code, subscription revision and created-at.
Search length <=80, page size 1..100, UUID keyset pagination.
Override history and platform audit use **descending event timestamp + UUID**
keyset ordering, so pages reflect newest events first instead of random UUID
order. Cursors are resolved only inside the requested company scope; unknown
or foreign-company cursors fail closed.
`platform_get_company_usage` reveals only canonical entitlement and
aggregate counts. No emails, private Storage bytes or financial business rows.

For #370 recovery, `platform_get_membership_for_recovery` fetches a
**single known company/membership pair** behind recent MFA instead of
unrestricted membership-table reads.

## Canonical quotas

The **existing** `private.resolve_company_effective_entitlement` remains
the sole effective source. The private, versioned override ledger composes
resource capacities and additive enabled features into its returned JSON.
All existing capacity guards (#32/#355/#356/#357) consume that resolver;
there are no parallel quota counters.

Supported resource keys (absolute limits): `company_users`,
`combined_vehicles`, `customers`, `drivers`, `routes`,
`lifetime_trips`, `lifetime_invoices`, `business_documents`.
An override cannot lower the immutable Free Starter baseline. The
`unlimited` value is supported by the existing quota guard, but should be
used only with a documented reason and operator permission.

Feature keys: `driver_app`, `advanced_reports`, `maintenance`,
`whatsapp_notifications`. Grants only **enable** a feature. Existing
free features (branding, invoice PDF, report PDF/XLSX, document upload)
are never removed or recharged. Features without a current server gate
remain declarations until their corresponding feature implementation
adds a protected gate: this change does not invent such functionality.

**Time:** Grant intervals are half-open `[effective_at, expires_at)`.
One company/scope cannot have overlapping non-revoked intervals.
The resolver evaluates current DB time per read/write and returns
`next_override_change_at` for read consumers to refresh time-bound
entitlements. Expired grants require no destructive job. Previously
created companies, trips, invoices and documents remain intact.

**Concurrency:** Company lock is acquired before subscription/override
row locks, matching existing quota writers. Each grant/revoke requires
subscription `expected_revision`, an idempotency `request_id` and
fingerprint, actor and reason. Exact retries return the same result.
Conflicting payloads and stale revisions are rejected with stable SQLSTATE
codes. Privileged mutations and audit write are one DB transaction.
A Platform Operator who is an active member of a target company cannot
grant/revoke that company's limits.

### Separate owner-created-company exception

The one-company rule belongs to original creator `user_id`, **not**
`company_id`. `private.platform_company_creation_capacity` holds one
versioned absolute extra-slot allowance per creator. Mutations lock the
same per-creator advisory lock as #354 onboarding before reading the
history. `create_company_with_initial_owner` keeps the existing client
signature and immutable `company_creation_ledger` but adds **active**
operator-approved extra slots to the Free Starter base.

Extra slots can expire or be revoked; historical creation never resets.
No operator may grant their **own** creator ID additional slots.

## Public RPCs

| RPC | Operator scope | Purpose |
| --- | --- | --- |
| `platform_list_tenants` | `tenant_read` | Paginated minimal tenant directory |
| `platform_get_company_usage` | `usage_read` | Effective entitlement + 8 used counters |
| `platform_get_membership_for_recovery` | `membership_recovery` + recent MFA | One recovery target |
| `platform_grant_entitlement_override` | `override_write` + recent MFA | Atomic scoped grant |
| `platform_revoke_entitlement_override` | `override_write` + recent MFA | Atomic scoped revoke |
| `platform_list_entitlement_overrides` | `override_read` | Paginated override state |
| `platform_list_operator_audit` | `audit_read` | Protected platform audit history |
| `platform_set_company_creation_capacity` | `creation_grant_write` + recent MFA | Per-creator exception / revoke |

All public RPCs grant EXECUTE to `authenticated` only, then enforce
**independent** in-function authorization. Direct DML/SELECT on new
private tables is revoked for `PUBLIC`, `anon`, `authenticated`.

Typed API error mapping and EN/AR/RTL operator views are #359 (Flutter
Domain/Data/Presentation), **not** undocumented client snippets in #358.

## Migration ordering and rollout

1. `20261115010000`: operator security, immutable platform audit,
   session/MFA gate, minimal read APIs and narrower tenant RLS.
2. `20261115011000`: canonical entitlement overrides, protected
   grant/revoke mutations and temporal indexes.
3. `20261115011500`: read-only, chronological keyset projections for
   override history and protected audit history.
4. `20261115012000`: separate, per-original-creator capacity exception,
   and the existing owner onboarding RPC extension.
5. Review complete disposable migration replay and real signed-JWT evidence.
6. Separately approve *Development* migration application and provision
   an approved operator via separately reviewed DB-owner migration.
7. Test operator MFA, #370 recovery, user/tenant negative reads and quotas
   on Development. **No Production modification** under this approval.
8. Any later Production deployment needs #362 compatibility, backups,
   rollout/rollback approval and #202 security release gates.

All migrations are additive or replace explicitly reviewed functions/
policies; previously applied migrations are never edited. The new
`is_platform_admin()` becomes stricter and intentionally needs a
coordinated operator provisioning step. Database revert must use
**new reviewed corrective migration(s)**, not a live-only edit or
destructive removal of evidence. Keep the append-only platform audit
and historical grant records when limiting/revoking functionality.

## Security verification matrix

Must pass before acceptance:

- Real local GoTrue signed-JWT AAL2 operator, AAL1 denial, ordinary tenant
  owner/admin/viewer, anonymous and cross-tenant direct API denial.
- Server-side operator revocation while JWT remains valid; session
  revocation/expiry and recent MFA assurance limits.
- Minimal directory and usage payloads, independent operator scopes,
  no direct tenant-business or private-table disclosure.
- Exact and conflicting idempotent retries, concurrent distinct grants,
  optimistic revision, interval overlap, timed expiry and revoke.
- All 8 quota resources including #357 business documents, plus feature
  enabled state; historical/financial reads must remain authorized.
- Owner-created-company exception before/after expiry and removal,
  preserving creation ledger and audit trace.
- #370 recovery remains auditable with exactly one event; owner/admin
  normal membership management remains unchanged.
- Append-only platform audit, actor/reason/old/new, RLS/grants and schema
  advisors; full migration replay, Flutter quality gate and explicit
  Windows/Android/iOS regression only if the app contract changes.

**Current status:** Source exists on its feature branch. These are
acceptance requirements, **not claims that tests passed**.
