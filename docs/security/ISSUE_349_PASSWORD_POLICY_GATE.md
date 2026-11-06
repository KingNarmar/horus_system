# Issue #349 — Hosted Auth password policy and release gate

## Single source of truth

**New or reset passwords** must meet both constraints in hosted Supabase Auth:
1. At least **15 Unicode code points** (GoTrue `utf8.RuneCountInString`), with no mandatory character-class composition.
2. At most **72 UTF-8 bytes** (GoTrue `len(password)`); no truncation, trimming, or password transformation.

This is a **provider compatibility constraint**, **not** a claim of full NIST 64-Unicode-character support: 64 ASCII code points fit, but 64 emoji do not. The 72-byte maximum is part of Supabase's existing hosted verifier. Keep any stricter NIST interpretation open for separate architectural/product signoff.

**Sign-in of existing accounts** must never use these creation-time rules.

## Product acceptance — 2026-11-06

The product owner explicitly **accepted the hosted Supabase Auth maximum of 72 UTF-8 bytes** as a documented compatibility exception for this H.O.R.U.S release. The creation/reset contract is therefore:

- **Minimum 15 Unicode code points**, maximum **72 UTF-8 bytes**; no mandatory mixture of character classes.
- Do not trim, truncate, normalize, or otherwise alter passwords. Passwords between 15 and 72 ASCII characters fit; multibyte Unicode passwords may reach the byte limit sooner.
- Existing users may continue to sign in using previously accepted shorter passwords. Apply the new policy to creation/reset only.
- This is **not full support for arbitrary 64-character Unicode passwords** or an assertion of full NIST 64-character guideline conformance; the provider limit is a known exception. Revisit if the hosted provider changes this limit.

**Approval scope:** This product-policy acceptance does **not** authorize merging the [Flutter Draft PR #350](https://github.com/KingNarmar/horus_system/pull/350) or [Website Draft PR #32](https://github.com/KingNarmar/king-narmar-website/pull/32), changing Supabase **Production** Auth settings, deploying the production website/app, or closing [Issue #349](https://github.com/KingNarmar/horus_system/issues/349). These require separate explicit release approval after the remaining manual security/EN-AR checks and rollout/rollback review.

## Architecture and files

- Domain: `lib/features/auth/domain/policies/password_policy.dart` owns validation; `register_usecase.dart` owns registration use case.
- Presentation: `registration_password_validator.dart` maps Domain outcomes to EN/AR localized labels; `register_page.dart` renders only.
- Common Failure mapping: `auth_password_too_short` / `auth_password_too_long`; never expose raw backend errors.
- Website H.O.R.U.S: `src/features/horus-auth/domain/passwordPolicy.ts`, recovery page and EN/AR copy; non-H.O.R.U.S M.I.N.A pages unchanged.
- Data: Supabase SDK stays in Data; hosted GoTrue remains the security boundary.
- No database schema/RLS/grant/migration/audit changes.

## Verification and deployment sequence (not yet approved)

1. **PR CI**: Flutter format, architecture, analyze, full test, Android/Windows builds; website Node policy tests, lint, build.
2. **Preview isolation**: verify whether Cloudflare branch Preview uses Development Supabase before entering any Auth credentials or recovery tokens. Cloudflare previews are auto-published by the connected repository; no production website deployment should occur.
3. **Development hosted Auth**: verify current project Auth minimum/character requirements and any MFA/current-password/secure-change flags. Configure minimum=15 only after explicit approval; this is a hosted Auth setting (not a DB migration) and must be documented in the release operations checklist.
4. **Development auth E2E**: negative 14-code-point password, positive 15 code points, 72-byte positive, 73-byte rejection, 18 vs 19 emoji, wrong/expired recovery link, successful reset and browser sign-out, old short-password sign-in; EN/AR feedback, Windows/Android smoke.
5. **Production gate**: separate approval for hosted Auth settings and deployment sequence, regression QA and rollback plan. Do not auto-merge PRs or change Supabase Production here.

### Sources

- [Supabase Auth verifier source](https://github.com/supabase/auth/blob/master/internal/api/password.go)
- [Supabase Password Security docs](https://supabase.com/docs/guides/auth/password-security)
- [NIST SP 800-63B-4 password verifier guidance](https://pages.nist.gov/800-63-4/sp800-63b.html#password-verifiers)
