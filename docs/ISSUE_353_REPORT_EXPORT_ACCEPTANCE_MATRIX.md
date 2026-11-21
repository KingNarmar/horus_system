# Issue #353 — Nine-report export acceptance matrix

Status: **Acceptance tracking, not a release sign-off.** The current Draft PR
implements PDF and a draft frozen snapshot data path. XLSX remains planned for
the separate PR B. Database snapshots are not enabled in app DI until an
independently approved Development migration deployment.

This matrix ties **each of the nine approved report modes** to the actual
authoritative source and the evidence needed before Issue #353 can close.
All nine must preserve the exact selected company, user privileges and date
range, including server-side financial field restrictions.

| Report mode | Authoritative source | Domain output | Existing automated coverage | Still required |
| --- | --- | --- | --- | --- |
| Daily trips | Operational trips | Individual trips grouped by day; eight typed PDF columns | Date, trip row/count, status cell; report kind + permission policy | Screen vs PDF row IDs/count/filter parity on realistic data |
| Trips by customer | Operational trips | Counts grouped by customer | Grouped projection (shared five-dimension test) | Compare every group and total to screen |
| Trips by route | Operational trips | Counts grouped by route | Grouped projection (shared five-dimension test) | Compare route label, empty/unassigned, groups and totals |
| Trips by driver | Operational trips | Counts grouped by driver | Grouped projection (shared five-dimension test) | Compare driver/unassigned groups and totals |
| Trips by tractor head | Operational trips | Counts grouped by tractor head | Grouped projection (shared five-dimension test) | Compare plate/unassigned groups and totals |
| Trips by trailer | Operational trips | Counts grouped by trailer | Grouped projection (shared five-dimension test) | Compare plate/unassigned groups and totals |
| Trip expenses | Trip-expenses RPC | Typed money in minor units and exact Domain total | Source mapper/projector and typed funding-source cells; signed-JWT financial RBAC | Screen vs export totals, negatives, precision validation and all rows |
| Trip net profit | Trips **plus** ledger expenses, one frozen snapshot | Freight, expenses, net profit without UI recomputation | Domain projector verifies original totals; paged Data pair test | Screen vs PDF per-trip and aggregate money parity, including all statuses |
| Open invoices | Invoices **plus** payments, one frozen snapshot | Issued invoices, payments and outstanding in typed money/date cells | Source/projector and paged Data pair tests; restricted roles | Screen vs PDF balances, currencies, filters and multiple-payment cases |

## Cross-cutting evidence already present

- The nine `ReportExportKind` values and role policy are covered by
  `test/features/reports/domain/report_export_kind_test.dart`.
- Domain-to-typed-export projection is tested by
  `test/features/reports/domain/report_export_projector_test.dart`.
- PDF rendering includes 100-row and 1,000-row pagination, long/wide layout,
  Cairo Arabic font embedding, mixed Arabic/English, and timezone failures:
  `test/features/reports/data/services/report_pdf_renderer_impl_test.dart`.
- Snapshot integrity (exact counts, stable token, unique IDs, cancellation)
  is tested by `report_source_page_collector_test.dart` and the Data
  repository tests; signed-JWT 1,300-row source tests passed in isolated CI.
- A separate 12,000-row test must verify all four source types, linked
  financial streams, returned page-byte size, totals, frozen values after
  writes, live role revocation, capacity, cleanup and timings. **No 12K PASS
  should be claimed until the dedicated GitHub workflow completes.**

## Gates not yet satisfied

1. Record per-mode, per-filter **screen vs PDF** row/group/total parity for
   all nine modes, with empty and long-field cases and both EN/AR layouts.
2. Complete the 12K+ isolated snapshot test; separately measure PostgreSQL
   peak memory and initialization latency. The current start RPC still
   materializes the complete authoritative JSON result before the capacity
   check, even though *page responses* are bounded.
3. Obtain separate owner approval for hosted Development-only migration
   ordering/deployment, then wire the snapshot repository into export-only DI.
   No app runtime should call unavailable new RPCs.
4. Run desktop/Android end-to-end tests again after the backend bridge is
   activated. iOS smoke remains at release gating. Export cancellation cannot
   interrupt native print/share dialogs and must be described accordingly.
5. Native XLSX (typed numbers/dates, injection prevention) remains separate
   PR B; it is not complete merely because PDF/export groundwork passes.

Related: [Issue #353](https://github.com/KingNarmar/horus_system/issues/353),
[Draft PR #389](https://github.com/KingNarmar/horus_system/pull/389), and
[Large Report Paging Contract](ISSUE_353_LARGE_REPORT_PAGING_CONTRACT.md).
