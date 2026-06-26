# H.O.R.U.S System - Project Roadmap

## Project Name

**H.O.R.U.S System**

**Heavy Operations & Route Unified System**

## Project Vision

H.O.R.U.S System is a SaaS platform for managing heavy transport companies.
The first real business case targets cement transport companies operating tractor heads and trailers between governorates.

The system must manage the full operational and financial cycle:

* Companies
* Users and roles
* Customers
* Drivers
* Tractor heads
* Trailers
* Routes
* Trips
* Trip expenses
* Driver settlements
* Invoices
* Payments
* Reports
* Subscriptions

The platform must be designed as a commercial product that can be sold to multiple companies using monthly subscription plans.

---

## Current Roadmap Status

Last updated: 2026-06-26

The project has completed the core SaaS foundation, the main master-data foundation, and the current Trips/Trip Expenses foundation that has been reviewed and accepted so far.

Completed foundations include:

* Clean Architecture project structure
* SaaS multi-tenant company scoping
* Supabase RLS foundation
* Authentication and current company context foundation
* Customers module
* Customers responsive polish
* Drivers module
* Audit & Accountability foundation
* Fleet module for tractor heads and trailers
* Routes module
* Trips Domain foundation
* Trips Data layer foundation
* Trips Presentation layer
* Trip Status History
* Trip Expenses module
* Trip Net Profit calculation through an isolated Domain use case
* README project overview
* CONTRIBUTING rules document
* TESTING strategy document

Recently completed / closed:

* Issue #14 - Drivers module was completed and closed.
* Issue #15 - Fleet Module was completed and closed.
* PR #41 - Fleet module foundation was merged.
* PR #42 - Fleet schema/RLS guard migration was merged.
* PR #43 - Tightened Fleet authenticated grants was merged.
* Issue #16 - Routes Module was completed and closed.
* PR #44 - Routes module was merged.
* Issue #18 - Trips Domain Foundation was completed and closed.
* Issue #19 - Trips Data Layer was completed and closed.
* Issue #20 - Trips Presentation Layer was completed and closed.
* Issue #21 - Trip Status History was completed and closed.
* Issue #22 - Trip Expenses Module was completed and closed.
* Issue #23 - Trip Net Profit Calculation was completed and closed.
* Issue #33 - README Project Overview was completed and closed.
* Issue #34 - Contribution and Code Rules document was completed and closed.
* Issue #35 - Testing Strategy document was completed and closed.
* Issue #39 - Customers Responsive UI polish was completed and closed.
* Issue #17 - Old mixed expense types/payment methods settings issue was closed as superseded/not planned.

Current phase:

* Phase 2 - Master Data is complete for Customers, Drivers, Fleet, and Routes.
* Phase 3 - Trip Operations foundation is complete for the currently reviewed scope.
* Phase 4 - Expenses and Driver Settlement has started with Trip Expenses.
* Trip Expenses are implemented using DB-backed `expense_types`, company-scoped `trip_expenses`, audit logs, and automatic `trips.total_expenses` recalculation.
* Trip Net Profit is displayed using an isolated Domain use case and must remain isolated from UI.

Next implementation focus:

1. Issue #24 - Driver advances and deductions foundation.
2. Issue #25 - Invoices Domain foundation.
3. Issue #26 - Invoices Data and Presentation.
4. Issue #27 - Payments module.
5. Issue #28 - Customer statement foundation.
6. Issue #29 - Dashboard foundation.
7. Issue #30 - Basic reports.
8. Issue #31 - Subscription plans placeholder.
9. Issue #32 - Plan limit checks foundation.

Deferred Settings / Platform work:

* Issue #37 - Company timezone support.
  * Backlog unless reporting/date behavior needs it earlier.
* Issue #45 - Settings: Manage expense types master data.
  * Deferred until the Settings module implementation begins.
  * The current Trip Expenses flow is not blocked because default expense types are seeded for existing companies and auto-seeded for new companies.
* Issue #46 - Settings: Manage payment methods master data.
  * Created to replace the payment-methods part of old Issue #17.
  * Deferred until the Settings module or Payments module needs payment-method master data.

