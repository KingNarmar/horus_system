# H.O.R.U.S System — GitHub Issues Execution Plan

## Purpose

This document defines the first execution issues for **H.O.R.U.S System**.

**H.O.R.U.S System** stands for:

**Heavy Operations & Route Unified System**

The project must always follow:

```text
SaaS + Multi-Tenant + Responsive/Adaptive + Clean Architecture by the book + SOLID Principles
```

This file is a planning document. Issues can be copied from here into GitHub Issues one by one.

---

# Issue Labels

Recommended labels:

- `foundation`
- `architecture`
- `database`
- `supabase`
- `flutter`
- `auth`
- `saas`
- `ui`
- `master-data`
- `operations`
- `finance`
- `reports`
- `subscriptions`
- `documentation`

---

# Milestone 0 — Project Foundation

## Issue #1 — Setup Flutter project for H.O.R.U.S System

### Goal

Create the initial Flutter project and prepare it for desktop, tablet, mobile, and web-friendly development.

### Scope

- Create Flutter project.
- Set project name to `horus_system`.
- Configure basic app entry points.
- Confirm the app runs successfully.
- Prepare the project for adaptive/responsive UI.

### Acceptance Criteria

- Flutter project exists in the repository.
- App runs without errors.
- Project name is consistent with H.O.R.U.S System.
- No business feature is implemented yet.

### Architecture Rules

- No feature logic in `main.dart`.
- App bootstrap must stay clean and minimal.

---

## Issue #2 — Create Clean Architecture folder structure

### Goal

Create the base folder structure required by Clean Architecture by the book.

### Scope

Create the following structure:

```text
lib/
  main.dart
  app.dart

  core/
    config/
    constants/
    errors/
    extensions/
    routing/
    theme/
    utils/
    validators/
    widgets/
    di/

  shared/
    entities/
    models/
    services/
    cubits/

  features/
    auth/
      data/
      domain/
      presentation/

    company/
      data/
      domain/
      presentation/

    subscriptions/
      data/
      domain/
      presentation/

    customers/
      data/
      domain/
      presentation/

    drivers/
      data/
      domain/
      presentation/

    fleet/
      data/
      domain/
      presentation/

    routes/
      data/
      domain/
      presentation/

    trips/
      data/
      domain/
      presentation/

    expenses/
      data/
      domain/
      presentation/

    invoices/
      data/
      domain/
      presentation/

    reports/
      data/
      domain/
      presentation/
```

### Acceptance Criteria

- Required folders exist.
- No Supabase imports exist outside Data Layer.
- No UI code exists inside Domain or Data.
- The structure matches `ARCHITECTURE_GUIDELINES.md`.

---

## Issue #3 — Add base architectural contracts

### Goal

Create shared base contracts used across features.

### Scope

Add:

- `Failure` base class.
- Common failure types.
- Base use case class.
- Base repository result type approach.
- Shared validation helpers if needed.

### Acceptance Criteria

- Domain errors are represented as failures, not raw exceptions.
- Use Cases can return success/failure cleanly.
- No external SDK is imported into Domain.

### Architecture Rules

- Domain must remain pure.
- No Flutter, Supabase, JSON, or HTTP dependencies in Domain.

---

## Issue #4 — Configure app theme and responsive foundations

### Goal

Prepare a consistent visual foundation for desktop, tablet, and mobile.

### Scope

- Create base app theme.
- Create spacing constants.
- Create breakpoints.
- Create responsive layout helper.
- Prepare placeholders for desktop/tablet/mobile layouts.

### Acceptance Criteria

- App has a central theme.
- Breakpoints are defined in one place.
- No business logic is duplicated per screen size.

---

# Milestone 1 — Supabase and SaaS Foundation

## Issue #5 — Setup Supabase database schema v1

### Goal

Apply and validate `docs/database/DATABASE_SCHEMA_V1.sql` in Supabase.

### Scope

