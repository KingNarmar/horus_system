# Issue #354 — Free Starter entitlement contract and recovery

Parent: [#191](https://github.com/KingNarmar/horus_system/issues/191)  
Frozen business policy: [#207](https://github.com/KingNarmar/horus_system/issues/207)  
PR: [#375](https://github.com/KingNarmar/horus_system/pull/375)  
Account deletion lifecycle: [#196](https://github.com/KingNarmar/horus_system/issues/196)  
Next dependency: [#32](https://github.com/KingNarmar/horus_system/issues/32)

## Scope and status

- Zero-price indefinite **Free Starter** is provisioned as part of the same
  PostgreSQL onboarding transaction that creates the company, first active
  Owner membership, invoice settings, creation allowance and structured audit.
- Development migration applied: `20261109130225_issue_354_free_starter_provisioning.sql`
  to `zwnfmszssxtfxkaofnhq`. This file is in the PR under the **same**
  migration version. **Production remains unchanged.**
- Current company entitlement is read through the protected
  `get_company_effective_entitlement(p_company_id)` RPC. Owner/Admin can
  view the full company entitlement; other roles do not gain permission via
  presentation alone. No service-role key is shipped in the client.
- Historic Basic/Pro/Enterprise rows are retained as data but must not be
  advertised as V1 sales plans. No payment processing in V1.
- This issue is **not** the resource quota enforcement implementation.
  Resource mutation checks belong to #32 and #355/#356/#357.

## Canonical read projection

`get_company_effective_entitlement(p_company_id)` returns one JSON object:

| Property | Contract |
| --- | --- |
| `company_id` | UUID of the company verified by backend authorization |
| `plan_code` | `free_starter` for the baseline V1 grant |
| `policy_version` | Positive integer referencing immutable stored plan policy |
| `revision` | Positive integer for the current company grant |
| `effective_at` | ISO timestamp |
| `expires_at` | Nullable; `null` for indefinite Free Starter |
| `status` | `active`, `suspended`, `expired` or `revoked` |
| `limits` | JSON object with **all** resource keys, no missing-as-unlimited |
| `enabled_features` | Explicit list; no implicit premium grants |

Frozen baseline resource limits:

| Key | Limit | Future enforcement owner |
| --- | ---: | --- |
| `owner_created_companies` | 1 | #354 |
| `company_users` | 3 | #32 |
| `customers` | 10 | #355 |
| `drivers` | 5 | #355 |
| `combined_vehicles` | 6 | #32 |
| `routes` | 10 | #355 |
| `lifetime_trips` | 30 | #356 |
| `lifetime_invoices` | 10 | #356 |
| `business_documents` | 50 | #357 |

Essential features explicitly enabled for Starter:
`company_branding`, `invoice_pdf`, `report_pdf`,
`report_xlsx`, and `document_upload`. These feature flags do not imply
the unfinished branded export features #351/#352/#353 already exist.

## Onboarding and retries

1. Server receives `p_request_id` (UUID), **derives actor from
   `auth.uid()`** and serializes concurrent creation attempts per actor.
   First success writes a permanent company creation ledger entry.
2. A repeat of the same UUID and same normalized payload returns the original
   company without another grant, ledger record or audit. Using the same UUID
   with a different payload receives typed `P2838`.
3. A different creation request after the normal allowance is exhausted
   receives typed `P2836`; invitations and other companies' memberships do
   not consume the actor's creation allowance.
4. The client persists the pending request UUID and a SHA-256 fingerprint
   of the request **in device secure storage**, scoped to the current user.
   It does **not** persist the input fields or credentials.
5. A transport failure, timeout, lost response or malformed response leaves
   the pending identity in place for a safe retry after restarting the app.
   Definite server-side business rejection and confirmed successful response
   release that pending identity.
6. If a previous uncertain request is retried with different form data,
   the original UUID stays in place; the server decides whether this is a
   conflicting replay. The client never silently treats unknown results as
   successful or creates an automatic replacement request.
7. If secure storage is unreadable or cannot persist safely, the client fails
   closed with a typed localized message, before sending an onboarding RPC.
8. **Limitation:** Only the request identity, not the original form inputs, is
   persisted. After restart, users may need to re-enter the original form to
   retry exactly, or use company switching to discover an already-created
   company. Automatic form restoration is not asserted. In-app restart
   recovery remains a manual acceptance check after deploying the latest build.

### App compatibility

The #354 migration replaces the old onboarding RPC signature with one that
requires `p_request_id`. An old app will fail to create companies against
the new backend. A future Production rollout **must** coordinate a compatible
app version/force-update gate under #362/#202 before enabling signup.
A successful Development smoke or a green CI run does not approve Production
deployment. Do not roll Production backward to a non-atomic creation RPC.

## Account deletion and creator history (#196)

The owner-approved #207 contract says leaving, deactivating, transferring
ownership or deleting an account must **not** automatically replenish the
same actor's creation allowance.

- `private.company_creation_ledger` preserves the original creator UUID
  and company UUID independently of active membership/current ownership.
  There is intentionally no foreign key that cascades deletion from
  `auth.users`. RLS is enabled; ordinary authenticated users and anonymous
  users have no direct read/write access. Ledger rows are append-only.
- The existing #196 finalizer removes the Auth account only when it would not
  leave a company without an active owner. It does **not** delete creator-ledger
  records, matching the no-replenishment rule for the original actor ID.
- The protected ledger also retains request UUID and SHA-256 fingerprint
  for real onboarding records. This is **pseudonymous operational metadata**;
  the fingerprint was derived from normalized onboarding fields that may
  include personal details. No raw email, phone number or credentials are
  stored in that ledger.
- **Privacy/release gate:** Confirm the necessary retention duration,
  user-facing privacy/account-deletion disclosure, access controls and
  minimization of this ledger (especially request fingerprints) within the
  account-deletion policy and #202 release review. No claim of general legal
  compliance or automatic erasure is made by #354 alone. Any change to the
  approved #196 deletion finalizer requires its own reviewed scope/migration
  and explicit authorization. Never silently delete company audit/history.
- Deletion followed by creation of a **new Auth identity** is a separate
  identity/account policy question; the ledger does not magically link new
  accounts to deleted actors. Do not claim it prevents that case.

## Verification and remaining gates

Development has verified: four historical companies non-destructively
backfilled, manual Windows first-company creation and Free Starter grant,
exactly one creator ledger row and four onboarding audit events; second
creation attempts in EN/AR denied with no additional company/grant/audit.
Windows Owner/Admin and Android mobile EN/AR RTL displays have passed manual
smoke. Source-only local JWT suites cover concurrency, tenant isolation and
RPC signature. Evidence is on [Issue #354](https://github.com/KingNarmar/horus_system/issues/354).

Before marking #354 complete:

- Verify the **latest** PR head's format/analyze/tests, signed-JWT suites,
  migration replay and Windows/Android release builds.
- Verify the secure-storage restart/replay state in unit tests and a focused
  manual failure-recovery scenario without a hosted production write.
- Review account-deletion metadata retention and disclosure as a release gate.
- Secure explicit owner approval **separately** for PR merge. No #32 work,
  Production migration or app/store release is approved by this document.
