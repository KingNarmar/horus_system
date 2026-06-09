# H.O.R.U.S System

**Heavy Operations & Route Unified System**

H.O.R.U.S System is a SaaS multi-tenant platform for managing heavy transport operations.

The first real business case targets cement transport companies operating tractor heads and trailers between governorates.

---

## Product Vision

H.O.R.U.S System is designed to manage the full operational and financial cycle of heavy transport companies:

- Companies
- Users and roles
- Customers
- Drivers
- Tractor heads
- Trailers
- Routes
- Trips
- Trip expenses
- Driver settlements
- Invoices
- Payments
- Reports
- Subscriptions

The product must be sellable to multiple companies using monthly subscription plans.

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

The most important rule is the Dependency Rule:

```text
Source code dependencies must point inward only.
```

Correct dependency direction:

```text
Presentation → Domain ← Data
```

The Domain Layer must not depend on:

- Flutter
- Supabase
- Cubit
- UI
- JSON
- HTTP
- Database tables
- External services

---

## SOLID Principles

All production code must follow SOLID principles:

- Single Responsibility Principle
- Open / Closed Principle
- Liskov Substitution Principle
- Interface Segregation Principle
- Dependency Inversion Principle

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

## Documentation

| Document | Purpose |
| --- | --- |
| `PROJECT_ROADMAP.md` | Product roadmap and implementation phases |
| `docs/database/DATABASE_SCHEMA_V1.sql` | Initial database schema |
| `docs/architecture/ARCHITECTURE_GUIDELINES.md` | Architecture rules and forbidden shortcuts |
| `docs/github/GITHUB_ISSUES.md` | Planned GitHub issues and milestones |
| `docs/setup/DEVELOPMENT_SETUP.md` | Development environment setup |
| `CONTRIBUTING.md` | Contribution and code rules |

---

## Initial Execution Order

1. Setup Flutter project.
2. Create Clean Architecture folder structure.
3. Add base architectural contracts.
4. Configure theme and responsive foundations.
5. Validate database schema.
6. Configure Supabase in Data Layer only.
7. Implement authentication foundation.
8. Implement company onboarding.
9. Implement current company context.
10. Implement responsive/adaptive app shell.

---

## Important Restrictions

The following are forbidden:

- Supabase queries inside Widgets
- Supabase queries inside Cubits
- Business calculations inside UI
- Domain importing Flutter
- Domain importing Supabase
- Models replacing Entities everywhere
- Feature accessing another feature Data Source directly
- Hardcoding `company_id` in UI
- Relying only on frontend filtering for tenant isolation

---

## Current Status

Project foundation is in progress.

Completed foundation items:

- Project roadmap
- Database schema v1
- Architecture guidelines
- GitHub issues execution plan
- Initial GitHub issues

Next step:

```text
Issue #1 — Setup Flutter project for H.O.R.U.S System
```
