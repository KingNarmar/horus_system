# Contributing to H.O.R.U.S System

## Project Rule

H.O.R.U.S System must always follow:

```text
SaaS + Multi-Tenant + Responsive/Adaptive + Clean Architecture by the book + SOLID Principles
```

These rules are mandatory for every feature, fix, refactor, and document update.

---

## Architecture Rules

The project follows Clean Architecture by the book.

Correct dependency direction:

```text
Presentation → Domain ← Data
```

The Domain Layer is the core of the application and must stay pure.

Domain must not depend on:

- Flutter
- Supabase
- Cubit / Bloc
- UI
- JSON
- HTTP
- Database tables
- SQL or RLS details
- External SDKs or services
- Data models
- Data sources

Data implements abstractions defined in Domain.
Presentation depends on Domain through use cases and presentation state.

---

## Feature Structure

Each feature must follow feature-first Clean Architecture:

```text
lib/features/<feature>/
  domain/
    entities/
    policies/
    repositories/
    usecases/

  data/
    constants/
    datasources/
    mappers/
    models/
    repositories/

  presentation/
    cubit/
    localization/
    pages/
    widgets/
```

Use only the folders needed by the feature, but never mix layer responsibilities.

---

## Forbidden Shortcuts

The following are not allowed:

- Supabase queries inside Widgets, Pages, Dialogs, or Cubits.
- Business calculations inside UI.
- Domain importing Flutter, Supabase, Cubit, UI, JSON, DB, HTTP, Data models, or Data sources.
- Models replacing Entities everywhere.
- Feature accessing another feature Data Source directly.
- Hardcoding `company_id` in UI.
- Relying only on frontend filtering for tenant isolation.
- User-facing hardcoded strings in UI.
- Raw backend, Supabase, database, or internal error messages shown directly to users.
- Temporary fixes, unrelated changes, or over-engineering.

---

## SOLID Rules

All production code must respect:

- Single Responsibility Principle
- Open / Closed Principle
- Liskov Substitution Principle
- Interface Segregation Principle
- Dependency Inversion Principle

---

## SaaS and Multi-Tenant Rules

H.O.R.U.S is a SaaS product, not a single-company custom app.

Every company-owned operational table must include:

```text
company_id
```

Rules:

- Each company must only access its own data.
- Company isolation must be enforced at database level using Row Level Security.
- Application-level filtering is not enough.
- New tables must include correct RLS policies and grants.
- Queries and mutations for company-owned data must be scoped by company.
- Role rules must be enforced through Domain policies and database policies when applicable.

---

## Supabase and Database Rules

- Supabase is allowed only in Data layer implementations and DI wiring.
- Supabase must never be used directly in UI or Cubits.
- Database table and column names must stay in Data/Core Data constants, never Domain.
- Domain entities must not expose persistence details.
- Data models and mappers convert database fields into pure Domain entities.

---

## Localization Rules

- Localization-first is mandatory.
- No user-facing hardcoded strings in UI.
- English and Arabic must be updated together.
- Labels, buttons, hints, dialogs, snackbars, errors, empty states, validation messages, and audit timeline text must be localizable.
- UI must map typed Failure codes to localized messages.

---

## Failure Rules

- Use typed Failure classes and stable Failure codes.
- Use cases must return `Result<T>`.
- UI must display localized messages from Failure codes.
- Do not use random user-facing error strings.
- Do not swallow errors silently.

---

## Audit and Accountability Rules

Audit/accountability is app-wide and reusable.

Rules:

- Audit logs must be structured.
- Audit logs must be company-scoped.
- Use stable module, entity, and action names.
- Include meaningful old/new values when applicable.
- Audit writes must not happen from UI widgets or Cubits.
- Domain must not know audit persistence details.
- Data repositories may coordinate audit writes after successful mutations.

---

## UI and State Management Rules

- Cubits orchestrate use cases and presentation state only.
- Cubits must not contain Supabase calls or database logic.
- UI widgets must not contain business rules.
- Large UI must be split into focused pages, widgets, dialogs, helpers, cards, tables, forms, or sections.
- Desktop should use data tables and filters where appropriate.
- Mobile and tablet layouts must remain responsive/adaptive.

---

## Maintainability Rules

- Code must be readable, maintainable, testable, extensible, and scalable.
- File length is a review signal only; it is not a refactoring rule or a quality metric by itself.
- Files approaching or exceeding roughly 400–500 lines should receive an explicit architectural and design review.
- Do not split a file only because it crosses a line-count threshold.
- Refactor when Clean Architecture boundaries, SOLID principles, SRP, cohesion, coupling, complexity, readability, testability, extensibility, duplication, or independent reasons to change show a real maintenance problem.
- A smaller file may still require refactoring when responsibilities are mixed or the design is difficult to test, extend, modify, or maintain.
- A larger file may remain valid when it is cohesive, has one clear responsibility, and remains easy to test, extend, modify, and maintain.
- Avoid duplicated hardcoded constants.
- Shared app-wide code belongs in `core/`.
- Feature-specific code stays in the feature.
- Keep commits small and focused.

---

## Branch Naming

Recommended branch format:

```text
feature/<issue-number>-<short-description>
fix/<issue-number>-<short-description>
refactor/<issue-number>-<short-description>
docs/<issue-number>-<short-description>
test/<issue-number>-<short-description>
```

Examples:

```text
feature/14-drivers-module
fix/39-customers-responsive-polish
docs/34-contribution-rules
```

---

## Commit Message Style

Recommended format:

```text
<type>: <short description>
```

Allowed examples:

```text
feat: add drivers module
fix: prevent duplicate status taps
docs: add contribution rules
refactor: split customer widgets
test: add driver tests
```

Plain imperative messages are also acceptable when they are clear:

```text
Add drivers domain status
Fix customer status action loading
Document contribution rules
```

Each commit should focus on one logical change.

---

## Pull Request Checklist

Before opening or accepting a pull request, verify:

- [ ] `PROJECT_ROADMAP.md` was reviewed.
- [ ] The target issue body and comments were reviewed.
- [ ] The change is scoped to the issue.
- [ ] Domain Layer remains pure.
- [ ] Dependencies point inward.
- [ ] Cubits call Use Cases only.
- [ ] Supabase calls are limited to Data Sources and DI.
- [ ] Repository interfaces are defined in Domain.
- [ ] Repository implementations are in Data.
- [ ] Business rules are inside Use Cases, Domain policies, or Domain services.
- [ ] Company-owned data is scoped by `company_id`.
- [ ] RLS and grants are included when database access changes.
- [ ] User-facing strings are localized in English and Arabic.
- [ ] Typed Failure codes are used and mapped to localized UI messages.
- [ ] Audit is structured, reusable, company-scoped, and not written from UI/Cubits.
- [ ] UI is responsive/adaptive where applicable.
- [ ] Files with significant size or complexity were reviewed for architecture, SRP, cohesion, coupling, testability, extensibility, and maintainability; no split was made solely for line count.
- [ ] No temporary fixes, unrelated changes, or over-engineering were introduced.
- [ ] `dart format` was run when Dart files changed.
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.

---

## Required Verification Commands

Run before closing issues:

```bash
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

For documentation-only changes, `flutter analyze` and `flutter test` should still be run when possible to confirm the branch remains healthy.

---

## Final Rule

If a shortcut makes the application faster today but breaks architecture tomorrow, it must not be used.