Supabase workflow rule:

* Any Supabase-related change must be handled manually and carefully.
* Send one SQL verification query at a time.
* Wait for the result before sending the next query.
* Verify schema, RLS, policies, grants, enum values, triggers, seed data, and audit behavior before closing an issue.
* Any DB change must be saved as a migration in the repository and must not remain live-only in Supabase.

Stop point:

* No new implementation should start until Mina explicitly says to continue.

---

# 1. Core Architecture Decision

H.O.R.U.S System must strictly follow Clean Architecture by the book.

The project must respect the Dependency Rule.

Inner layers must not depend on outer layers.

The Domain Layer must not know anything about:

* Flutter
* Supabase
* Cubit
* Bloc
* UI
* JSON
* HTTP
* Database tables
* External services
* Data models
* Data sources

The correct dependency direction is:

```text
Presentation -> Domain <- Data
```

The Domain Layer is the core of the application.

## SOLID Principles

All code must follow SOLID principles:

* Single Responsibility Principle
* Open / Closed Principle
* Liskov Substitution Principle
* Interface Segregation Principle
* Dependency Inversion Principle

No business logic should be written directly inside UI widgets.

No Supabase queries should be written inside UI widgets or Cubits.

All external implementations must depend on abstractions defined in the Domain Layer.

---

# 2. Technology Stack

## Frontend

Flutter

The application must support:

* Desktop
* Tablet
* Mobile

## Backend

Supabase is used for:

* Authentication
* PostgreSQL database
* Row Level Security
* Storage later for trip documents and attachments

## State Management

Cubit / Bloc

## Architecture Style

Feature-first Clean Architecture.

Each feature must be divided into:

```text
data/
domain/
presentation/
```

---

# 3. SaaS Requirements

H.O.R.U.S System is not a single-company custom application.

It must be built as a SaaS product from day one.

Every operational table must include:

```text
company_id
```

Each company must only access its own data.

Company isolation must be enforced at database level using Row Level Security.

Application-level filtering is not enough.

---

# 4. Platform Requirements

## Desktop

Main platform for:

* Admin users
* Company owners
* Accountants
* Operations staff

Desktop UI should use:

* Sidebar navigation
* Data tables
* Filters
* Reports
* Export actions

## Tablet

Tablet UI should support:

* Operations monitoring
* Trip status review
* Dashboard overview
* Quick actions

## Mobile

Mobile UI should support:

* Owner dashboard
* Trip overview
* Basic status tracking
* Later driver-specific actions

Driver mobile app features are not part of MVP unless explicitly required later.

---

# 5. User Roles

## Platform Level

* Platform Owner
* Platform Admin

## Company Level

* Company Owner
* Company Admin
* Operations User
* Accountant
* Viewer
* Driver later

---

# 6. Main Modules

## Phase 0 - Foundation

Status: Completed.

Deliverables:

* Project roadmap
* Database schema v1
* Flutter project structure
* Supabase setup plan
* Architecture rules
* Initial GitHub issues

## Phase 1 - SaaS Foundation

Status: Core foundation completed.

Modules:

* Authentication
* Company creation
* Company profile
* Company users
* User roles
* Current company context
* Subscription plan placeholder - still needs Issue #31 implementation
* Trial status placeholder
* RLS policies

## Phase 2 - Master Data

Status: Core master-data foundation completed.

Completed:

* Customers
* Customers responsive polish
* Drivers
* Tractor Heads
* Trailers
* Routes

Supporting master data:

* Expense Types are seeded for Trip Expenses and are DB-backed.
* Expense Types Settings management is deferred to Issue #45.
* Payment Methods Settings management is tracked separately in Issue #46.

## Phase 3 - Trip Operations

Status: Current reviewed Trips foundation completed.

Implemented or available in the current Trips flow:

* Trip creation
* Trip list
* Trip details
* Assign customer
* Assign route
* Assign driver
* Assign tractor head
* Assign trailer
* Trip status update
* Trip status history
* Trip timings
* Loading order number
* Waybill number
* Quantity in tons
* Freight price
* Prevent duplicate open trip for the same vehicle
* Audit/accountability for trip actions
* Activity timeline inside Trip Details
* Localized EN/AR presentation strings
* Trip Net Profit calculation through isolated Domain use case