- Create Supabase project.
- Run schema v1 SQL.
- Confirm tables are created.
- Confirm enums are created.
- Confirm RLS is enabled.
- Confirm seed subscription plans are inserted.

### Acceptance Criteria

- All schema objects are created successfully.
- RLS is enabled on SaaS, master data, operations, and finance tables.
- No operational table is missing `company_id`.
- Subscription plans exist.

### Notes

If SQL errors appear, create a follow-up migration instead of editing history after production begins.

---

## Issue #6 — Implement Supabase configuration in Data Layer only

### Goal

Configure Supabase access without violating Clean Architecture.

### Scope

- Add Supabase dependency.
- Create Supabase client initialization.
- Place Supabase access behind Data Layer services.
- Prepare environment configuration.

### Acceptance Criteria

- Supabase initialization works.
- No Supabase import exists in Domain.
- No Supabase query exists in Cubit or UI.

### Architecture Rules

Supabase is an external detail and must stay outside Domain and Presentation business logic.

---

## Issue #7 — Implement authentication foundation

### Goal

Create the authentication foundation using Clean Architecture.

### Scope

Create Auth feature:

```text
features/auth/
  domain/
    entities/
    repositories/
    usecases/
  data/
    models/
    datasources/
    repositories/
  presentation/
    cubit/
    pages/
    widgets/
```

Implement:

- Login use case.
- Logout use case.
- Get current user use case.
- Auth repository abstraction.
- Supabase auth data source.
- Auth Cubit.
- Login page.

### Acceptance Criteria

- User can log in.
- User can log out.
- Auth state is handled by Cubit.
- Cubit calls Use Cases only.
- Supabase Auth calls are only inside Data Layer.

---

## Issue #8 — Implement company onboarding foundation

### Goal

Allow a new user to create a company workspace.

### Scope

- Create company entity.
- Create company repository abstraction.
- Create company remote data source.
- Create company onboarding use case.
- Create company onboarding page.
- Insert company record.
- Insert owner record in `company_users`.

### Acceptance Criteria

- Authenticated user can create a company.
- User becomes company owner.
- Company context can be loaded after onboarding.
- Tenant ownership is respected.

### Notes

If direct insert flow becomes limited by RLS, create secure Supabase RPC in a later migration.

---

## Issue #9 — Implement current company context

### Goal

Load and store the active company context for the logged-in user.

### Scope

- Get user companies.
- Select active company.
- Store current company in app state.
- Expose current company ID to repositories through a safe context provider.

### Acceptance Criteria

- User can only see companies they belong to.
- Current company is required before accessing business modules.
- Repositories cannot operate without company context.

### Architecture Rules

- UI must not hardcode `company_id`.
- Tenant filtering must not rely only on UI logic.

---

## Issue #10 — Implement company users and roles foundation

### Goal

Create the first role-based access structure.

### Scope

- Load company users.
- Display user roles.
- Support roles:
  - owner
  - admin
  - operations
  - accountant
  - viewer
  - driver later
- Prepare invite flow placeholder.

### Acceptance Criteria

- Company owner can view company users.
- Role enum is represented safely in Domain.
- UI behavior can be adjusted by role.
- No permission logic is hardcoded randomly in widgets.

---

# Milestone 2 — App Shell and Navigation

## Issue #11 — Implement responsive/adaptive app shell

### Goal

Create the main shell used after login.

### Scope

Desktop:

- Sidebar navigation.
- Main content area.

Tablet:

- Navigation rail.
- Adaptive content width.

Mobile:

- Bottom navigation.
- Card-based content approach.

### Acceptance Criteria

- Same route works across desktop/tablet/mobile.
- Layout adapts based on breakpoint.
- Business logic is not duplicated per platform.

---

## Issue #12 — Implement routing foundation

### Goal

Create app routing with authentication and company guards.

### Scope

- Public routes.
- Authenticated routes.
- Company-required routes.
- Placeholder routes for main modules.

