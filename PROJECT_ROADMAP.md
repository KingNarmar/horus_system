# H.O.R.U.S System — Project Roadmap

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

Last updated: 2026-06-19

The project has completed the core foundation and most of the required master-data foundation before Trips.

Completed foundations include:

* Clean Architecture project structure
* SaaS multi-tenant company scoping
* Supabase RLS foundation
* Authentication and current company context foundation
* Customers module
* Drivers module
* Audit & Accountability foundation
* Fleet module for tractor heads and trailers

Recently completed:

* Issue #15 — Fleet Module was completed and closed.
* PR #41 — Fleet module foundation was merged.
* PR #42 — Fleet schema/RLS guard migration was merged.
* PR #43 — Tightened Fleet authenticated grants was merged.

Current phase:

* The project is currently in **Phase 2 — Master Data**.
* Customers, Drivers, Tractor Heads, and Trailers are done.
* The next primary business module is **Routes**.
* Trips must not start before Routes because trips need loading/unloading routes and default freight prices.

Next planned issue:

* Issue #16 — Routes Module.

Planned Routes scope:

* `routes` table with `company_id`
* RLS and authenticated grants
* Domain entity and repository abstraction
* Data model, mapper, remote data source, repository implementation
* Use cases
* Routes Cubit
* Routes list page
* Add/edit route form
* Active/inactive filtering
* Deactivate/reactivate flow
* Audit logs for create/update/deactivate/reactivate
* Localization keys

Implementation order from here:

1. Routes Module — Issue #16
2. Trips Module
3. Trip Expenses Module
4. Dashboard Foundation
5. Basic Reports
6. Customer Statement
7. Invoices and Payments
8. Subscription placeholders and plan limits
9. Documentation polish: README, contribution rules, testing strategy
10. Responsive UI polish issues

Supabase workflow rule:

* Any Supabase-related change must be handled manually and carefully.
* Send one SQL query at a time.
* Wait for the result before sending the next query.
* Verify schema, RLS, policies, grants, enum values, and audit behavior before closing an issue.

Stop point:

* No new implementation should start until Mina explicitly says to continue.

---

# 1. Core Architecture Decision

H.O.R.U.S System must strictly follow:

## Clean Architecture by the book

The project must respect the Dependency Rule.

Inner layers must not depend on outer layers.

The Domain Layer must not know anything about:

* Flutter
* Supabase
* Cubit
* UI
* JSON
* HTTP
* Database tables
* External services

The correct dependency direction is:

```text
Presentation → Domain ← Data
```

The Domain Layer is the core of the application.

---

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

Supabase

Supabase will be used for:

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

## Core SaaS Rules

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

Initial roles:

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

## Phase 0 — Foundation

Purpose: Prepare the project foundation before building business features.

Deliverables:

* Project roadmap
* Database schema v1
* Flutter project structure
* Supabase setup plan
* Architecture rules
* Initial GitHub issues

---

## Phase 1 — SaaS Foundation

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

Goal:

Before building trips, customers, or invoices, the system must know:

* Who is logged in
* Which company they belong to
* What role they have
* What data they can access

---

## Phase 2 — Master Data

Modules:

* Customers
* Drivers
* Tractor Heads
* Trailers
* Routes
* Expense Types
* Payment Methods

Goal:

Allow each company to prepare its core operational data before creating trips.

---

## Phase 3 — Trip Operations

Modules:

* Trip creation
* Trip list
* Trip details
* Assign driver
* Assign tractor head
* Assign trailer
* Trip status update
* Trip timings
* Loading order number
* Waybill number
* Quantity in tons
* Freight price
* Prevent duplicate open trip for the same vehicle

Goal:

Manage the full trip cycle from loading order to delivery.

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

---

## Phase 4 — Expenses and Driver Settlement

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

Goal:

Track trip cost and calculate operational profitability.

Initial formula:

```text
Trip Net Profit = Freight Price - Total Trip Expenses
```

The formula must be isolated inside a Domain Use Case so it can be changed later without changing UI or Data layers.

---

## Phase 5 — Invoices and Payments

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

---

## Phase 6 — Dashboard and Reports

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

---

## Phase 7 — Subscription and Commercial Layer

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

---

## Phase 8 — Advanced Features

These features are not part of MVP.

* Driver mobile app
* GPS tracking
* WhatsApp notifications
* Customer portal
* Document upload from mobile
* QR code per trip
* Advanced maintenance module
* Accounting system integration
* Payment gateway integration
* Offline mode

---

# 7. Initial Database Tables

The first schema version should include:

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
* payment_methods

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
    errors/
    extensions/
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

  data/
    models/
    mappers/
    datasources/
    repositories/

  presentation/
    cubit/
    pages/
    widgets/
```

Example:

```text
features/trips/
  domain/
    entities/
      trip_entity.dart
    repositories/
      trips_repository.dart
    usecases/
      create_trip_usecase.dart
      get_trips_usecase.dart
      update_trip_status_usecase.dart
      calculate_trip_net_profit_usecase.dart

  data/
    models/
      trip_model.dart
    mappers/
      trip_mapper.dart
    datasources/
      trips_remote_datasource.dart
    repositories/
      trips_repository_impl.dart

  presentation/
    cubit/
      trips_cubit.dart
      trips_state.dart
    pages/
      trips_page.dart
      trip_details_page.dart
      add_edit_trip_page.dart
    widgets/
      trip_form.dart
      trips_table.dart
      trips_mobile_list.dart
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
* Cubit calling Supabase directly
* UI calculating business rules
* Widgets containing database queries
* Data models replacing Domain entities everywhere
* Feature accessing another feature data source directly

---

# 11. First GitHub Issues

## Issue #1

Setup H.O.R.U.S System Flutter project with Clean Architecture structure

## Issue #2

Setup Supabase project and database schema v1

## Issue #3

Implement authentication foundation

## Issue #4

Implement company onboarding and current company context

## Issue #5

Implement users and roles foundation

## Issue #6

Implement responsive/adaptive app shell

## Issue #7

Implement customers module

## Issue #8

Implement drivers module

## Issue #9

Implement fleet module: tractor heads and trailers

## Issue #10

Implement routes module

## Issue #11

Implement trips module

## Issue #12

Implement trip expenses module

## Issue #13

Implement invoices and payments module

## Issue #14

Implement dashboard and basic reports

## Issue #15

Implement subscription plan placeholders

---

# 12. MVP Definition

The MVP is successful when one company can:

* Create an account
* Create or access a company workspace
* Add customers
* Add drivers
* Add tractor heads
* Add trailers
* Add routes
* Create trips
* Assign driver, tractor head, and trailer
* Update trip status
* Register trip expenses
* Calculate trip net profit
* Create invoices
* Register payments
* View dashboard
* View basic reports

---

# 13. Non-MVP Features

The following must not delay the first MVP:

* Driver mobile app
* GPS tracking
* WhatsApp automation
* QR code
* Customer portal
* Advanced maintenance
* Full accounting integration
* Online subscription payment integration

---

# 14. Next Deliverables

After this roadmap, the next files should be prepared in this order:

1. `DATABASE_SCHEMA_V1.sql`
2. `ARCHITECTURE_GUIDELINES.md`
3. `GITHUB_ISSUES.md`
4. Flutter project initialization
5. Supabase project setup
6. Authentication and company context implementation

---

# 15. Critical Project Rule

H.O.R.U.S System must always be treated as:

```text
SaaS + Multi-Tenant + Responsive/Adaptive + Clean Architecture by the book + SOLID Principles
```

This rule must be repeated and respected in every architecture, roadmap, code structure, database, and implementation discussion.
