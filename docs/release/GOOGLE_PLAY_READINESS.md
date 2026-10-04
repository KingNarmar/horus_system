# H.O.R.U.S Google Play Readiness Evidence

Issue: #199  
Parent: #191  
Status: In progress

This document is the evidence-driven source of truth for Google Play Console
readiness for H.O.R.U.S. It does not replace the final release-candidate gate
tracked by #202.

## Scope and guardrails

This workstream covers Play Console compliance, listing preparation, artifact
verification, testing-track readiness, and submission evidence.

It must not:

- rework the Android production foundation already completed in #192;
- rework privacy/legal/account-deletion foundations already completed in
  #195/#196 unless a verified blocker is found;
- introduce Google Play Billing or production monetization work tracked by
  #207/#208/#209/#32/#210;
- change Production Supabase, schema, RLS, grants, or tenant data without a
  separately verified blocker and explicit approval;
- use fictional screenshots or unsupported marketing claims;
- infer final permissions from the source AndroidManifest alone.

## Current verified Android baseline

Source-controlled release facts on current main:

- application ID: `com.kingnarmar.horus`
- namespace: `com.kingnarmar.horus`
- display name: `H.O.R.U.S`
- compile SDK: 36
- target SDK: 36
- version: `1.0.0+1`
- main manifest declares `android.permission.INTERNET`
- release signing fails closed when signing material is missing
- launcher branding includes adaptive and Android 13+ monochrome support
- CI release gates already build Android and Windows release artifacts
- previous #192 verification established 64-bit and 16 KB compatibility
  evidence for the release foundation

Final Play submission must still verify these properties on the exact signed
AAB uploaded to Play Console.

## Official Google Play references

Re-check these immediately before final submission because Play requirements
can change:

- Data Safety:
  https://support.google.com/googleplay/android-developer/answer/10787469
- App review sign-in details:
  https://support.google.com/googleplay/android-developer/answer/15748846
- App content / review preparation:
  https://support.google.com/googleplay/android-developer/answer/9859455
- Personal-account testing requirements:
  https://support.google.com/googleplay/android-developer/answer/14151465
- Store listing assets:
  https://support.google.com/googleplay/android-developer/answer/9866151
- Play Console requirements:
  https://support.google.com/googleplay/android-developer/answer/10788890

## Play Console workstreams

### 1. App entry and permanent identity

Status: **Manual verification required**

Required evidence:

- H.O.R.U.S app entry exists in Play Console.
- Package name matches `com.kingnarmar.horus`.
- App name is H.O.R.U.S.
- Default language and app/game classification are confirmed.
- Developer/contact verification has no outstanding mandatory action.

The Play package identity must be treated as permanent after app creation.

### 2. App access / reviewer instructions

Status: **Preparation required**

H.O.R.U.S contains authenticated/restricted functionality. Google reviewers
must receive reusable credentials and instructions that allow them to reach all
functionality needed for policy review.

Reviewer access must:

- remain valid throughout review;
- be reusable and not depend on one-time passwords;
- work independently of reviewer location;
- be documented in English in Play Console;
- avoid exposing real customer or Production-sensitive data;
- provide enough tenant/company context to navigate the product;
- use an approved non-sensitive review/demo company and account.

Do not place reviewer passwords in Git, issue bodies, PR descriptions, release
docs, or source code. Store credentials only in the approved private operational
location and enter them directly in Play Console.

### 3. Ads declaration

Status: **Verify in final shipping build**

Current repository review has not identified an advertising SDK or implemented
advertising feature.

Before answering Play Console:

- inspect final dependencies/artifact;
- confirm no ad SDK or advertising surface is present;
- record the final declaration in the release evidence.

Do not declare based only on intent.

### 4. Target audience and content

Status: **Manual Play Console completion required**

H.O.R.U.S is a business SaaS product for heavy transport operations and is not
designed as a child-directed product.

Before submitting:

- answer target-audience questions based on the actual product;
- avoid selecting child age groups unless the product is intentionally designed
  for them;
- ensure listing copy and screenshots match the declared audience.

### 5. Content rating / IARC

Status: **Manual Play Console completion required**

Complete the IARC questionnaire using the actual shipping functionality.
Record the resulting rating and any warnings in the #199 evidence before
closure.

