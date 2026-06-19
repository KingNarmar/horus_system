# H.O.R.U.S System — Roadmap Status

Last updated: 2026-06-19

## Current Position

The project has completed the core master-data foundation needed before Trips can be implemented.

Completed foundations include:

- Clean Architecture project structure.
- SaaS multi-tenant company scoping.
- Supabase RLS foundation.
- Authentication/company context foundation.
- Customers module.
- Drivers module.
- Audit & Accountability foundation.
- Fleet module for tractor heads and trailers.

## Recently Completed

### Issue #15 — Fleet Module

Status: Completed and closed.

Delivered:

- Tractor heads and trailers as separate assets.
- Domain-safe Fleet entities and repository abstractions.
- Data layer Supabase implementation.
- Fleet Cubit and UI.
- Desktop/tablet/mobile responsive Fleet screens.
- Create/update/deactivate/reactivate flows.
- Vehicle operational status separate from lifecycle `is_active`.
- Audit timeline/details integration.
- Supabase tables, RLS, policies, grants, enum values, and audit integrity verified manually.

Merged PRs:

- PR #41 — Fleet module foundation.
- PR #42 — Fleet schema/RLS guard migration.
- PR #43 — Tighten Fleet authenticated grants.

## Next Planned Work

### Next primary issue: Issue #16 — Routes Module

Routes are the correct next step before Trips because trips need predefined loading/unloading routes and default freight prices.

Planned scope:

- `routes` table with `company_id`.
- RLS and authenticated grants.
- Domain entity and repository abstraction.
- Data model, mapper, remote data source, repository implementation.
- Use cases.
- Routes Cubit.
- Routes list page.
- Add/edit route form.
- Active/inactive filtering.
- Deactivate/reactivate flow.
- Audit logs for create/update/deactivate/reactivate.
- Localization keys.

Do not start implementation until explicitly approved.

## Implementation Order From Here

1. Routes Module — Issue #16.
2. Trips Module.
3. Trip Expenses Module.
4. Dashboard Foundation.
5. Basic Reports.
6. Customer Statement.
7. Invoices and Payments.
8. Subscription placeholders and plan limits.
9. Documentation polish: README, contribution rules, testing strategy.
10. Responsive UI polish issues.

## Rules That Remain Locked

- Clean Architecture by the book.
- SOLID Principles.
- Dependency Rule: `Presentation → Domain ← Data`.
- Domain must not import Flutter, Supabase, Cubit, UI, JSON, DB, HTTP, or external services.
- Supabase access only in Data/DI.
- No Supabase calls in UI or Cubits.
- No business logic inside widgets.
- Every operational table must be scoped by `company_id`.
- RLS must protect every company-owned table.
- Localization-first.
- Audit logs must be app-wide foundation and written outside UI/Cubits.
- No temporary fixes.
- No unrelated changes inside feature PRs.
- Run `flutter analyze` and `flutter test` before closing implementation issues.

## Supabase Workflow Rule

Any Supabase-related change must be handled manually and carefully:

- Send one SQL query at a time.
- Wait for the result before sending the next query.
- Verify schema, RLS, policies, grants, enum values, and audit behavior before closing an issue.

## Stop Point

Roadmap status has been updated after closing Issue #15.

No new implementation should start until Mina explicitly says to continue.
