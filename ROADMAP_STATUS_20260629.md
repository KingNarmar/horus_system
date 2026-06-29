# Roadmap Status Update - 2026-06-29

## Completed

- Issue #24 - Driver advances and deductions foundation.
- PR #47 - Driver advances and deductions foundation.
- PR #48 - Issue #24 hardening cleanup.

## Verified

- Driver finance RLS insert access is restricted to `owner`, `admin`, and `accountant`.
- `authenticated` no longer has `UPDATE` privilege on `driver_financial_movements` while no update flow exists.
- Driver finance audit logs use semantic keys instead of English display text.
- Legacy audit display compatibility is preserved.
- Driver finance state emission no longer uses untracked async behavior.
- `flutter analyze` passed.
- `flutter test` passed.
- Supabase policy, grant, insert, rollback, and update checks were completed manually.

## Current Next Focus

1. Issue #25 - Invoices Domain foundation.
2. Issue #26 - Invoices Data and Presentation.
3. Issue #27 - Payments module.
4. Issue #28 - Customer statement foundation.
5. Issue #29 - Dashboard foundation.
6. Issue #30 - Basic reports.
7. Issue #31 - Subscription plans placeholder.
8. Issue #32 - Plan limit checks foundation.

## Working Rule

Before starting Issue #25, read and follow `AI_WORKING_RULES.md` and `PROJECT_ROADMAP.md`.