### 6. Privacy policy and account deletion

Status: **Foundation implemented; Play Console wiring still required**

Canonical public URLs:

- Privacy Policy: https://kingnarmar.com/horus/privacy-policy
- Account deletion: https://kingnarmar.com/horus/account-deletion
- Support: https://kingnarmar.com/horus/support

The app also contains an in-app authenticated account-deletion path.

Before closure:

- verify each public URL from an unauthenticated browser;
- add the privacy-policy URL to Play Console;
- add the external account-deletion URL where requested;
- answer deletion questions to match the implemented lifecycle;
- smoke the in-app deletion path on the release candidate.

### 7. Data Safety inventory

Status: **Detailed declaration preparation required**

Do not complete Data Safety from generic assumptions or dependency names alone.
The declaration must reflect real H.O.R.U.S flows and SDK behavior.

Known source-supported data handling includes at least the following categories.

| Data / content | Source-supported H.O.R.U.S use | Off-device handling to verify | Final Play declaration |
| --- | --- | --- | --- |
| Email address | Registration, login, recovery, Auth identity | Supabase Auth | Pending verified classification |
| Full name | Registration/profile metadata | Supabase Auth / profile data | Pending verified classification |
| Phone number | Registration/profile metadata | Supabase Auth / profile data | Pending verified classification |
| Account identifiers | Auth user/company context | Supabase backend | Pending verified classification |
| Operational business data | Customers, drivers, fleet, routes, trips, finance, reports | Supabase database | Pending field-level inventory |
| Driver documents/images | Profile/license/national-ID document flows | Supabase Storage | Pending verified classification |
| Fleet licence documents | File-picker document flow | Supabase Storage | Pending verified classification |
| Trip documents/images | File picker, gallery, and camera capture | Supabase Storage | Pending verified classification |
| Authentication/session material | Session persistence required for logged-in access | Supabase SDK / secure local persistence behavior | Pending SDK verification |
| App preferences | Locale and other local app preferences as implemented | Local storage behavior to verify | Pending verification |
| Connectivity state | Connection-awareness functionality | Plugin behavior to verify | Pending verification |

For every applicable Play data type, verify and record:

1. whether it is collected off-device;
2. whether it is shared with a third party under Play's definition;
3. whether collection is required or optional;
4. the purpose(s) for collection;
5. whether data is processed ephemerally where relevant;
6. whether transfer encryption applies;
7. deletion behavior and retention implications;
8. behavior of included SDKs, not just first-party app code.

The final Data Safety answer must be cross-checked against:

- Privacy Policy;
- actual Supabase Auth/database/storage flows;
- final application dependencies;
- final release artifact;
- account-deletion behavior.

Google requires Data Safety for apps published on closed, open, or production
tracks. An app active only on internal testing is exempt until it moves beyond
internal testing.

### 8. Android permissions and merged-manifest evidence

Status: **Final artifact verification required**

The source main manifest currently declares only:

`android.permission.INTERNET`

This is not sufficient evidence for Play declarations because Android plugins
may contribute manifest entries during merge.

For the exact final signed AAB:

1. build using the approved Production compile-time configuration;
2. inspect the merged/base manifest using current Android tooling/bundletool;
3. list every requested permission and relevant feature;
4. compare them with actual app flows and plugin requirements;
5. complete any Play permission declaration only when required;
6. fail the release gate for any unexplained or unnecessary sensitive
   permission.

Record the final manifest output and Play validation result in release evidence.

### 9. Store listing copy

Status: **Draft required in English and Arabic**

Official expansion:

**H.O.R.U.S = Heavy Operations & Route Unified System**

Never use the incorrect historic concept expansion:
“Heavy Operations & Route Management System”.

The final listing must:

- describe only implemented functionality;
- avoid unsupported security, automation, financial, or integration claims;
- use consistent terminology across English and Arabic;
- represent H.O.R.U.S as a multi-tenant heavy-transport operations SaaS;
- avoid promising future billing/commercial features not present in the build.

Required preparation:

- app name;
- short description;
- full description;
- support website/contact details;
- release notes for the testing release.

Final copy remains pending a focused listing review against the shipping app.

### 10. Play Store graphics

Status: **Outstanding**

Approved visual direction:

