# Roadmap Status Update - 2026-06-29

## Completed

- Issue #24 - Driver advances and deductions foundation.
- PR #47 - Driver advances and deductions foundation.
- PR #48 - Issue #24 hardening cleanup.
- PR #49 - AI working rules and roadmap status docs.

## Verified

- Driver finance RLS insert access is restricted to `owner`, `admin`, and `accountant`.
- `authenticated` no longer has `UPDATE` privilege on `driver_financial_movements` while no update flow exists.
- Driver finance audit logs use semantic keys instead of English display text.
- Legacy audit display compatibility is preserved.
- Driver finance state emission no longer uses untracked async behavior.
- `flutter analyze` passed.
- `flutter test` passed.
- Supabase policy, grant, insert, rollback, and update checks were completed manually.

## Roadmap Correction

Trip Expenses are already implemented for costs directly related to individual trips.

A separate Company Expenses module is required for general operating expenses that are not necessarily tied to a single trip, such as:

- Vehicle maintenance
- Spare parts
- Tires
- Oils and fluids
- Licenses and renewals
- Office expenses
- Rent
- Salaries or admin costs
- Any other general company expense

This module is required before the financial dashboard and full profit reports, because real company profitability must include both trip-level expenses and company-level operating expenses.

## Current Next Focus

1. Issue #50 - Company Expenses foundation.
2. Issue #25 - Invoices Domain foundation.
3. Issue #26 - Invoices Data and Presentation.
4. Issue #27 - Payments module.
5. Issue #28 - Customer statement foundation.
6. Issue #29 - Dashboard foundation.
7. Issue #30 - Basic reports.
8. Issue #31 - Subscription plans placeholder.
9. Issue #32 - Plan limit checks foundation.

## Branching Rule

Do not create a new branch for every small step.

Use one branch per real feature or PR-sized unit of work. Docs-only corrections may be committed directly to `main` when Mina explicitly approves and the change is safe and limited.

For code, database, or risky changes, use a focused feature branch and keep the diff minimal.

## Working Rule

Before starting Issue #50, read and follow:

- `AI_WORKING_RULES.md`
- `PROJECT_ROADMAP.md`
- `ROADMAP_STATUS_20260629.md`
- Issue #50
