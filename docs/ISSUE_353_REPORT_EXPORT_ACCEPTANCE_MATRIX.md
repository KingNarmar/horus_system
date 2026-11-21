# Issue #353 — Nine-report export acceptance matrix

Status (2026-11-21): **PDF PR A #389 remains Draft and unmerged.**
The original `a9f48758` acceptance checkpoint completed **15/15 GitHub
Actions workflows** and the user-confirmed Development client smoke below.
The new focused long-field/paged-source regression tests added after that
checkpoint are **pending their own current-head CI result**; do not count prior
checks as results for a new commit. Native XLSX remains separate PR B.

The existing Reports **screen** uses its four authoritative report readers.
Development PDF **export** alone uses an authorized, frozen, paged snapshot
source. Development snapshot migrations were applied and merged via [PR #392](https://github.com/KingNarmar/horus_system/pull/392).
Staging/Production have not been approved for snapshot rollout.

## Nine report modes — observed client parity

User directly compared the selected company's Windows Development screen and
exported PDF on **2026-09-01 through 2026-11-21**. These were manual visual
comparisons, not independent machine-readable row diffs. The observations
must not be generalized to combinations or edge cases absent from that data.

| Report mode | Authoritative source | Domain representation | User-confirmed screen–PDF comparison |
| --- | --- | --- | --- |
| Daily trips | Operational trips | Trips grouped by day, eight typed columns | PASS — observed trip IDs/counts/statuses |
| Trips by customer | Operational trips | Grouped customer counts | PASS — observed groups and totals |
| Trips by route | Operational trips | Grouped route counts | PASS — observed routes and totals |
| Trips by driver | Operational trips | Grouped driver counts | PASS — observed drivers and totals |
| Trips by tractor head | Operational trips | Grouped tractor-head counts | PASS — observed plates and totals |
| Trips by trailer | Operational trips | Grouped trailer counts | PASS — observed plates and totals |
| Trip expenses | Trip-expenses RPC | Minor-unit money/Domain totals | PASS — observed expense values/currencies/totals |
| Trip net profit | Trips and ledger expenses in one frozen snapshot | Domain freight, expenses and net | PASS — observed per-trip and aggregate values |
| Open invoices | Invoices and payments in one frozen snapshot | Domain issued/paid/outstanding money | PASS — observed invoice/payment/balance values |

Evidence: [Windows 9/9 checkpoint](https://github.com/KingNarmar/horus_system/pull/389#issuecomment-7061256694).
This does **not** prove every negative/unassigned/long-value/multi-payment case
was present in the manually inspected data.

## Other completed evidence on `a9f48758`

- Windows Arabic/RTL Daily Trips: legible, correctly oriented, visible columns;
  [evidence](https://github.com/KingNarmar/horus_system/pull/389#issuecomment-7061326167).
- Physical HONOR Android 16: PDF preview, zoom and complete horizontal pan,
  native Share, Print preview (not physical printing), and Save/reopen;
  [preview](https://github.com/KingNarmar/horus_system/pull/389#issuecomment-7061418527),
  [share/print](https://github.com/KingNarmar/horus_system/pull/389#issuecomment-7061446745),
  [save](https://github.com/KingNarmar/horus_system/pull/389#issuecomment-7061964015).
- **Empty export bug fixed**: authoritative zero-business-row results return
  typed `reports.export.no_data` before branding, rendering or delivery;
  all nine kinds, four actions, zero-valued real rows and backend failure
  precedence are covered by Domain/Cubit/EN-AR Widget tests. The owner
  rechecked Daily Trips on HONOR for **2025-01-01 through 2025-01-31**
  and confirmed the no-data Snackbar;
  [evidence](https://github.com/KingNarmar/horus_system/pull/389#issuecomment-7061932166).
  The owner did not separately confirm absence of an opened preview in that
  message; the automated early-return tests assert that property.
- Operations-account UI: operational Daily Trips visible, financial Expenses,
  Net Profit and Open Invoices not exportable;
  [evidence](https://github.com/KingNarmar/horus_system/pull/389#issuecomment-7062028585).
  This is **not** the server security test.
- User confirmed Company A → close PDF preview → switch to Company B, with
  no stale A screen rows and B-scoped export/empty feedback;
  [evidence](https://github.com/KingNarmar/horus_system/pull/389#issuecomment-7062041343).
  This is not a manually tested mid-export tenant race.
- CI **15/15 succeeded on `a9f48758`**, including Flutter quality/test
  gates, Windows/Android release builds, signed-JWT, local migration replay
  and frozen-snapshot stress;
  [CI evidence](https://github.com/KingNarmar/horus_system/actions/runs/44897775530).

## Automated source and renderer coverage

- Domain kinds/permissions, grouped and financial parity, source validation,
  exact money semantics, typed errors and EN/AR feedback are covered by
  tests under `test/features/reports/`.
- Source collector and Data repository tests verify exact frozen counts,
  stable tokens, unique IDs, bounded cursors, cancellation and release.
  Signed-JWT tests verify backend role/tenant boundaries and role revocation.
- Renderer tests on the prior head cover 100-row and 1,000-row **short-field,
  three-column** pagination; a **seven-row eight-column** landscape PDF;
  and a **single short mixed Arabic/Latin** embedded-Cairo example.
- **New, pending current-head CI:** `report_pdf_long_content_test.dart`
  combines eight wide columns, wrapped descriptive fields, multiple pages,
  and an Arabic/English RTL Cairo scenario. The English test checks that
  every stable trip ID occurs once. It is an automated layout/content check,
  not a human pixel-level clipping inspection or proof against every
  adversarial unbreakable text input.
- **New, pending current-head CI:** a fake-source integration regression
  in `paged_reports_repository_impl_test.dart` covers **421 rows in three
  200-row-bounded calls**, exact IDs/count/progress and snapshot release.
  This exercises the adapter/collector, not a hosted device or a full
  app-to-PDF 421-row export.
- Separate [isolated 12K signed-JWT snapshot stress](https://github.com/KingNarmar/horus_system/actions/runs/44879958642)
  passed for all four report sources, with real frozen pages, exact financial
  totals, revocation, capacity and cleanup. This is **not** hosted app PDF
  rendering or concurrency/peak-memory verification.

## Acceptance boundaries and outstanding work

| Area | Evidence / decision | Status |
| --- | --- | --- |
| Nine-mode Windows screen–PDF parity | User visual comparisons for the recorded company/date fixture | PASS for observed dataset |
| Arabic and Android native delivery | Windows RTL and HONOR Preview/Save/Share/Print-preview | PASS for observed devices/actions |
| Empty export, role visibility, company switch after preview | Focused user checks + automated failure/security/lifecycle coverage | PASS for stated scenarios |
| Latest-head regression and CI | New isolated long-layout and >200-row adapter tests | **Pending current-head checks** |
| Hosted large multi-page app export (>200 rows) | Small Development fixture; isolated source/renderer tests are not a hosted combined flow | **Not evidenced; no shared DB fixture flood approved** |
| High concurrency, PostgreSQL peak memory/latency and safe degradation | Explicitly tracked in [Issue #391](https://github.com/KingNarmar/horus_system/issues/391) | **Deferred pre-RC gate** |
| iOS signed/device smoke and Production snapshot migration | Later rollout and release gates, separately authorized | Not part of PDF PR A acceptance |
| Native typed XLSX + formula injection protection | Separate PR B for Issue #353 | Not implemented |

Do **not** redo recorded owner smoke without a relevant regression, inflate
the 12K local stress into a production capacity claim, deploy seed fixtures to
hosted Development/Production, or merge #389 without final owner approval.
After PDF PR A, proceed to [Issue #390](https://github.com/KingNarmar/horus_system/issues/390)
and then XLSX PR B.

References: [Issue #353](https://github.com/KingNarmar/horus_system/issues/353),
[PR #389](https://github.com/KingNarmar/horus_system/pull/389),
[final review checkpoint](https://github.com/KingNarmar/horus_system/pull/389#issuecomment-7062251065),
[large-report paging contract](ISSUE_353_LARGE_REPORT_PAGING_CONTRACT.md).
