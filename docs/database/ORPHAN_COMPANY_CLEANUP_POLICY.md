# Orphan Company Cleanup Policy

This policy defines how H.O.R.U.S handles legacy company rows that have no valid active Owner membership.

## Invariant

Every active company must have at least one active Owner membership.

New company onboarding must create the company and its initial Owner membership atomically through the approved server-side command. Flutter must not create either row directly.

## Never Infer Ownership

Do not assign or restore ownership from `companies.created_by` alone.

`created_by` is audit provenance, not proof that the creator is still the intended Owner. Ownership recovery must be an explicit, verified decision.

## Detection

Treat an active company as an orphan candidate when either condition is true:

- it has no `company_users` rows; or
- it has no active `owner` membership.

Detection is only the start of investigation. It must not trigger automatic repair or deletion.

## Required Verification Before Cleanup

For each candidate company, verify independently:

1. company identity, creation time, and creator;
2. all current and historical memberships;
3. active Owner count;
4. audit history;
5. invitations;
6. operational, master-data, financial, settlement, invoice, payment, and trip rows scoped to the company;
7. seeded rows created automatically during company creation;
8. foreign-key delete behavior for every dependent table.

## Cleanup Decision

### Company has business or audit history

Do not delete it automatically.

Escalate for explicit ownership and retention review. Any ownership recovery must use an approved membership/ownership command and must preserve tenant isolation and audit history.

### Development/test company has no memberships and only deterministic seed data

The company may be removed only after the exact row has been explicitly reviewed and approved for cleanup.

The cleanup must be environment-specific and narrowly targeted. Do not add a broad production migration that deletes every company matching an orphan predicate, because legitimate recovery cases could be destroyed.

Seed rows may be removed through verified `ON DELETE CASCADE` foreign keys when the reviewed company row is deleted.

## Production Rule

Production orphan findings are incidents, not routine cleanup candidates.

Do not automatically delete, deactivate, transfer, or assign ownership. First determine how the invariant was violated, preserve evidence, and approve a specific remediation.

## Verification After Cleanup

Re-run the orphan detection query and confirm:

- the reviewed orphan row is gone only when deletion was explicitly approved;
- no unrelated company row changed;
- dependent seed rows were removed as expected;
- no cross-tenant rows were affected;
- all remaining active companies have at least one active Owner.
