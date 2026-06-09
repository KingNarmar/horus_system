# H.O.R.U.S System — Architecture Guidelines

## Project Identity

**H.O.R.U.S System**

**Heavy Operations & Route Unified System**

H.O.R.U.S System is a SaaS multi-tenant platform for managing heavy transport operations, routes, fleet, trip expenses, invoices, payments, reports, and subscriptions.

This document defines the architecture rules that must be followed across the whole project.

---

# 1. Critical Architecture Contract

H.O.R.U.S System must always be treated as:

```text
SaaS + Multi-Tenant + Responsive/Adaptive + Clean Architecture by the book + SOLID Principles
```

These are not optional preferences.

They are project rules.

Any implementation that violates these rules must be refactored before being accepted.

---

# 2. Clean Architecture by the Book

The project must strictly follow Clean Architecture as a real architectural discipline, not just as folder names.

The most important rule is the **Dependency Rule**:

```text
Source code dependencies must point inward only.
```

The Domain Layer is the core of the system.

Outer layers may depend on inner layers, but inner layers must never depend on outer layers.

Correct dependency direction:

```text
Presentation → Domain ← Data
```

Forbidden dependency direction:

```text
Domain → Data
Domain → Presentation
Domain → Flutter
Domain → Supabase
```

---

# 3. Layers

## 3.1 Domain Layer

The Domain Layer contains the pure business rules of H.O.R.U.S System.

It must not know anything about Flutter, Supabase, Cubit, JSON, HTTP, UI, or database tables.

Allowed inside Domain:

- Entities
- Repository abstractions
- Use cases
- Value objects when needed
- Domain failures
- Domain validation rules
- Business rules

Forbidden inside Domain:

- Flutter imports
- Supabase imports
- HTTP clients
- JSON serialization
- Database table names
- UI logic
- Cubit or Bloc
- BuildContext
- Widgets
- External SDKs

Example allowed Domain dependency:

```dart
abstract class TripsRepository {
  Future<Either<Failure, TripEntity>> createTrip(CreateTripParams params);
}
```

Example forbidden Domain dependency:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
```

---

## 3.2 Data Layer

The Data Layer is responsible for external data access and persistence.

It may know about:

- Supabase
- PostgreSQL persistence shape
- JSON
- Remote data sources
- Models
- Mappers
- Repository implementations

The Data Layer must implement repository abstractions defined in the Domain Layer.

Allowed inside Data:

- Models
- Mappers
- Remote data sources
- Local data sources later if needed
- Repository implementations
- Supabase queries
- DTO parsing

Forbidden inside Data:

- UI widgets
- Cubit state
- Screen navigation
- Business decisions that belong to Use Cases

Example:

```text
TripsRepositoryImpl implements TripsRepository
```

---

## 3.3 Presentation Layer

The Presentation Layer is responsible for UI and user interaction.

It may contain:

- Pages
- Widgets
- Cubits
- States
- UI models / view models when needed
- Form controllers
- Responsive/adaptive layouts

The Presentation Layer must call Use Cases.

It must not directly call Supabase.

Forbidden inside Presentation:

- Supabase queries
- Direct database table access
- Heavy business calculations
- Financial rules
- Trip closing rules
- Driver settlement rules
- Invoice calculation rules

Example allowed flow:

```text
AddTripPage
↓
TripsCubit
↓
CreateTripUseCase
↓
TripsRepository
↓
TripsRepositoryImpl
↓
TripsRemoteDataSource
↓
Supabase
```

---

# 4. SOLID Principles

All production code must follow SOLID principles.

## 4.1 Single Responsibility Principle

Each class must have one clear reason to change.

Examples:

- A Cubit manages UI state only.
- A Use Case executes one business action.
- A Repository defines a data access contract.
- A Data Source talks to Supabase.
- A Mapper converts between Model and Entity.

Forbidden:

- A Cubit that performs Supabase queries, calculates profit, validates invoices, and controls navigation.
- A Widget that contains database queries or business rules.

---

## 4.2 Open / Closed Principle

The system should be open for extension and closed for modification.

Examples:

- Adding a new expense type should not require changing trip calculation code everywhere.
- Adding a new payment method should not break existing payment logic.
- Adding new subscription plan rules should be isolated.

---

## 4.3 Liskov Substitution Principle

Any implementation must be replaceable by another implementation of the same abstraction without breaking the system.

Examples:

- SupabaseTripsRepositoryImpl can later be replaced by MockTripsRepository in tests.
- Remote data source can later be replaced or supported by local offline storage without changing Domain use cases.

---

## 4.4 Interface Segregation Principle

Do not create large interfaces that force implementations to depend on unused methods.

Bad example:

```dart
abstract class CompanyRepository {
  Future<void> addCustomer();
  Future<void> createTrip();
  Future<void> createInvoice();
  Future<void> registerPayment();
  Future<void> updateSubscription();
}
```

Good example:

```dart
abstract class CustomersRepository {}
abstract class TripsRepository {}
abstract class InvoicesRepository {}
abstract class SubscriptionsRepository {}
```

---

## 4.5 Dependency Inversion Principle

High-level business rules must not depend on low-level external details.

Use Cases depend on repository abstractions, not implementations.

Bad:

```dart
class CreateTripUseCase {
  final SupabaseClient client;
}
```

Good:

```dart
class CreateTripUseCase {
  final TripsRepository repository;

  CreateTripUseCase(this.repository);
}
```

---

# 5. Feature-First Clean Architecture

The project must use feature-first structure.

Each business feature owns its Data, Domain, and Presentation layers.

Required feature structure:

```text
features/
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

