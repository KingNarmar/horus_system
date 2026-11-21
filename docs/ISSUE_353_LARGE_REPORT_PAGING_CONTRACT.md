# Issue #353 — Large reports: bounded source paging contract

Status (2026-11-21): **Development migrations applied and merged in PR #392.**
The existing Reports screen continues to use the four canonical source RPCs.
Draft PR #389 now wires paged snapshots into **Development PDF export only**,
using the existing Domain use cases. Staging/Production do not call the new
RPCs until their separate migration and release approvals. The new DI code
still needs CI and hosted end-to-end verification before PDF PR A sign-off.

## Existing authoritative sources

The nine report presentations use four sources:

1. Operational trips (six dimensions): one ordered trips stream.
2. Trip expenses: one ordered trip-expense stream.
3. Trip net profit: **trips and ledger-expenses** streams.
4. Open invoices: **invoices and payments** streams.

Each source carries company, period, timezone, source-read time and (where
financial) currency and validation counters. Preserve existing Domain
aggregation, money precision, financial status logic and server-side RBAC.

## Why LIMIT/OFFSET alone is insufficient

Each PostgREST HTTP request runs in its own transaction. A later page cannot
assume the snapshot of the previous request: changed data can shift offset
positions, change relationship membership or alter financial totals. A client
timestamp is not a PostgreSQL MVCC snapshot and cannot restore modified rows.
Never claim cross-request snapshot integrity from `statement_timestamp()`.

## Backend design verified before wiring

Use a **server-frozen, expiring export snapshot** under a non-exposed private
schema, with one complete, consistent set of metadata and materialized,
ordered per-stream rows. Snapshot initialization must use a consistent DB read
of the same source data and validation counters, **without** calling the old
unbounded JSON RPC once per requested page. For linked financial streams,
trip/expense and invoice/payment membership must originate from the same
source snapshot.

Backend contract (names intentionally provisional pending schema review):

- `start_report_export_snapshot`: input company, source kind and inclusive
  date bounds; authorize `auth.uid()`, active company membership, role and
  company state **in the database**; return opaque snapshot ID, source metadata,
  validation counters and per-stream total row counts.
- `read_report_export_snapshot_page`: input opaque snapshot ID, stream
  identifier, cursor and bounded page size; authorize **every call** against
  the active user/company/role, validate snapshot expiry and cursor binding;
  return strictly ordered, bounded rows, total count, snapshot token and
  optional next cursor. Do not expose underlying snapshot tables through the
  Data API.
- `release_report_export_snapshot`: best-effort owner-authorized cleanup;
  independently expire and purge orphaned snapshots. Never rely solely on
  client cleanup for retention/security.

For any SECURITY DEFINER function, revoke default PUBLIC execution grants,
use a constrained `search_path`, protect against spoofed company/role/cursors,
and test nonmember/deactivated/anonymous/unauthorized financial access. Apply
RLS and explicit table grants as defense in depth. Keep a separate per-user/
company/concurrent-export storage budget and safe expiration policy.

Use deterministic ordering with unique IDs; opaque keyset cursors are bound to
snapshot, stream and tenant. Do **not** implement offset paging over mutable
base tables. If snapshots are expired, mixed, incomplete, unexpectedly changed,
or over a documented resource budget, return a typed failure and never a
successful truncated report.

## Pure-Domain integrity groundwork included in this branch

`ReportSourcePageCollector` operates only on `ReportSourcePage<T>` and
`Result<T>`. It requires a frozen snapshot token, consistent total row count,
nonempty unique record IDs, cursor progress, and an exact final row count.
It observes cooperative cancellation and emits **real received/expected rows**
only when the server contract can prove them.

The collector is used by `PagedReportsRepositoryImpl`, which implements
the existing pure-Domain `ReportsRepository` interface. The request-scoped
export factory is wired only for Development; the screen stays on the
existing repository. No fallback to a different source occurs after a
snapshot failure.

`ReportExportProgress` exposes source / branding / render / delivery stages.
While the source is unpaged, UI must show **indeterminate** source progress,
not an invented percentage. Cancel discards pending results and prevents later
export stages; it cannot abort an already running HTTP request, PDF render or
native print/save/share dialog. Do not call this transport cancellation.

## Implementation gates

1. Read-only schema/functions/RLS/grants/volume verification on Development,
   in **one SQL block at a time**.
2. Draft focused migration for private snapshots/RPCs, then disposable local
   migration replay + signed-JWT cross-tenant/role/expiry/cleanup/concurrency
   tests. **Do not apply to hosted Development without separate owner approval.**
3. Add typed Data source/mappers/repository bridge for paged streams and proper
   snapshot release in `try/finally`; Domain computes original reports from
   verified streams. Keep the existing screen read path until deployment.
4. Wire real per-page progress; test cancellation, zero rows, 1,300+ records,
   10K+ records, duplicate/missing/changed pages, independent totals, and
   exact report parity for all nine presentation modes.
5. Verify bounded server response size, PDF memory use, no silent truncation,
   and desktop/mobile offline/platform behaviors. Larger loads belong also to
   the separate #391 release-gate stress plan.