Initial trip statuses:

* Created
* Assigned
* Loaded
* On Road
* Arrived
* Delivered
* Documents Received
* Invoiced
* Paid
* Cancelled

Closed Trips review issues:

* Issue #18 - Trips Domain Foundation.
* Issue #19 - Trips Data Layer.
* Issue #20 - Trips Presentation Layer.
* Issue #21 - Trip Status History.
* Issue #23 - Trip Net Profit Calculation.

## Phase 4 - Expenses and Driver Settlement

Status: Started.

Completed:

* Issue #22 - Trip Expenses Module.

Trip Expenses delivered scope:

* `trip_expenses` table integrated with company-scoped access.
* `expense_types` used as DB-backed master data.
* Default expense types seeded for existing companies.
* Default expense types auto-seeded for new companies through a company insert trigger.
* Add trip expense from Trip Details.
* Update trip expense from Trip Details.
* Expense type is required and saved as `expense_type_id`.
* `Other` expense type supports custom `expense_name`.
* Amount must be positive.
* Paid-by is tracked.
* `trips.total_expenses` is recalculated after add/update.
* Trip Net Profit is calculated as Freight Price minus Total Trip Expenses.
* Activity Timeline shows context-aware Trip vs Expense actions.
* EN/AR localization covers labels, saved expense names, audit labels, and validation/failure messages.
* No Supabase calls exist in Cubit or UI.

Remaining modules:

* Issue #24 - Driver advances and deductions foundation.
* Driver monthly settlement later.

Initial formula:

```text
Trip Net Profit = Freight Price - Total Trip Expenses
```

The formula must stay isolated inside a Domain Use Case so it can be changed later without changing UI or Data layers.

## Phase 5 - Invoices and Payments

Status: Not implemented yet. Issues #25, #26, #27, and #28 were reviewed and left open.

Modules:

* Issue #25 - Invoices Domain foundation.
* Issue #26 - Invoices Data and Presentation.
* Issue #27 - Payments module.
* Issue #28 - Customer account statement foundation.
* Create invoice from trip.
* Create grouped invoice for customer.
* Invoice status.
* Payments.
* Partial payments.
* Customer account statement.
* Unpaid invoices report.
* Overdue invoices report.

Invoice statuses:

* Draft
* Issued
* Partially Paid
* Paid
* Overdue
* Cancelled

## Phase 6 - Dashboard and Reports

Status: Not implemented yet. Issues #29 and #30 were reviewed and left open.

Dashboard should show:

* Today trips
* Running trips
* Delivered trips
* Available vehicles
* Vehicles on trip
* Total revenue
* Total expenses
* Net profit
* Unpaid invoices
* Overdue invoices

Initial reports:

* Daily trips report
* Trips by customer
* Trips by driver
* Trips by tractor head
* Trips by trailer
* Trip expenses report
* Trip net profit report
* Vehicle profitability report
* Customer statement
* Unpaid invoices report

## Phase 7 - Subscription and Commercial Layer

Status: Not implemented yet. Issues #31 and #32 were reviewed and left open.

Modules:

* Issue #31 - Subscription plans placeholder.
* Issue #32 - Plan limit checks foundation.
* Subscription plans
* Company subscription
* Trial mode
* Plan limits
* Billing status
* Subscription expiration handling

Initial subscription plans:

### Basic

* Limited users
* Limited vehicles
* Limited trips per month
* Basic reports

### Pro

* More users
* More vehicles
* More trips
* Invoices
* Payments
* Profit reports
* Customer statements

### Enterprise

* Custom limits
* Advanced reports
* Attachments
* Maintenance
* Future integrations

## Phase 8 - Settings and Master Data Administration

Status: Deferred.

Tracked issues:

* Issue #45 - Settings: Manage expense types master data.
* Issue #46 - Settings: Manage payment methods master data.

Rules:

* No Settings master-data implementation should start before the Settings module begins or before a dependent workflow requires it.
* Expense type management must use the existing `expense_types` table.
* Payment method management may introduce a `payment_methods` table when implemented.
* Both features must be company-scoped, localized EN/AR, permission-checked in Domain use cases, and audited.

