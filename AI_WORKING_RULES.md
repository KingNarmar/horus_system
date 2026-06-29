# AI Working Rules

These rules are mandatory for any AI-assisted work on H.O.R.U.S System.

## 1. Project Architecture Rules

- Follow Clean Architecture by the book.
- Follow SOLID principles.
- Use feature-first structure.
- Respect the Dependency Rule:

```text
Presentation -> Domain <- Data
```

## 2. Domain Layer Rules

The Domain layer must remain pure.

Domain must not depend on:

- Flutter
- Supabase
- Cubit
- Bloc
- UI
- JSON
- HTTP
- Database tables
- External services
- Data models
- Data sources

Domain may contain:

- Entities
- Repository abstractions
- Use cases
- Domain policies
- Value objects
- Domain validation rules

## 3. Presentation Rules

- UI must not call Supabase directly.
- Cubit must not call Supabase directly.
- UI and Cubit must call Use Cases only.
- No business rules should be written directly inside widgets.
- UI must remain localization-first.
- No hardcoded user-facing English text in UI.

## 4. Data Layer Rules

- Supabase access belongs in Data sources only.
- Models, mappers, and database serialization belong in Data.
- Data implementations must depend on Domain abstractions.
- No business authorization should rely only on Data layer checks.

## 5. Security and Multi-Tenant Rules

- Every business table must be company-scoped when applicable.
- `company_id` must be enforced consistently.
- RLS is mandatory for company-owned data.
- Security must be enforced in the database, not only in UI, Cubit, or Domain.
- Role-based restrictions must be verified against policies and grants.

## 6. Audit Rules

- Audit is an app-wide foundation.
- Important create/update/deactivate/reactivate financial and master-data actions must write audit logs.
- Audit descriptions and display values must use semantic keys where possible.
- Avoid relying on hardcoded English text for audit behavior.
- Legacy audit compatibility must be preserved when changing audit keys.

## 7. Supabase Workflow Rules

For any Supabase-related task:

- Send one SQL verification query/block at a time.
- Wait for Mina's result before sending the next query.
- Do not send multiple unrelated SQL checks in the same response.
- Verify schema before changing schema.
- Verify enum values before using enum values.
- Verify RLS policies before changing policies.
- Verify grants before and after grant changes.
- Verify triggers/functions when they are part of the change.
- Any live database change must be saved as a migration in the repository.
- No live-only Supabase changes are allowed.

## 8. Code Change Rules

- Use minimal diffs.
- Do not reformat unrelated files.
- Do not rename or restructure unless required by the issue.
- Do not mix cleanup, refactor, and feature work unless explicitly approved.
- Do not create temporary files in the repo.
- Remove accidental files before committing.
- Prefer small focused PRs.

## 9. Verification Rules

Before closing or merging a PR:

- Run `dart format` on changed Dart files.
- Run `flutter analyze`.
- Run `flutter test`.
- For DB work, verify Supabase schema/RLS/grants after applying the migration.
- Confirm changed files match the intended scope.
- Confirm no unrelated files are included.

## 10. Merge Rules

- Do not merge before verification is complete.
- Use squash merge when branch history contains temporary fixes, reverted mistakes, or conflict cleanup.
- The final `main` history must contain the clean final result.
- Document important verification results in the PR description.

## 11. Stop Rule

If Mina says:

```text
قف. بروتوكول.
```

Stop immediately, reset to these rules, and do not continue implementation until the next explicit instruction.