**No production action or PR merge is authorized by this document.**

References:
- [Issue #353](https://github.com/KingNarmar/horus_system/issues/353)
- [PR #389](https://github.com/KingNarmar/horus_system/pull/389)
- [PostgREST transactions](https://docs.postgrest.org/en/stable/references/transactions.html)
- [PostgreSQL repeatable-read MVCC](https://www.postgresql.org/docs/current/transaction-iso.html)

## Versioned server implementation (Development deployed; Production pending)

Migration: `20261121070000_issue_353_report_export_snapshot_paging.sql`.

- Two company-scoped **private** tables with RLS and no client table grants.
- Three authenticated public RPCs: start/read/release, each checking the actor;
  start/read independently enforce live active-membership and report-role
  policies. SECURITY DEFINER uses a fixed `pg_catalog` search path and no
  anonymous execute grants.
- Start materializes the existing trusted report RPC result **once inside
  Postgres**. All related financial streams and validation counters originate
  from that single source read. Follow-up read RPC calls return up to **200**
  rows per bounded page from frozen private rows, with random opaque row cursors
  scoped to the snapshot and stream. A cross-user cursor is rejected.
- Resources: at most three active snapshots per user, at most 50,000 rows and
  64 MiB of UTF-8 JSON text per snapshot (measured with `octet_length`,
  not compression-dependent `pg_column_size`). Exceeding these bounds
  must be an **explicit capacity error**, never silent truncation. Fifteen
  minute expiry, release RPC, and five-minute database-only pg_cron cleanup.
- **Capacity caveat / performance acceptance gate:** The start operation
  currently uses the existing `jsonb_agg` source RPC once in PostgreSQL. This
  removes unbounded HTTP response payloads, but snapshot creation still needs
  enough server memory to calculate the full source before persisting the
  bounded rows. This is a known limitation to measure in #391 and in the
  required 10K+ isolated test before calling large-report acceptance complete.
  Further optimized direct `INSERT ... SELECT` snapshot materialization
  must preserve original validation/business results and one coherent source
  read, not weaken financial parity for a premature speed claim.
- The Development-only export bridge was enabled in the DI code after the
  authorized 2026-11-21 Development rollout; the changes remain in Draft
  PR #389 until CI and target-device smoke pass. Staging/Production retain
  the existing legacy export source by explicit environment selection.
  A failed snapshot operation has no silent retry/fallback to legacy.

This design does not introduce duplicate financial formulas, client-side
aggregation, or a permissive fallback that could export stale/partial data.

## Independent 12K stress gate (isolated local CI)

`issue-353-snapshot-12k-stress.yml` runs only in an unlinked, disposable
Supabase stack. It extends the **existing 1,300-row fixture** to **12,000
records per source** while preserving the original subscription/quota triggers,
then checks all four frozen authoritative sources and their paired financial
streams through real signed-JWT pages. Assertions include exact independent
amount totals, stable/unique row IDs, no silent truncation, ≤200 rows/page,
≤1 MiB serialized response/page, and release without leaked snapshots.

It additionally verifies that updating a live trip does not mutate the frozen
snapshot; downgrading a user's finance role revokes subsequent snapshot page
access; and a fourth active snapshot correctly fails with the capacity code.
The job records server payload size, maximum page response bytes, initialization
time and total elapsed time for each source. These are **local CI diagnostic
metrics**, not production latency guarantees or peak PostgreSQL memory
measurements. The dedicated [run #44879958642](https://github.com/KingNarmar/horus_system/actions/runs/44879958642)
**PASSED** (12,000 rows per stream in all four report sources): snapshot
initialization 505–849 ms; 60 pages for single streams, 120 for paired streams;
maximum page response 114,154 bytes; source sizes 6.74–8.12 MB.
The 12K seed took ~275 seconds; its read-only health probe safely reconnected
after one stale idle HTTP socket. No start/release mutation was auto-retried.
Peak PostgreSQL memory and hosted concurrency remain unmeasured.

The independent stress fixture is **not** a migration and must never be
executed on hosted Development or Production. The Development client export Data adapter is now selected by dependency
injection, pending CI and hosted Windows/Android end-to-end verification.
No Production rollout or app merge has been authorized.

Size accounting reference: [PostgreSQL database size functions](https://www.postgresql.org/docs/18/functions-admin.html) and [string `octet_length`](https://www.postgresql.org/docs/18/functions-string.html).

## Development rollout evidence (2026-11-21)

- Original migration versions `20261120144500` and `20261121070000`
  applied to Development in order and merged into `main` via PR #392.
- Hosted read-only follow-up on 2026-11-21 confirmed both history versions
  and all three snapshot RPCs. Prior recorded transaction-scoped hosted
  role/tenant and snapshot cleanup smoke passed.
- PR #389 rebased its merge ancestry safely onto `main` without rewriting
  history or introducing duplicate migrations.
- Remaining: CI for Development-only DI wiring, nine-mode screen-to-PDF
  parity, focused Windows/Android smoke and #391 concurrency/memory gate.

[Development DB rollout record](ISSUE_353_DB_DEVELOPMENT_ROLLOUT.md).