- Modern Horus Eye
- dark navy / near-black
- gold / amber
- cyan / blue accent
- premium industrial SaaS feel
- no truck cliché
- no steering-wheel/gear cliché
- no text inside launcher icon

Required assets/evidence:

- final Google Play icon, 512 x 512;
- feature graphic, 1024 x 500, if used/required by the approved listing;
- real screenshots captured from the actual shipping application;
- at least the current minimum screenshot set required by Play;
- higher-quality phone/tablet coverage where the app supports those form
  factors.

Do not use generated fictional app screens as store screenshots.

Repository audit on current main did not find a dedicated Play Store asset set.
Existing web/macOS 512 icons must not be assumed to be the approved Play Store
icon without explicit review.

### 11. Testing tracks

Status: **Not yet completed for H.O.R.U.S**

Recommended sequence:

1. Internal testing.
2. Resolve artifact, install, auth, networking, and policy blockers.
3. Complete Data Safety and required App Content before closed testing.
4. Start H.O.R.U.S closed testing.
5. Maintain at least 12 testers continuously opted in for at least 14 days for
   this app where the personal-account requirement applies.
6. Preserve testing feedback and production-access evidence.
7. Apply for Production access only after the requirement is satisfied.
8. Do not submit to Production until the separate final RC gate (#202) is
   approved.

The fact that Mina System previously completed its own testing does not prove
that H.O.R.U.S is exempt. Treat H.O.R.U.S independently unless Play Console
explicitly shows otherwise.

### 12. Billing / commercial boundary

Status: **Deferred intentionally**

The approved commercial decision is that paid Android SaaS monetization will
eventually use Google Play subscriptions, with server-side verification and
company-scoped entitlements.

However, #199 must not expand into #207/#208/#209/#32/#210 unless Play blocks
the approved pre-monetization testing path.

Internal and closed testing may proceed before paid monetization is enabled.
A real paid public launch remains blocked by the dedicated commercial/billing
issues.

## Artifact verification checklist

Before uploading the release candidate to Play:

- [ ] Build from clean, synchronized main/release candidate.
- [ ] Use `APP_ENV=production`.
- [ ] Use the approved Production Supabase URL and client-safe publishable key.
- [ ] Ensure debug logging is disabled.
- [ ] Build with the approved private upload keystore.
- [ ] Verify package is `com.kingnarmar.horus`.
- [ ] Verify version name/code.
- [ ] Verify target SDK 36.
- [ ] Dump and review the merged/base manifest.
- [ ] Record all final Android permissions.
- [ ] Verify upload signing certificate fingerprint.
- [ ] Reconfirm 64-bit coverage.
- [ ] Reconfirm 16 KB page-size compatibility.
- [ ] Verify no secret/service-role/admin key exists in the artifact.
- [ ] Upload to Internal Testing first.
- [ ] Review Play artifact validation warnings/errors.
- [ ] Review pre-launch results before promotion.

## #199 evidence checklist

Issue #199 must not be closed again until evidence exists for all applicable
items:

### Repository / artifact

- [ ] Data Safety inventory reviewed against real implementation.
- [ ] Final merged permissions documented.
- [ ] Final signed AAB passes Play validation.
- [ ] English/Arabic listing copy approved.
- [ ] Final Play icon approved.
- [ ] Feature graphic approved if used/required.
- [ ] Real application screenshots approved.

### Play Console

- [ ] Developer/account verification has no blocker.
- [ ] App entry/package identity verified.
- [ ] Category/app properties completed.
- [ ] App Access/reviewer instructions completed.
- [ ] Ads declaration completed accurately.
- [ ] Target audience completed accurately.
- [ ] Data Safety completed accurately.
- [ ] Privacy Policy configured.
- [ ] Account-deletion URL/questions completed.
- [ ] IARC/content rating completed.
- [ ] Permission declarations completed if applicable.
- [ ] No mandatory App Content item remains incomplete.

### Testing

- [ ] Internal test completed.
- [ ] Closed test started when required.
- [ ] Required tester count/duration completed.
- [ ] Tester feedback/evidence preserved.
- [ ] Production-access application is available/approved as applicable.

### Final handoff

- [ ] #199 evidence is complete.
- [ ] No unresolved Google Play blocker remains.
- [ ] #199 may then close.
- [ ] Proceed to #202 for final release-candidate QA and submission approval.