### Acceptance Criteria

- User cannot access app shell without login.
- User cannot access company modules without company context.
- Routes are centralized.

---

# Milestone 3 — Master Data

## Issue #13 — Implement customers module

### Goal

Allow each company to manage its own customers.

### Scope

- Customer entity.
- Customer model.
- Customer mapper.
- Customers repository abstraction.
- Customers remote data source.
- Use cases:
  - GetCustomersUseCase
  - AddCustomerUseCase
  - UpdateCustomerUseCase
  - DeactivateCustomerUseCase
- Customers Cubit.
- Customers page.
- Add/edit customer form.
- Desktop table.
- Mobile cards.

### Acceptance Criteria

- Company user can list customers for current company only.
- Authorized roles can add/edit customers.
- Customers can be deactivated instead of hard deleted.
- No Supabase calls exist in Cubit or UI.

---

## Issue #14 — Implement drivers module

### Goal

Allow each company to manage drivers.

### Scope

- Driver entity/model/mapper.
- Repository abstraction and implementation.
- Data source.
- Use cases.
- Drivers Cubit.
- Drivers page.
- Driver form.
- Driver status support.

### Acceptance Criteria

- Drivers are company-scoped.
- Driver status is represented using Domain enum/value.
- Operations role can manage drivers.
- Driver can be deactivated.

---

## Issue #15 — Implement fleet module: tractor heads and trailers

### Goal

Manage tractor heads and trailers as separate assets.

### Scope

- TractorHead entity/model/mapper.
- Trailer entity/model/mapper.
- Fleet repository abstraction.
- Fleet data source.
- Use cases.
- Fleet Cubit.
- Tractor heads page.
- Trailers page.
- Add/edit forms.
- Vehicle status support.

### Acceptance Criteria

- Tractor heads and trailers are separated.
- Plate number is unique per company.
- Vehicle status is tracked.
- No permanent pairing is forced.

---

## Issue #16 — Implement routes module

### Goal

Allow each company to define loading/unloading routes and default freight price.

### Scope

- Route entity/model/mapper.
- Repository abstraction and implementation.
- Data source.
- Use cases.
- Routes page.
- Route form.

### Acceptance Criteria

- Company can create routes.
- Route can include loading location, unloading location, governorates, and default freight price.
- Route can be deactivated.

---

## Issue #17 — Implement expense types and payment methods settings

### Goal

Allow company-specific financial setup.

### Scope

- Expense types CRUD.
- Payment methods CRUD.
- Default values can be created per company later.

### Acceptance Criteria

- Expense types are company-scoped.
- Payment methods are company-scoped.
- Accountant/admin roles can manage them.

---

# Milestone 4 — Trip Operations

## Issue #18 — Implement trips domain foundation

### Goal

Create the pure Domain foundation for trip operations.

### Scope

- TripEntity.
- TripStatus.
- TripsRepository abstraction.
- CreateTripParams.
- UpdateTripStatusParams.
- Use cases:
  - CreateTripUseCase
  - GetTripsUseCase
  - GetTripDetailsUseCase
  - UpdateTripStatusUseCase
  - CalculateTripNetProfitUseCase

### Acceptance Criteria

- Domain contains no Flutter or Supabase imports.
- Trip rules are represented in Domain.
- Profit calculation is isolated in a Use Case.

---

## Issue #19 — Implement trips data layer

### Goal

Connect trip Domain contracts to Supabase.

### Scope

- TripModel.
- TripMapper.
- TripsRemoteDataSource.
- TripsRepositoryImpl.
- Query trips by current company.
- Insert trip.
- Update trip status.
- Load trip details.

### Acceptance Criteria

- Data layer implements Domain repository.
- Supabase calls are isolated in remote data source.
- All queries are scoped to current company.

---

## Issue #20 — Implement trips presentation layer

### Goal

