# Issue #353 — Nine-report export acceptance matrix

Status (2026-11-21): **Acceptance tracking, not a release sign-off.** Draft
PR #389 implements PDF and a frozen snapshot Data path. Development database
migrations are already applied and merged in PR #392. The export-only
snapshot DI bridge is now implemented for Development, but CI and real
end-to-end verification are still pending. Screens continue using original
authoritative source readers. XLSX remains separate PR B.

This matrix ties **each of the nine approved report modes** to the actual
authoritative source and the evidence needed before Issue #353 can close.
All nine must preserve the exact selected company, user privileges and date
range, including server-side financial field restrictions.

| Report mode | Authoritative source | Domain output | Existing automated coverage | Still required |
| --- | --- | --- | --- | --- |
| Daily trips | Operational trips | Individual trips grouped by day; eight typed PDF columns | Date, trip row/count, status cell; report kind + permission policy | Screen vs PDF row IDs/count/filter parity on realistic data |
| Trips by customer | Operational trips | Counts grouped by customer | Focused five-kind Domain parity test | Compare every group and total to screen |
| Trips by route | Operational trips | Counts grouped by route | Focused five-kind Domain parity test | Compare route label, empty/unassigned, groups and totals |
| Trips by driver | Operational trips | Counts grouped by driver | Focused five-kind Domain parity test | Compare driver/unassigned groups and totals |
| Trips by tractor head | Operational trips | Counts grouped by tractor head | Focused five-kind Domain parity test | Compare plate/unassigned groups and totals |
| Trips by trailer | Operational trips | Counts grouped by trailer | Focused five-kind Domain parity test | Compare plate/unassigned groups and totals |
| Trip expenses | Trip-expenses RPC | Typed money in minor units and exact Domain total | Source mapper/projector and typed funding-source cells; signed-JWT financial RBAC | Screen vs export totals, negatives, precision validation and all rows |
| Trip net profit | Trips **plus** ledger expenses, one frozen snapshot | Freight, expenses, net profit without UI recomputation | Domain projector verifies original totals; paged Data pair test | Screen vs PDF per-trip and aggregate money parity, including all statuses |
| Open invoices | Invoices **plus** payments, one frozen snapshot | Issued invoices, payments and outstanding in typed money/date cells | Source/projector and paged Data pair tests; restricted roles | Screen vs PDF balances, currencies, filters and multiple-payment cases |

## Cross-cutting evidence already present

- The nine `ReportExportKind` values and role policy are covered by
  `test/features/reports/domain/report_export_kind_test.dart`.
- Domain-to-typed-export projection is tested by
  `test/features/reports/domain/report_export_projector_test.dart`, with
  `test/features/reports/domain/report_export_grouped_parity_test.dart`
  verifying grouped counts/labels across all five operational kinds.
- PDF rendering includes 100-row and 1,000-row pagination, long/wide layout,
  Cairo Arabic font embedding, mixed Arabic/English, and timezone failures:
  `test/features/reports/data/services/report_pdf_renderer_impl_test.dart`.
- Snapshot integrity (exact counts, stable token, unique IDs, cancellation)
  is tested by `report_source_page_collector_test.dart` and the Data
  repository tests; signed-JWT 1,300-row source tests passed in isolated CI.
- The [12K isolated stress run](https://github.com/KingNarmar/horus_system/actions/runs/44879958642)
  **PASSED** with all four sources (12,000 per stream), exact financial
  totals, bounded 200-row pages, frozen data under live writes, permission
  revocation, capacity limits and cleanup.

## Acceptance evidence by stage

| Stage | Current evidence | Status |
| --- | --- | --- |
| Verified done | Windows/Android pre-paging PDF smoke, Cairo/RTL renderer, Domain grouping/financial projection tests, disposable signed-JWT/12K tests, Development DB migration/RLS/role smoke | Verified for those earlier versions and scopes |
| Partially verified | Frozen paged repository and Development-only DI bridge exist; prior source tests prove semantics, but the new wiring needs CI and hosted client smoke | Partially verified |
| Missing tests | Screen vs PDF per-row/group/amount parity for all nine modes, long/empty/EN/AR cases after bridge enablement, updated Windows/Android cancel/progress/revocation smoke | Pending |
| Release-only | Hosted scale/concurrency/peak memory #391, iOS signing/platform smoke, Production schema rollout and final RC #202 | Not authorized / pending |

## Gates not yet satisfied

1. Record per-mode, per-filter **screen vs PDF** row/group/total parity for
   all nine modes, with empty and long-field cases and both EN/AR layouts.
2. The 12K isolated test **passed**; PostgreSQL peak memory and concurrent
   hosted-load/latency remain unverified. The current start RPC materializes
   the authoritative JSON before the capacity check. Track this as an
   outstanding #391 release stress gate even though *pages* are bounded.
3. The authorized Development migration ordering/deployment is **completed**
   and the export-only DI bridge has been committed. Verify CI and Development
   app smoke. Staging/Production must not call the new RPCs prior to their
   own approved release rollout; do not silently fall back if paging fails.
4. Run desktop/Android end-to-end tests again after the backend bridge is
   activated. iOS smoke remains at release gating. Export cancellation cannot
   interrupt native print/share dialogs and must be described accordingly.
5. Native XLSX (typed numbers/dates, injection prevention) remains separate
   PR B; it is not complete merely because PDF/export groundwork passes.

Related: [Issue #353](https://github.com/KingNarmar/horus_system/issues/353),
[Draft PR #389](https://github.com/KingNarmar/horus_system/pull/389), and
[Large Report Paging Contract](ISSUE_353_LARGE_REPORT_PAGING_CONTRACT.md).
