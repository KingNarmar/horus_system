# Issue #5 — Database Schema V1 Review Findings

## Review Scope

Reviewed `docs/database/DATABASE_SCHEMA_V1.sql` for:

- Enums
- Tables
- Indexes
- Updated-at triggers
- RLS helper functions
- RLS policies
- SaaS multi-tenant readiness
- Subscription plan seed data

## Confirmed

- Schema is designed for SaaS multi-tenancy from day one.
- Operational and finance tables include `company_id`.
- Core SaaS tables exist:
  - `user_profiles`
  - `companies`
  - `company_users`
  - `subscription_plans`
  - `company_subscriptions`
- Master data tables exist.
- Operations tables exist.
- Finance tables exist.
- Indexes exist for company-scoped access patterns.
- Updated-at triggers exist for tables with `updated_at`.
- RLS is enabled across the schema.
- RLS helper functions exist:
  - `private.is_platform_admin()`
  - `private.is_company_member(uuid)`
  - `private.has_company_role(uuid, public.company_role[])`
- Subscription plans are seeded:
  - `basic`
  - `pro`
  - `enterprise`

## Finding 1 — Cross-company foreign key integrity needs strengthening

Many company-scoped tables include `company_id`, which is correct.

However, some relationships reference related records by `id` only instead of enforcing `(company_id, id)` consistency.

Example:

- `trips.company_id`
- `trips.customer_id`
- `trips.driver_id`
- `trips.tractor_head_id`
- `trips.trailer_id`
- `trips.route_id`

The current foreign keys confirm that the referenced record exists, but they do not directly confirm that the referenced record belongs to the same company as the trip.

## Risk

A record could theoretically reference another company's related record if the UUID is known and if insert/update policies allow the write path.

RLS protects reads/writes at policy level, but database-level relational integrity should also enforce company consistency.

## Required follow-up migration

Create a follow-up migration to add company-scoped relational integrity.

Recommended approach:

1. Add composite unique constraints on company-scoped parent tables:
   - `customers(company_id, id)`
   - `drivers(company_id, id)`
   - `tractor_heads(company_id, id)`
   - `trailers(company_id, id)`
   - `routes(company_id, id)`
   - `trips(company_id, id)`
   - `invoices(company_id, id)`
   - `payment_methods(company_id, id)`
   - `expense_types(company_id, id)`

2. Add composite foreign keys on child tables so records cannot reference data from another company.

3. Keep RLS policies as the first isolation layer, but reinforce data consistency using database constraints.

## Decision

Issue #5 should not modify the original `DATABASE_SCHEMA_V1.sql`.

Required correction should be documented and implemented in a follow-up migration.
