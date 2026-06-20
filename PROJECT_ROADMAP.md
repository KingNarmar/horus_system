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

Last updated: 2026-06-20

The project has completed the core SaaS foundation and the required master-data foundation needed before Trips.

Completed foundations include:

* Clean Architecture project structure
* SaaS multi-tenant company scoping
* Supabase RLS foundation
* Authentication and current company context foundation
* Customers module
* Drivers module
* Audit & Accountability foundation
* Fleet module for tractor heads and trailers
* Routes module

Recently completed:

* Issue #15 - Fleet Module was completed and closed.
* PR #41 - Fleet module foundation was merged.
* PR #42 - Fleet schema/RLS guard migration was merged.
* PR #43 - Tightened Fleet authenticated grants was merged.
* Issue #16 - Routes Module was completed and closed.
* PR #44 - Routes module was merged.

Current phase:

* Phase 2 - Master Data is complete for Customers, Drivers, Fleet, and Routes.
* The project is ready to move into Phase 3 - Trip Operations.
* The next primary business module is Trips.
* Trips can now start because Routes are available for loading/unloading route references and default freight prices.

Next planned issues:

* Issue #18 - Implement trips domain foundation.
* Issue #19 - Implement trips data layer.
* Issue #20 - Implement trips presentation layer.
* Issue #21 - Implement trip status history.

Planned Trips scope:

* `trips` table with `company_id`.
* `trip_status_history` table with `company_id`.
* RLS and authenticated grants for Trips tables.
* Pure Domain layer:
  * `TripEntity`.
  * `TripStatus`.
  * `TripStatusHistory`.
  * `TripWriteData` / create params.
  * `UpdateTripStatusParams`.
  * `TripsRepository` abstraction.
  * Use cases for create, list, details, status update, and net profit calculation.
* Data layer:
  * Supabase remote data source.
  * Trip model.
  * Trip status history model.
  * Mappers.
  * Repository implementation.
* Presentation layer:
  * Trips Cubit and State.
  * Trips list page.
  * Add/edit trip form.
  * Trip details dialog/page.
  * Desktop table.
  * Mobile/tablet cards.
  * Search and status filters.
  * Status update action.
* Audit logs for important trip actions:
  * created
  * updated
  * assigned
  * status_changed
  * cancelled
  * completed
* Accountability UI inside Trip Details.
* Activity timeline inside Trip Details.
* Trip status history visible in Trip Details.
* Localization keys in English and Arabic.

Implementation order from here:

1. Trips Domain Foundation - Issue #18
2. Trips Data Layer - Issue #19
3. Trips Presentation Layer - Issue #20
4. Trip Status History - Issue #21
5. Trip Expenses Module - Issue #22
6. Trip Net Profit Calculation - Issue #23
7. Driver Advances and Deductions Foundation - Issue #24
8. Invoices Foundation - Issue #25
9. Invoices Data and Presentation - Issue #26
10. Payments Module - Issue #27
11. Dashboard Foundation - Issue #29
12. Basic Reports - Issue #30
13. Customer Statement
14. Subscription placeholders and plan limits
15. Documentation polish: README, contribution rules, testing strategy
16. Responsive UI polish issues

Supabase workflow rule:

* Any Supabase-related change must be handled manually and carefully.
* Send one SQL verification query at a time.
* Wait for the result before sending the next query.
* Verify schema, RLS, policies, grants, enum values, and audit behavior before closing an issue.

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
* Subscription plan placeholder
* Trial status placeholder
* RLS policies

## Phase 2 - Master Data

Status: Core master-data foundation completed.

Completed:

* Customers
* Drivers
* Tractor Heads
* Trailers
* Routes

Later supporting modules:

* Expense Types
* Payment Methods

## Phase 3 - Trip Operations

Status: Next implementation phase.

Modules:

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

## Phase 4 - Expenses and Driver Settlement

Modules:

* Trip expenses
* Fuel expenses
* Road fees
* Weighbridge fees
* Loading fees
* Unloading fees
* Fines
* Emergency maintenance
* Driver advances
* Driver deductions
* Driver monthly settlement

Initial formula:

```text
Trip Net Profit = Freight Price - Total Trip Expenses
```

The formula must be isolated inside a Domain Use Case so it can be changed later without changing UI or Data layers.

## Phase 5 - Invoices and Payments

Modules:

* Create invoice from trip
* Create grouped invoice for customer
* Invoice status
* Payments
* Partial payments
* Customer account statement
* Unpaid invoices report
* Overdue invoices report

Invoice statuses:

* Draft
* Issued
* Partially Paid
* Paid
* Overdue
* Cancelled

## Phase 6 - Dashboard and Reports

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

Modules:

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

## Phase 8 - Advanced Features

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
* expense_types later
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

# 11. Audit and Accountability Rules

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

# 12. Active GitHub Issues

## Trips

* Issue #18 - Implement trips domain foundation.
* Issue #19 - Implement trips data layer.
* Issue #20 - Implement trips presentation layer.
* Issue #21 - Implement trip status history.
* Issue #22 - Implement trip expenses module.
* Issue #23 - Implement trip net profit calculation.

## Finance and Reports

* Issue #24 - Implement driver advances and deductions foundation.
* Issue #25 - Implement invoices domain foundation.
* Issue #26 - Implement invoices data and presentation.
* Issue #27 - Implement payments module.
* Issue #29 - Implement dashboard foundation.
* Issue #30 - Implement basic reports.

## Platform / Commercial / Polish

* Issue #32 - Implement plan limit checks foundation.
* Issue #37 - Add company timezone support.
* Issue #39 - Responsive UI polish for Customers module.

---

# 13. MVP Definition

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

# 14. Non-MVP Features

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

# 15. Validation Before Closing Any Business Issue

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
* Audit write verification.
* Accountability UI verification.
* Acceptance criteria review against the GitHub issue and this roadmap.

Analyze/test passing alone is not enough to close a module.

---

# 16. Critical Project Rule

H.O.R.U.S System must always be treated as:

```text
SaaS + Multi-Tenant + Responsive/Adaptive + Clean Architecture by the book + SOLID Principles
```

This rule must be respected in every architecture, roadmap, code structure, database, and implementation discussion.
