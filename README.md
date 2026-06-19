# H.O.R.U.S System

**Heavy Operations & Route Unified System**

H.O.R.U.S System is a SaaS multi-tenant platform for managing heavy transport operations.

The first business target is cement and heavy transport companies that operate tractor heads, trailers, drivers, customers, routes, trips, expenses, invoices, payments, and reports across multiple locations.

---

## Product Vision

H.O.R.U.S System is designed to manage the full operational and financial cycle of heavy transport companies from one unified platform.

The long-term product vision includes:

- Company onboarding and multi-company access.
- Role-based access control.
- Customers management.
- Drivers management.
- Fleet management for tractor heads and trailers.
- Routes management.
- Trips lifecycle management.
- Trip status tracking.
- Trip expenses.
- Driver advances and deductions.
- Invoices and payments.
- Customer statements.
- Dashboards and operational reports.
- Subscription and plan-limit foundations.

The product must be sellable to multiple companies using subscription plans.

---

## Core Project Rule

H.O.R.U.S System must always be treated as:

```text
SaaS + Multi-Tenant + Responsive/Adaptive + Clean Architecture by the book + SOLID Principles
```

This is not optional.

Any implementation that violates the architecture contract must be refactored before being accepted.

---

## Architecture

The project follows **Clean Architecture by the book**.

Correct dependency direction:

```text
Presentation → Domain ← Data
```

Layer responsibilities:

- **Domain**: pure business rules, entities, repository abstractions, policies, and use cases.
- **Data**: Supabase data sources, models, mappers, repository implementations, and database constants.
- **Presentation**: Flutter UI, Cubits, pages, widgets, dialogs, filters, cards, tables, and localization helpers.

The Domain Layer must not depend on:

- Flutter.
- Supabase.
- Cubit / Bloc.
- UI.
- JSON.
- HTTP.
- Database tables.
- SQL or RLS details.
- External services.
- Data models.
- Data sources.

Supabase must stay in the Data layer and DI wiring only. It must never be called directly from UI widgets, pages, dialogs, or Cubits.

---

## SOLID Principles

All production code must follow SOLID principles:

- Single Responsibility Principle.
- Open / Closed Principle.
- Liskov Substitution Principle.
- Interface Segregation Principle.
- Dependency Inversion Principle.

No business logic should be written directly inside UI widgets.

---

## SaaS and Multi-Tenant Concept

H.O.R.U.S System is not a single-company custom app.

Every company-owned operational table must include:

```text
company_id
```

Tenant isolation must be enforced at database level using Supabase Row Level Security.

Application-level filtering is not enough.

Company-owned queries and mutations must be company-scoped, and role permissions must be enforced consistently through Domain policies and RLS policies where applicable.

---

## Technology Stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter |
| Backend | Supabase |
| Database | PostgreSQL |
| Auth | Supabase Auth |
| State Management | Cubit / Bloc |
| Architecture | Feature-first Clean Architecture |
| Platforms | Desktop, Tablet, Mobile |

---

## Current Project Status

The project is in active foundation and early feature implementation.

Completed or established foundations:

- Flutter project foundation.
- Feature-first Clean Architecture structure.
- Responsive/adaptive UI foundations.
- Supabase configuration in Data/DI only.
- Authentication and company context foundations.
- Multi-tenant company-scoped access rules.
- Customers module foundation.
- Drivers module foundation.
- App-wide audit/accountability foundation.
- Contribution and code rules document.
- Testing strategy document.

Recently completed focus areas:

- Customers responsive polish.
- Drivers status represented as a Domain value.
- Button-level loading state for customer and driver status actions.
- Contribution/code rules documentation.
- Testing strategy documentation.

Next planned roadmap areas:

- Fleet module.
- Routes module.
- Expense types and payment methods.
- Trips Domain, Data, and Presentation.
- Trip status history.
- Trip expenses and net profit.
- Driver advances and deductions.
- Invoices and payments.
- Customer statement.
- Dashboard and reports.
- Subscription and plan-limit placeholders.

---

## Documentation

| Document | Purpose |
| --- | --- |
| `PROJECT_ROADMAP.md` | Product roadmap, project rules, and implementation phases |
| `CONTRIBUTING.md` | Contribution rules, architecture rules, branch naming, commit style, and PR checklist |
| `TESTING.md` | Testing strategy, testing priorities, and verification commands |
| `docs/database/DATABASE_SCHEMA_V1.sql` | Initial database schema |
| `docs/architecture/ARCHITECTURE_GUIDELINES.md` | Architecture guidelines and forbidden shortcuts |
| `docs/github/GITHUB_ISSUES.md` | Planned GitHub issues and milestones |
| `docs/setup/DEVELOPMENT_SETUP.md` | Development environment setup |

---

## Important Development Rules

The following are forbidden:

- Supabase queries inside Widgets, Pages, Dialogs, or Cubits.
- Business calculations inside UI.
- Domain importing Flutter.
- Domain importing Supabase.
- Domain importing Cubit / Bloc.
- Domain importing UI.
- Domain importing JSON, database details, HTTP, Data models, or Data sources.
- Models replacing Entities everywhere.
- Feature accessing another feature Data Source directly.
- Hardcoding `company_id` in UI.
- Relying only on frontend filtering for tenant isolation.
- User-facing hardcoded strings in UI.
- Temporary fixes, unrelated changes, or over-engineering.

---

## Localization

H.O.R.U.S System is localization-first.

Rules:

- No user-facing hardcoded strings in UI.
- English and Arabic must be updated together.
- Labels, buttons, hints, dialogs, snackbars, errors, validation messages, empty states, and audit timeline text must be localizable.
- UI must map typed Failure codes to localized messages.

---

## Audit and Accountability

Audit/accountability is an app-wide foundation.

Rules:

- Audit logs must be structured.
- Audit logs must be company-scoped.
- Audit must use stable module, entity, and action names.
- Audit writes must not happen from UI widgets or Cubits.
- Domain must not know audit persistence details.
- Data repositories may coordinate audit writes after successful mutations.

---

## Verification Commands

Run before closing any issue:

```bash
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

---

## Contribution

Before contributing, read:

- `PROJECT_ROADMAP.md`
- `CONTRIBUTING.md`
- `TESTING.md`

Every pull request must preserve Clean Architecture, SOLID principles, tenant isolation, localization, typed failures, audit/accountability rules, and responsive/adaptive behavior.