## Phase 9 - Advanced Features

These features are not part of MVP.

* Driver mobile app
* GPS tracking
* WhatsApp notifications
* Customer portal
* Document upload from mobile
* QR code per trip
* Advanced maintenance
* Accounting system integration
* Payment gateway integration
* Offline mode

---

# 7. Current Database Tables

## SaaS Core

* companies
* company_users
* subscription_plans
* company_subscriptions

## Users and Access

* user_profiles
* roles or role enum
* permissions later if needed

## Master Data

* customers
* drivers
* tractor_heads
* trailers
* routes
* expense_types
* payment_methods later

## Audit and Accountability

* audit_logs

## Operations

* trips
* trip_status_history
* trip_expenses
* trip_attachments later

## Finance

* invoices
* invoice_trips
* payments
* driver_advances
* driver_deductions
* driver_settlements later

## Reports

Reports should be generated from operational tables and database views where appropriate.

---

# 8. Required Folder Structure

The project must use Feature-first Clean Architecture.

```text
lib/
  main.dart
  app.dart

  core/
    config/
    constants/
    data/
    errors/
    extensions/
    localization/
    responsive/
    routing/
    theme/
    utils/
    validators/
    widgets/

  shared/
    entities/
    models/
    services/
    cubits/

  features/
    audit/
      data/
      domain/
      presentation/

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

    settings/
      data/
      domain/
      presentation/
```

---

# 9. Feature Structure Rule

Each feature must follow this structure:

```text
feature_name/
  domain/
    entities/
    repositories/
    usecases/
    policies/

  data/
    constants/
    models/
    mappers/
    datasources/
    repositories/

  presentation/
    cubit/
    pages/
    dialogs/
    widgets/
    localization/
    helpers/
```

Example for Trips:

```text
features/trips/
  domain/
    entities/
      trip_entity.dart
      trip_status.dart
      trip_status_history.dart
      trip_write_data.dart
    repositories/
      trips_repository.dart
    usecases/
      create_trip_usecase.dart
      get_trips_usecase.dart
      get_trip_details_usecase.dart
      update_trip_status_usecase.dart
      calculate_trip_net_profit_usecase.dart

  data/
    models/
      trip_model.dart
      trip_status_history_model.dart
    mappers/
      trip_mapper.dart
    datasources/
      trips_remote_data_source.dart
    repositories/
      trips_repository_impl.dart

  presentation/
    cubit/
      trips_cubit.dart
      trips_state.dart
    pages/
      trips_page.dart
    widgets/
      trip_form_dialog.dart
      trips_filters.dart
      trips_list.dart
      trip_details_dialog.dart
      trip_activity_timeline_item.dart
```

Example for Expenses:

```text
features/expenses/
  domain/
    entities/
      trip_expense.dart
      trip_expense_paid_by.dart
      trip_expense_write_data.dart
      expense_type_option.dart
    repositories/
      trip_expenses_repository.dart
    usecases/
      trip_expenses_usecases.dart
    policies/
      trip_expenses_permission_policy.dart

  data/
    models/
      trip_expense_model.dart
    mappers/
      trip_expense_mapper.dart
    datasources/
      trip_expenses_remote_data_source.dart
    repositories/
      trip_expense_repo_impl.dart
```

---

# 10. Dependency Rule

Allowed dependencies:

```text
Presentation depends on Domain
Data depends on Domain
Data implements Domain abstractions
Domain depends on nothing external
```

Forbidden:

* Domain importing Flutter
* Domain importing Supabase
* Domain importing Cubit or Bloc
* Domain importing UI
* Domain importing JSON/database implementation details
* Cubit calling Supabase directly
* UI calculating business rules
* Widgets containing database queries
* Data models replacing Domain entities everywhere
* Feature accessing another feature data source directly

---

# 11. Localization Rules

Localization-first is mandatory.

Rules:

