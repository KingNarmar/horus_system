# Issue #317 R4.4 — Financial Integrity and Release Gates

**Status:** NO-GO for PR Ready/Merge and Production deployment until remaining
checks below pass and the operator explicitly approves each release step.

**Scope:** Driver Settlement Realtime + server-authoritative financial creation.
This document is a test/release protocol, not approval to modify Production.

## Verified Development evidence — 2026-10-24

- Windows/Android cross-device Draft create, Finalize, Void and offline
  reconciliation succeeded. No client-refresh workaround was needed.
- Signed-JWT negative role matrix: 13/13 PASS; client INSERT to settlement
  header and items denied; forged private Broadcast explicitly denied.
- Two different signed company users raced identical atomic Draft creation:
  same ID, one row, one create audit. Finalize versus Void yielded one terminal
  Voided settlement with one audit each for create/finalize/void (3/3 PASS).
- The race row was independently read from Development; salary gross/net
  AED 1,000, zero opening/closing balance, zero items, Voided status.
- Actions CI #40085114082 on `5105db7b`: Quality Gate, invitation edge,
  Android and Windows builds all PASS.
- **None of these is a source-backed expense-versus-finalize race.**
  Earlier SQL `ROLLBACK` simulations are not separate signed-JWT sessions.

## Source-backed expense-void versus settlement-finalize gate

1. Use the existing #337 rules and lock-order migrations as the server
   foundation. Do **not** use
   `supabase/tests/issue_337_signed_jwt_fixture_setup_dev.sql` unchanged:
   it directly INSERTs settlement headers/items, omits the now-required
   compensation and exact-money fields, and creates draft/finalize snapshots
   incompatible with the R4.4 hardened contract. It predates R4.4.
2. Prepare **one isolated Development-only** driver-funded Trip Expense with
   known company/driver/trip, approved currency and an identifiable unique
   marker, and a server-validated Draft capturing exactly that source.
   Prefer using the app's canonical Preview and Draft RPC. Record its
   expense/settlement/driver IDs and marker privately; never record secrets.
3. Run the independent, read-only signed-session preflight in
   `scripts/security/verify_issue_317_r44_source_void_finalize.dart`.
   It requires **two different users** (Owner and Admin in Company A);
   the older #337 Python runner uses a **single JWT** in two threads and
   therefore does not satisfy the two-principal acceptance gate.
4. Run the explicitly confirmed Development race once. The result must be
   exactly one successful mutation: if Void wins, the draft must not finalize;
   if Finalize wins, expense void must be rejected. Ledger, settlement and
   company-scoped audit must agree with the winner. Deadlocks, timeouts,
   duplicated audit and financial drift are **FAIL**, not allowable outcomes.
5. If Void wins, the now-stale Draft may need an explicitly approved
   Development-only Void. If Finalize wins, the expense must remain intact.
   A fixture is consumed after this test: do not blindly retry.
6. Verify final DB state with one read-only SQL verification block at a time
   and the operator's reported result before declaring the gate closed.

No Production data, credentials, secret keys or live-only fixes are permitted.

## Binary/database compatibility — confirmed breaking change

`main` as reviewed on 2026-10-24, in
`lib/features/driver_settlements/data/datasources/driver_settlements_remote_data_source.dart`,
uses a **split direct INSERT** into `driver_settlements`, followed by
`driver_settlement_items`. R4.4 changes these writes to the atomic
`create_driver_settlement_draft_atomic` RPC and revokes the client INSERT
grants on both tables.

**Deploying the final R4.4 database restrictions before client adoption
will break Draft creation on older Windows and Android binaries.**
Conversely, a new RPC-only binary will not create Drafts if the RPC is absent.
The current tested binaries do not themselves establish a safe mixed-version
Production rollout. Existing closed financial records must remain immutable.

### Safe release decision required (not implemented)

- First verify exact Production migration inventory, installed-client version
  distribution and store update/rollout mechanics, **read-only**, with separate
  operator approval. Never infer adoption from a successful store submission.
- Decide and document how older clients will be prevented from unsafe
  financial writes and will obtain a clear localized EN/AR update path.
  Server-side authorization is mandatory: a frontend version check alone
  cannot enforce the financial boundary.
- A gradual compatibility window allowing old split-writes retains the old
  financial integrity hazard; **do not silently regrant INSERT** merely to
  avoid a visible incompatibility.
- A coordinated maintenance/cutover window may deliberately block older
  settlement writers, but that is a user-visible breaking change and requires
  product approval, advance communication, rollback/recovery decisions and
  tests of the **actual** old and new signed Windows/Android artifacts.
- Alternatively design an explicitly approved server-side compatibility
  protocol that is provably tenant-isolated, atomic and audit-safe; do not
  accept split writes, trigger-disabled operation or a privilege bypass.
- Verify rollback feasibility before applying irreversible/schema changes:
  reverting just the Flutter binary after database hardening can strand
  older clients. Restoring removed INSERT grants is **not** a safe rollback.
- Execute Production backup/restore readiness, version-preserving migrations,
  RLS/grants/audit verification and acceptance checks **only after explicit
  Production approval**. Then confirm reconnect/Realtime and incident
  rollback drills using real signed deployed artifacts.

**Release disposition:** This project remains NO-GO until source-backed
concurrency and a reviewed legacy-client rollout protocol have passed and
been explicitly approved. Do not label PR #339 Ready merely because CI passed.
