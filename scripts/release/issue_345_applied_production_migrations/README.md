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
history can remain compatible. Their current bodies implement **fail-closed, baseline-aware reconciliation**, not an unconditional replay of the historical Production repairs:

- The original Development baseline already has the expected function ACLs,
  table grants, column grants and RLS settings. Both function and table
  checkpoints detect the exact expected baseline and make **no mutations**.
- Production already records these three versions as applied, so it must
  never attempt them again.
- A fresh CLI environment that replays the historical migrations may start
  with **broader, explicitly fingerprinted function/table ACLs**. The first
  checkpoint accepts only the observed known function-grant preimage, then
  executes the reviewed, narrow EXECUTE/default-privilege grants and verifies
  the exact per-function ACL fingerprint. The second checkpoint accepts only
  the known table-ACL preimage and restores the canonical table grants and
  corresponding 56 column ACLs **inside the same atomic DO block**, verified
  by table and column fingerprints. The third checkpoint remains read-only
  and checks RLS, table and column grants.
- Any unexpected catalogue/preimage fails closed. No user/auth data, RLS
  policies, company business data, or Storage/Realtime objects are mutated.
  Never bypass a failing ACL fingerprint to force migration replay.

**Provenance caveat:** the SQL bodies stored at the three canonical version
paths are now intentionally different from the statements that were previously
executed on Production. This is explicitly documented rather than hidden:
the byte-exact historic bodies live in this archive, and this README preserves
their original Git blob SHA identifiers. Migration version identifiers are
maintained, but they alone do not attest that identical SQL ran on every
environment.

Validation required before merging PR #346:
1. Read-only confirm target ACL/RLS fingerprints in Development and Production.
2. Verify that the function and table repair branches run **only** on
   known fresh-replay ACL fingerprints, and do nothing on existing Dev/Prod.
   Confirm exact post-repair ACL digests and zero unexpected anonymous execute.
3. Check `supabase migration list` for both targets and
   `supabase db push --dry-run` against the intended linked target.
4. Demonstrate `supabase start` and `supabase db reset --local --no-seed`
   in an isolated GitHub Actions Supabase stack. Do not claim PASS until both
   complete and the three embedded ACL/RLS checks pass.

`db push` without `--dry-run`, `migration repair`, destructive cutover
scripts, production writes, and Cron activation are **not authorized** by this
documentation-only reconciliation.

References:
- [Production cutover #345](https://github.com/KingNarmar/horus_system/issues/345)
- [Supabase local development / migration workflow](https://supabase.com/docs/guides/local-development/cli-workflows)
