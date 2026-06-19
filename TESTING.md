# H.O.R.U.S Testing Strategy

This document defines the testing strategy for H.O.R.U.S System before the codebase grows further.

The goal is to protect:

- Clean Architecture.
- SOLID principles.
- SaaS multi-tenant isolation.
- Domain business rules.
- Typed Failure codes.
- Audit/accountability behavior.
- Localization-sensitive UI behavior.

## Testing Principles

- Test business rules as close to Domain as possible.
- Domain tests must run without Flutter, Supabase, UI, Cubit/Bloc, JSON, HTTP, database, or external services.
- Prefer small focused tests over large fragile tests.
- Every bug fix should add or update a test when practical.
- Architecture-sensitive behavior must be covered before a feature is considered complete.

## Test Pyramid

Recommended priority order:

```text
1. Domain unit tests
2. Data mapper and repository tests
3. Cubit tests
4. Widget tests for critical flows
5. Manual smoke tests
```

## 1. Domain Unit Tests

Domain is the first testing target.

Cover:

- Use case success paths.
- Validation failures.
- Permission failures.
- Domain policies.
- Status/value objects.
- Filtering rules that belong to Domain.
- Typed Failure codes.

Domain tests must not import:

- Flutter.
- Supabase.
- Cubit / Bloc.
- UI.
- Data models.
- Data sources.
- Database constants.

Example targets:

- `AddCustomerUseCase` validates required name and permission.
- `DeactivateCustomerUseCase` rejects roles without management permission.
- `AddDriverUseCase` validates required full name.
- `DriverStatusFilter` matches active, inactive, and all correctly.

## 2. Data Mapper and Repository Tests

Data tests should verify conversion and integration behavior without leaking database details into Domain.

Cover:

- Model to Entity mapping.
- Entity/write data to insert/update maps.
- Supabase response parsing.
- Repository success paths.
- Repository failure mapping to typed Failures.
- Audit write coordination after successful mutations.

Repository implementation tests may use fake data sources and fake audit use cases first. Supabase integration tests can be added later when a safe test database workflow exists.

## 3. Cubit Tests

Cubit tests should verify presentation orchestration only.

Cover:

- Initial loading states.
- Success state after loading.
- Failure state after use case failure.
- Search/filter state changes.
- Local list updates after create/update/deactivate/reactivate.
- Button-level pending state for async actions.
- Prevention of duplicate taps during pending actions.

Cubit tests must not use Supabase directly.

## 4. Widget Tests

Widget tests should focus on critical flows, not every visual detail.

Cover:

- Required form validation.
- Add/edit dialogs submit the expected data.
- Active/Inactive/All filters affect visible rows/cards.
- Deactivate/reactivate buttons show loading and become disabled while pending.
- Localized labels are visible for important actions.
- Empty states and error states are displayed correctly.

Widget tests should use mocked or fake Cubits/use cases when possible.

## 5. Manual Smoke Tests

Manual smoke tests are required for flows that depend on real routing, responsive layout, or Supabase configuration.

Minimum smoke test checklist for each feature:

- Load the page successfully.
- Create a record.
- Edit the record.
- Deactivate and reactivate the record.
- Verify Active/Inactive/All filters.
- Verify search behavior.
- Verify permission-controlled actions.
- Verify audit timeline for create/update/status changes when applicable.
- Verify responsive layout on desktop, tablet, and mobile widths.

## Architecture-Sensitive Test Targets

These paths should receive early test coverage:

- Permission policies.
- Use case validation.
- Failure code mapping.
- Data mappers that convert DB fields into pure Domain entities.
- Company-scoped repository methods.
- RLS-related database migrations through review and later integration tests.
- Audit old/new value mapping.
- Cubit mutation flows that must avoid full-page loading.

## Multi-Tenant Testing Rules

Every company-owned feature must test or verify:

- `company_id` is required where applicable.
- Repository calls are company-scoped.
- New tables include RLS policies.
- Application behavior does not rely on UI-only tenant filtering.

Database RLS behavior should be covered by integration tests later when the project has a safe test database setup.

## Failure Testing Rules

For use cases and repositories, test both success and failure paths:

- Validation failure.
- Permission failure.
- Missing company context.
- Server/data source failure.
- Unexpected failure.

Tests should assert stable Failure codes, not only message text.

## Audit Testing Rules

For auditable mutations, test that:

- Audit is written only after a successful mutation.
- Audit is not written when mutation fails.
- Audit contains company id, module, entity type, entity id, action, actor role, and structured old/new values where applicable.
- UI/Cubit does not write audit logs directly.

## Test Location Convention

Mirror the `lib/` feature structure inside `test/`:

```text
test/features/<feature>/domain/usecases/
test/features/<feature>/domain/policies/
test/features/<feature>/data/mappers/
test/features/<feature>/data/repositories/
test/features/<feature>/presentation/cubit/
test/features/<feature>/presentation/widgets/
```

Core tests should live under:

```text
test/core/
```

## Required Verification Commands

Run before closing issues:

```bash
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

For documentation-only changes, `flutter analyze` and `flutter test` should still be run when possible to confirm the project remains healthy.

## Definition of Done for Feature Testing

A feature should not be considered complete until:

- Critical Domain use cases are tested.
- Permission policies are tested.
- Failure codes are tested.
- Important Cubit state flows are tested.
- Critical UI flows have widget tests or manual smoke coverage.
- `flutter analyze` passes.
- `flutter test` passes.

## Current Priority

Until broader coverage exists, prioritize tests in this order:

1. Domain use cases and policies for Customers and Drivers.
2. Cubit mutation flows for Customers and Drivers.
3. Data mappers for Customers, Drivers, and Audit.
4. Widget tests for create/update/deactivate/reactivate flows.
5. Repository tests using fake data sources and fake audit use cases.
