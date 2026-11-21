# Issue #353 — Versioned Development DB rollout

Status as of 2026-11-21:

- **Development** `zwnfmszssxtfxkaofnhq`: original versions
  `20261120144500` (canonical company timezones) and
  `20261121070000` (report-export frozen snapshots) applied **in order**.
- **Production**: not deployed, not authorized by this PR.
- Other database migrations: no outstanding files relative to Development
  at the point of this rollout.
- Version identity: each migration was applied atomically on Development and
  the original file text was recorded under the original version/name in
  `supabase_migrations.schema_migrations`; no generated timestamp substitution.
- Existing reports continue using legacy sources until Issue #353's Data
  injection, PDF/XLSX acceptance and app smoke are complete. The new RPCs
  are additive and dormant in the app.
- No app business logic, company data, RLS policies on existing company
  tables, or Production secrets changed.

## Development verification

- Both private snapshot tables have RLS enabled. `anon` and
  `authenticated` have no direct table SELECT privileges.
- `start_report_export_snapshot`, `read_report_export_snapshot_page`,
  `release_report_export_snapshot`: SECURITY DEFINER with fixed
  `pg_catalog` search path, no anonymous EXECUTE grant, explicit
  authenticated EXECUTE grant, database-level live membership and role gates.
- Internal purge function not executable by anonymous/authenticated roles.
  The isolated `horus-report-export-snapshot-cleanup` pg_cron job runs
  every five minutes.
- Hosted Development transaction-scoped smoke: active owner can start, read
  and release; finance access denied to viewer; cross-company snapshot
  creation denied. Smoke-test writes rolled back.
- Isolated CI: 1,300-row signed JWT tests, 12K source stress,
  migration replay and full Flutter CI all passed on
  `34c72d403a12bc9e4df3d0e61a43eddad26ce4fc`.

## Limits / next gates

- The start RPC still materializes the full canonical report JSON *inside*
  PostgreSQL before the row and bytes guard. Local stress is not a Production
  resource guarantee. Do not enable it as a default or declare the export
  feature release-ready without reviewing peak memory, concurrency and
  delivery parity.
- Follow-up: Issue #353's app DI activation + PDF/XLSX end-to-end acceptance,
  #391 scale/recovery verification, then **separate** Production migration
  authorization and release QA.
- No automatic DB deployment is performed by merging these migration files
  to GitHub main. This PR records the Development-tested schema in the repo.

References:
- https://github.com/KingNarmar/horus_system/issues/353
- https://github.com/KingNarmar/horus_system/pull/389
- https://github.com/KingNarmar/horus_system/actions/runs/44882291437
- https://github.com/KingNarmar/horus_system/actions/runs/44882291386