* No user-facing hardcoded strings in UI.
* Every new label, button, empty state, validation error, failure message, filter label, and audit/action label must support EN/AR.
* DB canonical values may stay stable in English when needed, but UI must localize their display names.
* Custom user-entered values must not be force-translated.
* Any manually added fallback UI string is not allowed unless it is localized and temporary by design.

---

# 12. Audit and Accountability Rules

Audit/accountability is app-wide, structured, reusable, and company-scoped.

Rules:

* Important business actions must leave audit records.
* Audit rows must include `company_id`.
* Audit writes must not happen from UI widgets.
* Audit writes must not happen from Cubits.
* Audit writes should happen through repository/data layer or approved use case pattern.
* Cubits and UI must not call Supabase directly.
* Every module with create/update/deactivate/reactivate/status-change actions must expose accountability in the UI, not only in the database.

Details dialog pattern:

* Basic information section.
* Accountability section.
* Activity timeline section.
* Table/list action uses View Details with `AppIcons.view`.
* `AppIcons.auditHistory` appears inside timeline items only.
* Dialogs that need Cubit state must use `BlocProvider.value` or the established safe pattern.

---

# 13. GitHub Issue Status

## Completed / Closed as Completed

* Issue #14 - Drivers module.
* Issue #15 - Fleet Module.
* Issue #16 - Routes Module.
* Issue #18 - Implement trips domain foundation.
* Issue #19 - Implement trips data layer.
* Issue #20 - Implement trips presentation layer.
* Issue #21 - Implement trip status history.
* Issue #22 - Implement trip expenses module.
* Issue #23 - Implement trip net profit calculation.
* Issue #33 - README project overview.
* Issue #34 - Contribution and code rules document.
* Issue #35 - Testing strategy document.
* Issue #39 - Responsive UI polish for Customers module.

## Closed as Superseded / Not Planned

* Issue #17 - Implement expense types and payment methods settings.
  * Superseded by Issue #45 for expense types and Issue #46 for payment methods.

## Open - Next Business Implementation

* Issue #24 - Implement driver advances and deductions foundation.
* Issue #25 - Implement invoices domain foundation.
* Issue #26 - Implement invoices data and presentation.
* Issue #27 - Implement payments module.
* Issue #28 - Implement customer statement foundation.
* Issue #29 - Implement dashboard foundation.
* Issue #30 - Implement basic reports.
* Issue #31 - Implement subscription plans placeholder.
* Issue #32 - Implement plan limit checks foundation.

## Open - Deferred / Backlog

* Issue #37 - Add company timezone support.
* Issue #45 - Settings: Manage expense types master data.
* Issue #46 - Settings: Manage payment methods master data.

---

# 14. MVP Definition

The MVP is successful when one company can:

* Create an account.
* Create or access a company workspace.
* Add customers.
* Add drivers.
* Add tractor heads.
* Add trailers.
* Add routes.
* Create trips.
* Assign customer, route, driver, tractor head, and trailer.
* Update trip status.
* View trip status history.
* Register trip expenses.
* Calculate trip net profit.
* Create invoices.
* Register payments.
* View dashboard.
* View basic reports.

---

# 15. Non-MVP Features

The following must not delay the first MVP:

* Driver mobile app.
* GPS tracking.
* WhatsApp automation.
* QR code.
* Customer portal.
* Advanced maintenance.
* Full accounting integration.
* Online subscription payment integration.

---

# 16. Validation Before Closing Any Business Issue

Before closing or merging any business module:

```bash
flutter analyze
flutter test
```

Manual verification is also required:

* Manual smoke test for the full feature flow.
* Supabase schema verification.
* RLS verification.
* Policy verification.
* GRANT verification.
* Enum verification where applicable.
* Trigger verification where applicable.
* Seed data verification where applicable.
* Audit write verification.
* Accountability UI verification.
* Localization EN/AR verification.
* Acceptance criteria review against the GitHub issue and this roadmap.

Analyze/test passing alone is not enough to close a module.

---

# 17. Critical Project Rule

H.O.R.U.S System must always be treated as:

```text
SaaS + Multi-Tenant + Responsive/Adaptive + Clean Architecture by the book + SOLID Principles
```

This rule must be respected in every architecture, roadmap, code structure, database, and implementation discussion.