# 6. Core Folder

The `core/` folder is for shared infrastructure and cross-cutting concerns.

Allowed inside `core/`:

- App configuration
- Constants
- Errors
- Failures
- Routing
- Theme
- Validators
- Extensions
- Base use case classes
- Shared widgets
- Network helpers
- Dependency injection setup

Forbidden inside `core/`:

- Feature-specific business rules
- Feature-specific Supabase queries
- Feature-specific UI pages

---

# 7. Shared Folder

The `shared/` folder may contain reusable elements used by several features.

Allowed:

- Shared entities when truly cross-feature
- Shared UI components
- Shared cubits only when globally required
- Shared services that are not feature-specific

Rule:

Do not put something in `shared/` just because it is convenient.

Prefer feature ownership first.

---

# 8. State Management Rules

Cubit / Bloc is used for state management.

Cubit responsibilities:

- Receive UI events
- Call Use Cases
- Emit states
- Handle loading, success, and failure states

Cubit must not:

- Query Supabase directly
- Contain SQL or table names
- Calculate financial business rules
- Know persistence details
- Contain large validation rules that belong in Domain

---

# 9. Use Case Rules

Each important business action must be represented by a Use Case.

Examples:

- CreateCompanyUseCase
- GetCurrentCompanyUseCase
- AddCustomerUseCase
- CreateTripUseCase
- UpdateTripStatusUseCase
- CalculateTripNetProfitUseCase
- CreateInvoiceFromTripsUseCase
- RegisterPaymentUseCase
- GetCustomerStatementUseCase

Use Cases should be small and focused.

A Use Case must not know whether data comes from Supabase, local storage, or any other source.

---

# 10. Entity, Model, and Mapper Rules

## Entity

Entity belongs to Domain.

It represents business meaning.

It must be independent from JSON and database shape.

## Model

Model belongs to Data.

It represents external data shape.

It may contain:

- fromJson
- toJson
- Supabase column mapping

## Mapper

Mapper belongs to Data.

It converts:

```text
Model ↔ Entity
```

Rule:

UI should not depend directly on Supabase models when a Domain Entity is required.

---

# 11. SaaS Multi-Tenant Rules

H.O.R.U.S System is SaaS from day one.

Every operational table must include:

```text
company_id
```

Company isolation must be enforced by:

- Database Row Level Security
- Company-aware repositories
- Current company context in the application

Application-level filtering alone is not enough.

Any query that reads or writes company data must be scoped to the current company.

---

# 12. Supabase Rules

Supabase is an external detail.

Supabase belongs in the Data Layer only.

Allowed:

```text
data/datasources/*_remote_datasource.dart
```

Forbidden:

```text
domain/
presentation/
widgets/
cubit/
```

No Supabase call should appear inside Cubits or Widgets.

---

# 13. Responsive and Adaptive UI Rules

The app must support:

- Desktop
- Tablet
- Mobile

The business logic must stay the same across all platforms.

Only the layout should change.

Desktop should use:

- Sidebar
- Wide tables
- Advanced filters
- Multi-column forms

Tablet should use:

- Navigation rail
- Simplified tables
- Cards where needed

Mobile should use:

- Bottom navigation
- Cards instead of large tables
- Short forms
- Quick actions

Do not duplicate business logic for different screen sizes.

---

# 14. Validation Rules

Validation has levels.

## UI validation

Simple user input validation:

- Required field
- Min length
- Basic format

## Domain validation

Business rules:

- Trip cannot be closed without required data.
- Trip expense must be positive.
- Invoice cannot be paid if cancelled.
- Driver settlement must follow business rules.

## Database validation

Final protection:

- NOT NULL
- CHECK constraints
- Foreign keys
- Unique constraints
- RLS policies

---

# 15. Error and Failure Handling

Domain should expose failures, not raw exceptions.

Examples:

- ServerFailure
- ValidationFailure
- PermissionFailure
- NotFoundFailure
- SubscriptionLimitFailure

Data Layer catches external exceptions and maps them to Domain failures.

Presentation displays user-friendly messages.

---

# 16. Forbidden Shortcuts

The following are not allowed:

- Supabase queries inside Widgets
- Supabase queries inside Cubits
- Business calculations inside UI
- Domain importing Flutter
- Domain importing Supabase
- Models replacing Entities everywhere
- Large god repositories
- Large god Cubits
- Large god widgets
- Feature accessing another feature Data Source directly
- Hardcoding company_id in UI
- Relying only on frontend filtering for tenant isolation

---

# 17. Code Review Checklist

Before accepting any feature, verify:

- Does the Domain Layer remain pure?
- Are dependencies pointing inward?
- Does the Cubit call Use Cases instead of Data Sources?
- Are Supabase calls limited to Data Sources?
- Are repository interfaces defined in Domain?
- Are repository implementations in Data?
- Are business rules inside Use Cases or Domain services?
- Is company_id handled safely?
- Is RLS respected?
- Is the UI responsive/adaptive?
- Does the code follow SOLID?

---

# 18. Initial Feature Priority

The first implementation should focus on:

1. Authentication
2. Company onboarding
3. Current company context
4. Users and roles
5. Responsive/adaptive app shell
6. Customers
7. Drivers
8. Fleet
9. Routes
10. Trips
11. Trip expenses
12. Invoices and payments
13. Dashboard and reports

---

# 19. Final Rule

If a shortcut makes the application faster today but breaks Clean Architecture, SOLID, or tenant isolation tomorrow, it must not be used.

H.O.R.U.S System must be built as a long-term SaaS product, not as a quick custom application.
