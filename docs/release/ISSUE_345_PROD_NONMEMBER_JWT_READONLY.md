# Issue #345 — Production nonmember signed-JWT read-only verification

**Scope:** one narrow H.O.R.U.S release-security evidence gate, **not** a schema change or a public-launch approval. This procedure is intended for the existing Production project `rkhmfbxlduuovlbsxhgy` only.

## Why this test exists

The existing two QA Auth users each belong to both Production QA companies. SQL/RLS catalog evidence does not substitute for demonstrating actual Production GoTrue JWT denial for a user with **zero** company memberships. Two pre-existing private driver-document objects are available for a read-only test. No business or Storage fixture should be created.

## Safety and ownership

- Operator must create **one new disposable Supabase Auth user** with an email inbox they control, via **Supabase Dashboard → project `rkhmfbxlduuovlbsxhgy` → Authentication → Users** (supported Auth Admin UI). Set and confirm a strong password; do not use SQL to insert into `auth.users`. Never invite this user to either QA company or create a company on its behalf.
- Use a **separate existing QA Owner/Admin** identity (currently an authorized member of both QA companies) as a positive control. **Never** use a Platform Admin/service-role key or a live customer's password.
- Both passwords are prompted with hidden terminal input, used only for official GoTrue password login and JWT validation; **never paste credentials, API keys or JWTs into GitHub issues, chat or CI logs**. The script does not save credentials, tokens, object paths, signed URLs or response bodies.
- The verifier sends only: GoTrue login/token validation; PostgREST **GET** against company memberships, Trips, Routes and Audit; secured **read projection** RPCs; Storage **list** and short-lived URL **sign** permission checks; Storage GET whose body is discarded. It performs **no** application data/role update, no Storage upload/deletion, no user creation/deletion, no DB/DDL and no account-deletion Cron changes.
- GoTrue login creates authentication sessions, and the authorized Storage sign control issues a short-lived (60-second) URL **in memory**. These are the only expected server-side authentication/token side effects.
- Storage **signed URLs are bearer-capability links**; an owner-created signed URL is supposed to work for whoever possesses it until expiry. The verifier does **not** test, share or open owner-created signed URLs; it tests whether a *nonmember can mint one independently*.
- Run this script from a trusted local terminal on the operator's machine, **not GitHub Actions**. Do not place Production passwords in shell history, a file or repo secrets.

## Operator procedure — Windows PowerShell / Node.js 22+

1. Confirm this dedicated test Auth account exists and is verified, with **no membership in either company**. If you cannot create it using the official Dashboard Auth UI, stop; do **not** emulate a JWT or write to `auth.users` via SQL.
2. On the reviewed branch, in the repository directory, open PowerShell. Copy the **Production publishable / legacy anon API key** from Supabase project's API Keys screen (never `service_role` or `sb_secret_`). Set it in the **current terminal only** without typing its value into command history:

   ```powershell
   $env:HORUS_PROD_PUBLISHABLE_KEY = Read-Host "Production publishable/anon key"
   node scripts/security/verify_issue_345_production_nonmember_jwt_reads.js --preflight
   ```

3. Confirm the preflight reports the correct locked Production project and no network calls. Then execute:

   ```powershell
   node scripts/security/verify_issue_345_production_nonmember_jwt_reads.js --execute
   ```

4. Enter only the **QA Owner/Admin email** and **separate nonmember email**, then both passwords using the **hidden** prompts. The script discovers existing company, Trip, Route, and private Storage fixture identifiers in memory. It refuses a run with no positive fixture, the wrong project/key, no real GoTrue JWT, an outsider membership, a noninteractive shell or an unauthorized operation.
5. **PASS:** every security assertion passes and the printed summary ends with `0 FAIL`. **BLOCKED/FAIL:** stop and record only the sanitized failed check name; do not print payloads or retry using a privileged key. Neither a SQL-simulated JWT nor an empty-company result alone is sufficient.
6. After evidence is recorded, delete **only the named disposable nonmember Auth user** from the Production Auth Dashboard (confirm the correct user first; no deletion SQL), verify it is gone, and clear the temporary local key:

   ```powershell
   Remove-Item Env:HORUS_PROD_PUBLISHABLE_KEY
   ```

## Covered assertions

- Both accounts are real signed GoTrue JWT sessions and distinct user IDs; operator has two active QA company memberships, outsider has none.
- Outsider cannot list either company's Trips, Routes or Audit events, or call secure Trip/Route record projections with a known real fixture.
- An existing authorized owner can access a real private driver document, but outsider and anonymous sessions cannot download it.
- Authorized account can request a short-lived signed URL; outsider cannot mint its own signed URL for the same private object.
- No private document bytes, passwords, tokens, SQL business-row writes, financial values or file paths are printed/saved.

## Evidence boundary

This is **one bounded signed-JWT nonmember denial test** for Issue #345; it does not certify SMTP delivery/redirects, full backup restore (including Storage bytes), timed account-deletion Cron, iOS signing or all role/tenant write matrices. Source code and GitHub CI static checks alone do **not** constitute a completed Production runtime test. Keep the release master [#191](https://github.com/KingNarmar/horus_system/issues/191) and [#345](https://github.com/KingNarmar/horus_system/issues/345) open until remaining release gates are separately closed.

**Documentation:** [Supabase private bucket access](https://supabase.com/docs/guides/storage/buckets/fundamentals), [Storage private download and signed links](https://supabase.com/docs/guides/storage/serving/downloads).