Create the UI and Cubit for trip operations.

### Scope

- TripsCubit.
- TripsState.
- TripsPage.
- AddEditTripPage.
- TripDetailsPage.
- Trip form.
- Desktop table.
- Mobile card list.
- Status update action.

### Acceptance Criteria

- User can create a trip.
- User can list trips.
- User can view trip details.
- User can update trip status.
- Cubit calls Use Cases only.

---

## Issue #21 — Implement trip status history

### Goal

Record every important trip status change.

### Scope

- Insert status history record when status changes.
- Load status history in trip details.
- Show changed by, changed at, old status, new status.

### Acceptance Criteria

- Status changes are traceable.
- Trip details show status history.
- No status update happens silently.

---

# Milestone 5 — Expenses and Driver Settlement

## Issue #22 — Implement trip expenses module

### Goal

Track direct expenses per trip.

### Scope

- TripExpense entity/model/mapper.
- Repository abstraction and implementation.
- Data source.
- Use cases:
  - AddTripExpenseUseCase
  - GetTripExpensesUseCase
  - UpdateTripExpenseUseCase
- Expenses UI inside trip details.
- Expense list by trip.

### Acceptance Criteria

- Expenses are linked to trip and company.
- Amount must be positive.
- Expense can identify who paid it.
- Trip total expenses are calculated.

---

## Issue #23 — Implement trip net profit calculation

### Goal

Calculate trip net profit in Domain.

### Initial Formula

```text
Trip Net Profit = Freight Price - Total Trip Expenses
```

### Scope

- CalculateTripNetProfitUseCase.
- Unit-testable business logic.
- Display net profit in trip details.

### Acceptance Criteria

- Profit calculation is not inside UI.
- Formula is isolated and easy to change later.
- Trip details shows freight, expenses, and net profit.

---

## Issue #24 — Implement driver advances and deductions foundation

### Goal

Track basic driver financial movements.

### Scope

- Driver advances.
- Driver deductions.
- Link deduction to trip when applicable.
- Basic driver balance view placeholder.

### Acceptance Criteria

- Accountant can add driver advance.
- Accountant can add driver deduction.
- Driver financial records are company-scoped.

---

# Milestone 6 — Invoices and Payments

## Issue #25 — Implement invoices domain foundation

### Goal

Create the pure Domain foundation for invoices.

### Scope

- InvoiceEntity.
- InvoiceStatus.
- InvoicesRepository abstraction.
- Use cases:
  - CreateInvoiceFromTripUseCase
  - CreateGroupedInvoiceUseCase
  - GetInvoicesUseCase
  - UpdateInvoiceStatusUseCase

### Acceptance Criteria

- Invoice rules are in Domain.
- Domain has no Supabase or Flutter imports.
- Invoice statuses are represented safely.

---

## Issue #26 — Implement invoices data and presentation

### Goal

Allow users to create and manage invoices.

### Scope

- InvoiceModel.
- InvoiceMapper.
- InvoicesRemoteDataSource.
- InvoicesRepositoryImpl.
- InvoicesCubit.
- InvoicesPage.
- Create invoice from trip.
- Invoice details page.

### Acceptance Criteria

- Accountant can create invoice from trip.
- Invoice is company-scoped.
- Invoice can be listed and viewed.
- Trip cannot be invoiced twice.

---

## Issue #27 — Implement payments module

### Goal

Register payments against invoices/customers.

### Scope

- Payment entity/model/mapper.
- Payments repository.
- Payments data source.
- RegisterPaymentUseCase.
- Payments UI.
- Update invoice payment status.

### Acceptance Criteria

- Accountant can register payment.
- Payment amount must be positive.
- Partial payment is supported.
- Invoice status can become partially paid or paid.

---

## Issue #28 — Implement customer statement foundation

### Goal

Show a basic customer account statement.

### Scope

- Customer invoices.
- Customer payments.
- Outstanding balance.
- Date filtering.

