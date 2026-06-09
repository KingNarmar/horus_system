# Contributing to H.O.R.U.S System

## Project Rule

H.O.R.U.S System must always follow:

```text
SaaS + Multi-Tenant + Responsive/Adaptive + Clean Architecture by the book + SOLID Principles
```

These rules are mandatory.

---

## Architecture Rules

The project follows Clean Architecture by the book.

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
- External SDKs

---

## Feature Structure

Each feature must follow:

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

---

## Forbidden Shortcuts

The following are not allowed:

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

## SOLID Rules

All production code must respect:

- Single Responsibility Principle
- Open / Closed Principle
- Liskov Substitution Principle
- Interface Segregation Principle
- Dependency Inversion Principle

---

## Branch Naming

Recommended branch format:

```text
feature/issue-number-short-description
fix/issue-number-short-description
docs/issue-number-short-description
```

Examples:

```text
feature/1-flutter-project-setup
feature/7-auth-foundation
docs/33-readme-overview
```

---

## Commit Message Style

Recommended format:

```text
<type>: <short description>
```

Examples:

```text
docs: update project README
feat: add auth domain contracts
fix: correct company context loading
refactor: isolate Supabase data source
```

---

## Pull Request Checklist

Before opening or accepting a pull request, verify:

- Domain Layer remains pure.
- Dependencies point inward.
- Cubits call Use Cases only.
- Supabase calls are limited to Data Sources.
- Repository interfaces are defined in Domain.
- Repository implementations are in Data.
- Business rules are inside Use Cases or Domain services.
- Company isolation is respected.
- UI is responsive/adaptive where applicable.
- Code follows SOLID.

---

## Final Rule

If a shortcut makes the application faster today but breaks architecture tomorrow, it must not be used.
