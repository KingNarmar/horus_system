# Production Database Bootstrap

This document records the database-provisioning contract discovered during Issue #197.

## Why this exists

The original H.O.R.U.S SaaS schema was committed under `docs/database/` before
`supabase/migrations/` became the canonical migration directory.

The development Supabase project therefore contains foundational objects that
were historically applied outside the later migration chain. A brand-new
Supabase project cannot safely start from the former first migration
(`20260610112500_create_customers_table.sql`) because that migration already
expects objects such as `public.companies`, `public.company_users`, and
`public.company_role` to exist.

Issue #197 restores those historical changes into the canonical migration chain.

## Canonical migration history

Fresh environments must run the files in `supabase/migrations/` in filename
order. The restored entries intentionally preserve the original historical SQL
and ordering where evidence exists.

Two previously live-only foundations are also represented explicitly:

- Driver legacy/current name-field alignment and
  `public.sync_driver_name_fields()`.
- The `public.rls_auto_enable()` / `ensure_rls` defense-in-depth guard.

The Issue #270 migration filename is aligned with the version recorded in the
development Supabase migration history:
`20260922192748_issue_270_invoice_draft_trip_reservations.sql`.

## Production provisioning rule

Production must be provisioned from a clean Supabase project using the
repository migration chain.

Do not:

- copy development business data into production;
- treat the development project as production;
- execute historical migration files through a workflow that invents different
  migration versions;
- apply live-only schema fixes;
- place database passwords, service-role keys, or other privileged secrets in
  the Flutter application or repository.

Use a version-preserving Supabase CLI migration workflow for the historical
replay. The repository filename/version is part of the migration contract.

## Existing development project

The development project already contains the restored historical database
changes. The newly restored historical versions therefore represent migration
history reconciliation, not SQL that should be blindly replayed against the
existing development database.

Before a future CLI push to that legacy development project, reconcile its
migration-history metadata using the supported Supabase migration-repair
workflow. Do not rerun the original V1 bootstrap over the populated development
database.

## Required verification after production bootstrap

Issue #197 is not complete when migrations merely apply. Verify, in order:

1. migration history and schema inventory;
2. company ownership / `company_id` invariants;
3. RLS enabled state;
4. policies and role matrices;
5. table/schema/function grants;
6. functions, RPCs, triggers, `SECURITY DEFINER`, and `search_path`;
7. Storage buckets, object policies, and signed-URL behavior;
8. seed/default data for newly created companies;
9. cross-tenant negative tests;
10. role negative tests;
11. audit integrity and anti-forgery behavior;
12. Auth security settings;
13. backup/recovery and retention readiness.

Production configuration must use only the production project URL and
publishable client key in client builds. Privileged server credentials remain
outside the Flutter application.
