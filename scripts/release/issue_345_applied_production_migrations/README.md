# Issue #345 — immutable Production ACL recovery evidence

These three SQL files are exact, unmodified copies of the statements already
applied directly to the existing H.O.R.U.S Production database on 2026-11-01.

| Applied Production migration version | Original Git blob SHA-1 |
| --- | --- |
| `20261101150237` — public function/default ACL repair | `d26b7a8c1e11f5a101b55811fe3de52cb528d225` |
| `20261101152235` — table/default ACL repair | `516796baa383c884feab906eba99eac6dfa7954d` |
| `20261101155147` — column ACL restore | `c076e50e4f438c0790c5ddded124d633633233a7` |

The original SQL is preserved here for audit and disaster recovery. **DO NOT
execute it as part of normal Development migrations, local reset, or future
Production deployment.** It expects a specific, previously broken Production
catalog and deliberately fails on an already-correct Development database.

The correspondingly named files under `supabase/migrations/` retain the
same three migration versions so that the CLI's version-based migration
history can remain compatible. Their new bodies perform **read-only,
fail-closed baseline assertions**, not the historical Production repairs:

- The original Development baseline already has the expected function ACLs,
  table grants, column grants and RLS settings.
- Production already records these three versions as applied, so it must
  never attempt them again.
- A fresh environment built from the intended Development migration baseline
  may record these versions only after the assertions pass.
- If an environment differs, the assertion must fail rather than silently
  change permissions. Resolve the upstream schema/migration discrepancy
  under a separately reviewed migration; never bypass the check.

**Provenance caveat:** the SQL bodies stored at the three canonical version
paths are now intentionally different from the statements that were previously
executed on Production. This is explicitly documented rather than hidden:
the byte-exact historic bodies live in this archive, and this README preserves
their original Git blob SHA identifiers. Migration version identifiers are
maintained, but they alone do not attest that identical SQL ran on every
environment.

Validation required before merging PR #346:
1. Read-only confirm target ACL/RLS fingerprints in Development and Production.
2. Validate the three verification-only SQL files on a disposable local
   Development-baseline database; confirm no DML/DDL appears in their contents.
3. Check `supabase migration list` for both targets and
   `supabase db push --dry-run` against the intended linked target.
4. Demonstrate a local `supabase db reset` from repository migrations.
   Historic migration-number discrepancies may independently prevent reset;
   do not claim this gate passed without an actual run.

`db push` without `--dry-run`, `migration repair`, destructive cutover
scripts, production writes, and Cron activation are **not authorized** by this
documentation-only reconciliation.

References:
- [Production cutover #345](https://github.com/KingNarmar/horus_system/issues/345)
- [Supabase local development / migration workflow](https://supabase.com/docs/guides/local-development/cli-workflows)