### Acceptance Criteria

- Accountant can view customer statement.
- Statement is company-scoped.
- Statement includes invoices, payments, and balance.

---

# Milestone 7 — Dashboard and Reports

## Issue #29 — Implement dashboard foundation

### Goal

Create the first management dashboard.

### Scope

Dashboard cards:

- Today trips.
- Running trips.
- Delivered trips.
- Available vehicles.
- Vehicles on trip.
- Total revenue.
- Total expenses.
- Net profit.
- Unpaid invoices.

### Acceptance Criteria

- Dashboard loads company-specific data.
- Dashboard works on desktop/tablet/mobile.
- No business calculations are inside widgets.

---

## Issue #30 — Implement basic reports

### Goal

Create the initial operational and financial reports.

### Scope

Reports:

- Daily trips report.
- Trips by customer.
- Trips by driver.
- Trips by tractor head.
- Trips by trailer.
- Trip expenses report.
- Trip net profit report.
- Unpaid invoices report.

### Acceptance Criteria

- Reports are company-scoped.
- Reports support date filtering.
- Reports can be displayed clearly on desktop.
- Mobile can show simplified report cards.

---

# Milestone 8 — Subscription Layer

## Issue #31 — Implement subscription plans placeholder

### Goal

Show available subscription plans and current company plan.

### Scope

- Load subscription plans.
- Load current company subscription.
- Show plan limits.
- Show subscription status.

### Acceptance Criteria

- Company owner can view current plan.
- Company owner can view available plans.
- No real payment gateway is required in MVP.

---

## Issue #32 — Implement plan limit checks foundation

### Goal

Prepare the system for monthly subscription limits.

### Scope

Initial limits:

- Max users.
- Max vehicles.
- Max trips per month.

### Acceptance Criteria

- Use cases can check limits before creating records.
- Limit failures are represented as Domain failures.
- UI shows user-friendly limit messages.

---

# Milestone 9 — Documentation and Quality

## Issue #33 — Add README project overview

### Goal

Create a professional README for H.O.R.U.S System.

### Scope

README should include:

- Project name.
- Meaning of H.O.R.U.S.
- Project vision.
- Tech stack.
- Architecture rules.
- SaaS concept.
- Current roadmap status.

### Acceptance Criteria

- README is clear and professional.
- Architecture rules are mentioned.
- Project status is clear.

---

## Issue #34 — Add contribution and code rules document

### Goal

Create a short developer guide for future contributors.

### Scope

- Clean Architecture rules.
- SOLID rules.
- Branch naming.
- Commit message style.
- PR checklist.

### Acceptance Criteria

- Developers know how to contribute without breaking architecture.
- PR checklist includes architecture validation.

---

## Issue #35 — Add testing strategy document

### Goal

Define the testing approach before the codebase grows.

### Scope

- Domain use case tests.
- Repository implementation tests later.
- Cubit tests.
- Widget tests for critical flows.

### Acceptance Criteria

- Testing priorities are documented.
- Domain logic is identified as first testing target.

---

# Initial Execution Order

Recommended start order:

1. Issue #1 — Setup Flutter project.
2. Issue #2 — Create Clean Architecture folder structure.
3. Issue #3 — Add base architectural contracts.
4. Issue #4 — Configure app theme and responsive foundations.
5. Issue #5 — Setup Supabase database schema v1.
6. Issue #6 — Implement Supabase configuration in Data Layer only.
7. Issue #7 — Implement authentication foundation.
8. Issue #8 — Implement company onboarding foundation.
9. Issue #9 — Implement current company context.
10. Issue #11 — Implement responsive/adaptive app shell.

---

# Final Reminder

No issue should be implemented in a way that violates:

```text
Clean Architecture by the book
SOLID Principles
SaaS multi-tenant isolation
Responsive/adaptive platform support
```

If implementation speed conflicts with architecture correctness, architecture correctness wins.
