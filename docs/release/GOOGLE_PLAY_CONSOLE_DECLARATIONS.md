# Google Play Console Declarations — H.O.R.U.S

Issue: #199  
Parent: #191  
Status: Draft for Play Console entry

This document converts the verified H.O.R.U.S implementation into practical
Google Play Console answers. It is intentionally conservative: any declaration
that still depends on the exact Production AAB, live public URLs, or a reviewer
account remains explicitly marked for manual verification.

It supplements, and does not replace:

- `docs/release/GOOGLE_PLAY_READINESS.md`
- the final release-candidate gate in #202
- the production build/security evidence already established by #192–#198

## Product identity

- App name: **H.O.R.U.S System**
- Expansion: **Heavy Operations & Route Unified System**
- Android application ID: `com.kingnarmar.horus`
- App type: **App**
- Product model: multi-tenant SaaS for heavy transport operations
- Current version in source: `1.0.0+1`
- Current target SDK: 36

Never use the historic incorrect expansion
“Heavy Operations & Route Management System”.

---

## 1. App content — recommended answers

### Ads

**Recommended Play Console answer: No**

Evidence currently verified in the repository:

- no advertising feature exists;
- no AdMob/Google Mobile Ads dependency exists;
- no known third-party advertising SDK exists;
- no advertising or marketing data flow has been identified.

**Final gate:** re-check the exact shipping dependency graph and AAB before
saving the declaration.

### App access

**Recommended Play Console answer: All or some functionality is restricted.**

H.O.R.U.S requires authentication and company context for operational
functionality.

Google review access must use a dedicated reusable demo/reviewer account that:

- is active for the complete review period;
- does not require OTP/2FA during review;
- works regardless of reviewer location;
- belongs to a non-sensitive demo company;
- has enough permissions to inspect the major app functionality;
- contains only synthetic/demo business data;
- is not a real customer/company account.

Do **not** store reviewer passwords in Git, issues, PRs, screenshots, or this
document.

#### Reviewer instruction draft

Paste the following into Play Console only after the reviewer account is
created and tested:

> Launch H.O.R.U.S System and select Log in.  
> Enter the reviewer email and password supplied in the Play Console access
> fields.  
> The account is already assigned to the H.O.R.U.S Demo Company.  
> After login, the app opens the authenticated company workspace.  
> Use the main navigation to review Dashboard, Customers, Drivers, Fleet,
> Routes, Trips, Finance and Reports.  
> No OTP, location restriction, subscription purchase, or external hardware is
> required for this review account.

**Manual action required before submission:** create and smoke-test the actual
reviewer account/company in Production without using real customer data.

### Target audience

H.O.R.U.S is a B2B operations product for transport-company staff and is not
designed for children.

**Recommended age selection: 18 and over only.**

Do not select child age groups unless the product scope intentionally changes.

### News app

**Recommended answer: No.**

### Government app

**Recommended answer: No.**

### Financial features

H.O.R.U.S records operational financial data such as expenses, invoices,
payments, driver compensation, advances/deductions, settlements and business
reporting.

It is **not** a banking, lending, investment, wallet, money-transfer,
cryptocurrency, credit-scoring, insurance, or consumer financial-product app.

If Play Console asks whether the app provides regulated financial products or
services, the recommended answer is **No**, provided the shipping build remains
limited to the currently implemented business-accounting/operations scope.

### Health

**Recommended answer: No.**

### Account deletion

H.O.R.U.S supports:

- an authenticated in-app deletion request path;
- an external account-deletion request path;
- deletion/detachment/anonymization logic designed around multi-tenant business
  records and necessary retention.

Canonical external path configured by the app:

`https://kingnarmar.com/horus/account-deletion`

**Recommended answer:** users can request account deletion.

Important wording rule: do not claim that every historical business/audit record
is always physically erased. Some operational/financial/audit records may be
retained or detached/anonymized where necessary for company-history,
accountability, security, or legal/business retention. The public policy and
Play Console wording must stay consistent with the implemented lifecycle.

### Privacy policy

Canonical configured URL:

`https://kingnarmar.com/horus/privacy-policy`

Support URL:

`https://kingnarmar.com/horus/support`

**Manual verification required before submission:** open all three public URLs
in an unauthenticated browser and confirm HTTPS, final content, mobile rendering,
and no login/geographic restriction.

---

## 2. Data Safety — top-level answers

### Does the app collect or share any required user-data types?

**Yes.**

H.O.R.U.S transmits account, operational, document and financial data from the
client to Supabase Auth, PostgreSQL and Storage.

### Is all collected user data encrypted in transit?

**Expected answer: Yes.**

Verified architecture uses HTTPS Supabase endpoints and does not contain an
identified plaintext external transport path.

**Final gate:** validate the exact Production configuration and final AAB before
submitting this answer.

### Does the app provide a way for users to request deletion of their data?

**Recommended answer: Yes.**

Use the account-deletion implementation and external request path described
above. Retention exceptions must remain disclosed accurately.

### Does the app share user data with third parties?

**Recommended current answer: No**, subject to final SDK/dependency review.

Supabase is used as the application backend/cloud processor acting on behalf of
H.O.R.U.S. Under Google Play's Data Safety rules, a processor qualifying as a
service provider is not treated as “sharing” merely because data is transferred
to it.

No advertising, cross-app profiling, analytics, social, or independent
third-party data-use flow has been identified.

If the final dependency/artifact audit discovers a provider using H.O.R.U.S
data for its own independent purposes, this answer must be revisited.

---

## 3. Data Safety — type-by-type declaration matrix

The table below is the recommended Play Console declaration based on the current
implementation.

| Play data type | Collect? | Share? | Required / Optional | Purpose(s) | H.O.R.U.S evidence |
| --- | --- | --- | --- | --- | --- |
| Personal info — Name | Yes | No | Required | App functionality; Account management | Full name is required at account registration; customer/driver/contact names are also stored operationally |
| Personal info — Email address | Yes | No | Required | App functionality; Account management | Email is required for Auth registration/login/recovery; optional business contact emails also exist |
| Personal info — User IDs | Yes | No | Required | App functionality; Account management; Fraud prevention, security and compliance | Supabase Auth user IDs/company membership context identify authenticated actors and audit attribution |
| Personal info — Address | Yes | No | Optional | App functionality | Customer address/city/country and optional company location fields |
| Personal info — Phone number | Yes | No | Required | App functionality; Account management | Phone is required during user registration; customer/driver/company phone fields are also supported |
| Personal info — Other info | Yes | No | Optional | App functionality | Driver national ID/license information and customer tax-registration details may be entered |
| Financial info — User payment info | No | No | — | — | No card/bank-account/payment-instrument collection identified |
| Financial info — Purchase history | No | No | — | — | H.O.R.U.S invoices/payments are company operational records, not Play-user purchase history |
| Financial info — Credit score | No | No | — | — | Not implemented |
| Financial info — Other financial info | Yes | No | Optional | App functionality | Driver compensation, salary-related values, advances/deductions, settlements, balances and company/trip expenses |
| Location — Approximate | No | No | — | — | No app flow uses device/IP data to infer location |
| Location — Precise | No | No | — | — | No geolocation feature or location SDK/permission identified |
| Messages — Emails | No | No | — | — | App does not read user email content |
| Messages — SMS/MMS | No | No | — | — | No SMS access |
| Messages — Other in-app messages | No | No | — | — | No chat/messaging feature |
| Photos and videos — Photos | Yes | No | Optional | App functionality | Driver profile/license/ID images and trip evidence may be selected/captured and uploaded |
| Photos and videos — Videos | No | No | — | — | No video workflow identified |
| Audio — Voice/sound | No | No | — | — | No audio recording/upload workflow |
| Audio — Music | No | No | — | — | Not implemented |
| Audio — Other audio | No | No | — | — | Not implemented |
| Files and docs — Files and docs | Yes | No | Optional | App functionality | Driver, fleet and trip document flows upload files to Supabase Storage |
| Calendar — Calendar events | No | No | — | — | No calendar access |
| Contacts — Contacts | No | No | — | — | No device contacts access |
| App activity — App interactions | No | No | — | — | No analytics/screen-view/tap collection identified |
| App activity — In-app search history | No | No | — | — | Search/filter terms are not identified as persisted/transmitted history |
| App activity — Installed apps | No | No | — | — | No installed-app inventory access |
| App activity — Other user-generated content | Yes | No | Optional | App functionality | Notes and other free-text operational fields are stored when users provide them |
| App activity — Other actions | Yes | No | Required | App functionality; Fraud prevention, security and compliance | Server-authoritative audit history records authenticated create/update/status/financial actions |
| Web browsing — Web browsing history | No | No | — | — | No browsing-history collection |
| App info/performance — Crash logs | No | No | — | — | No Crashlytics/Sentry or equivalent crash-collection SDK identified |
| App info/performance — Diagnostics | No | No | — | — | No diagnostic telemetry SDK identified |
| App info/performance — Other performance data | No | No | — | — | No performance telemetry identified |
| Device or other IDs | Expected No | Expected No | — | — | No advertising/device-ID SDK identified; final AAB/SDK verification still required |

### Why “Other actions” is declared instead of “App interactions”

H.O.R.U.S does not currently record generic screen views, tap counts, session
analytics, or navigation telemetry.

It does record important authenticated business actions in structured audit
history, including actor identity, module/entity/action and relevant old/new
business values. This is best treated as **App activity — Other actions**, not
generic analytics-style **App interactions**.

### Required vs optional notes

Google only permits “optional” when users can avoid providing that data type.

Current form behavior establishes:

- account name: required;
- account phone: required;
- account email: required;
- customer name: required for a customer record;
- customer contact person/phone/email/tax/address/city/country/credit limit:
  optional;
- driver name: required for a driver record;
- driver phone/national ID/license/expiry/images/notes: optional;
- company name and timezone: required for company creation;
- company business type/phone/email/country/city: optional;
- document/image uploads are user-controlled, even though some later trip
  workflow states require acceptable trip evidence before progression.

If Play Console wording changes or treats a conditional core-workflow upload as
required for the entire data type, revisit the Photos / Files & docs rows before
submission.

---

## 4. Data types currently expected to remain unchecked

Do not select these unless the final artifact/SDK review proves otherwise:

- Approximate location
- Precise location
- Race and ethnicity
- Political or religious beliefs
- Sexual orientation
- Health information
- Fitness information
- Emails
- SMS/MMS
- Other in-app messages
- Videos
- Voice or sound recordings
- Music files
- Other audio files
- Calendar events
- Contacts
- Installed apps
- Web browsing history
- Crash logs
- Diagnostics
- Other app performance data
- Credit score
- User payment information
- Purchase history

Device or other IDs is **pending final artifact/SDK verification** and must not
be answered solely from the source manifest.

---

## 5. Data Safety purpose mapping

Use only the purposes below unless the implementation changes.

### App functionality

Use for:

- account authentication required to operate the app;
- customer/driver/company data;
- fleet/routes/trips;
- documents/images;
- operational notes;
- expenses/invoices/payments/statements;
- driver finance/compensation/settlements;
- audit/action history needed for business accountability.

### Account management

Use for:

- full name;
- account email;
- registration phone;
- Auth user ID;
- login/recovery/account lifecycle.

Do not apply Account management to unrelated customer/driver/business records.

### Fraud prevention, security and compliance

Use for:

- authenticated user IDs tied to accountability/security;
- server-authoritative audit action history.

Do not use this purpose for ordinary operational data merely because the backend
uses RLS.

### Purposes not currently supported by evidence

Do not select without a future verified implementation:

- Analytics
- Advertising or marketing
- Personalization
- Developer communications

---

## 6. SDK/dependency evidence

Current direct dependencies include:

- `supabase_flutter`
- `flutter_secure_storage`
- `shared_preferences`
- `connectivity_plus`
- `image_picker`
- `file_picker`
- `url_launcher`
- `device_preview`

Current repository review found no direct dependency for:

- Firebase Analytics
- Firebase Crashlytics
- Google Mobile Ads / AdMob
- Sentry
- geolocator/location SDK
- permission_handler
- contacts access

`device_preview` is present as a production dependency but is gated out of
release behavior by the established release configuration. It remains a
quality-hardening/dependency-cleanup consideration, not a #199 blocker unless
the final artifact proves otherwise.

---

## 7. Android permission declaration gate

The source Android manifest currently declares:

`android.permission.INTERNET`

Do **not** copy that fact directly into Play Console as final permission
evidence.

The exact Production AAB must be inspected after final signing/build because
plugins can contribute merged-manifest entries.

### Expected result

No sensitive Android runtime permission is currently expected from the verified
feature design.

Image and document flows use user-invoked picker/camera integrations rather
than a background data-collection design.

Treat any unexpected appearance of the following as a release blocker until
explained and justified:

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `READ_CONTACTS`
- `READ_SMS`
- `READ_CALL_LOG`
- `RECORD_AUDIO`
- broad storage/media access not required by the current picker implementation
- advertising ID related permissions

### Final AAB verification

For the exact signed Production AAB:

1. build from synchronized final main/RC;
2. use the approved Production compile-time configuration;
3. use the private upload keystore;
4. dump the base manifest with current `bundletool`;
5. record every `uses-permission`;
6. compare each permission with an implemented feature;
7. reject unexplained/sensitive additions;
8. upload to Internal Testing;
9. review Play Console artifact warnings;
10. preserve the manifest/validation evidence under #199.

Example local inspection pattern:

```text
java -jar bundletool.jar dump manifest --bundle=<production-aab> --module=base
```

Use the locally approved/current bundletool version rather than committing a
binary tool into the repository.

---

## 8. Main store listing — English

### App name

**H.O.R.U.S System**

### Short description

**Manage heavy transport trips, fleet, drivers, expenses and reports in one SaaS.**

### Full description

**H.O.R.U.S System — Heavy Operations & Route Unified System** is a
multi-tenant SaaS platform built for heavy transport operations.

Manage your company workspace from one unified application with tools for
customers, drivers, tractor heads and trailers, routes, trip lifecycle and
status tracking, operational documents, trip expenses, driver advances and
deductions, company expenses, invoices, payments, customer statements,
dashboards and reports.

H.O.R.U.S is designed for transport teams that need structured operational and
financial records across desktop, tablet and mobile layouts while keeping each
company workspace isolated.

Key capabilities include:

- Customer, driver and fleet management
- Route and trip lifecycle management
- Trip status history and operational evidence
- Trip and company expense tracking
- Driver finance and settlement workflows
- Invoices, payments and customer statements
- Dashboards, reports and company-scoped audit history
- Role-based multi-company access

H.O.R.U.S is business software intended for authorized transport-company users.
Some features depend on company role and permissions.

### Testing release notes

**Initial H.O.R.U.S testing release.**

Includes the production-ready foundation for authentication, multi-company
access, customers, drivers, fleet, routes, trips, expenses, driver finance,
invoices, payments, statements, dashboards, reports, documents and account
lifecycle flows.

This testing release is intended to validate installation, authentication,
company access, core workflows, performance and usability before production
submission.

---

## 9. Main store listing — Arabic

### اسم التطبيق

**H.O.R.U.S System**

### الوصف المختصر

**إدارة الرحلات والأسطول والسائقين والمصروفات والتقارير للنقل الثقيل.**

### الوصف الكامل

**H.O.R.U.S System — Heavy Operations & Route Unified System** هو نظام SaaS
متعدد الشركات مخصص لإدارة عمليات النقل الثقيل من خلال منصة موحدة.

يوفر النظام أدوات لإدارة العملاء والسائقين ورؤوس الجر والمقطورات والمسارات
ودورة حياة الرحلات وحالاتها والمستندات التشغيلية ومصروفات الرحلات وسلف وخصومات
السائقين ومصروفات الشركة والفواتير والمدفوعات وكشوف حساب العملاء ولوحات
المعلومات والتقارير.

تم تصميم H.O.R.U.S لفرق شركات النقل التي تحتاج إلى سجلات تشغيلية ومالية منظمة
مع دعم تخطيطات سطح المكتب والأجهزة اللوحية والهواتف، مع الحفاظ على عزل بيانات
كل شركة داخل مساحة العمل الخاصة بها.

أهم الإمكانيات:

- إدارة العملاء والسائقين والأسطول
- إدارة المسارات ودورة حياة الرحلات
- سجل حالات الرحلات والمستندات التشغيلية
- متابعة مصروفات الرحلات ومصروفات الشركة
- إدارة الحركات المالية والتسويات الخاصة بالسائقين
- الفواتير والمدفوعات وكشوف حساب العملاء
- لوحات المعلومات والتقارير وسجل العمليات الخاص بكل شركة
- صلاحيات وأدوار متعددة داخل الشركات

H.O.R.U.S هو برنامج أعمال مخصص للمستخدمين المصرح لهم داخل شركات النقل، وقد
تختلف بعض الوظائف حسب دور المستخدم وصلاحياته داخل الشركة.

### ملاحظات إصدار الاختبار

**الإصدار التجريبي الأول من H.O.R.U.S.**

يتضمن الأساس الجاهز للإنتاج للمصادقة والوصول متعدد الشركات وإدارة العملاء
والسائقين والأسطول والمسارات والرحلات والمصروفات والحركات المالية للسائقين
والفواتير والمدفوعات وكشوف الحساب ولوحات المعلومات والتقارير والمستندات ودورة
حياة الحساب.

هذا الإصدار مخصص لاختبار التثبيت وتسجيل الدخول والوصول إلى الشركة وسير العمل
الأساسي والأداء وسهولة الاستخدام قبل التقديم للإنتاج.

---

## 10. Store screenshots — capture plan

Screenshots must come from the real shipping application. Do not generate
fictional UI screenshots.

Before capture:

- use a synthetic demo company only;
- remove real customer, driver, phone, email, ID, financial and document data;
- use coherent demo values suitable for public display;
- ensure the release branding is visible;
- avoid debug banners/tools;
- use final localization and theme;
- avoid showing passwords, tokens, Supabase identifiers, internal IDs or
  developer consoles.

Recommended Android screenshot set:

1. Dashboard — operational overview
2. Trips — responsive trip list/statuses
3. Trip details — status/history/financial summary without sensitive values
4. Fleet — tractor/trailer management
5. Drivers — driver operations using synthetic identities
6. Reports / customer statement / finance workspace

For Arabic listing, capture localized Arabic screens if Play Console/localized
asset strategy uses language-specific screenshots.

---

## 11. Play graphics

Still required outside this documentation PR:

- final Google Play icon: 512 × 512
- feature graphic: 1024 × 500 where used/required
- real Android screenshots

Approved visual direction remains:

- Modern Horus Eye
- near-black/dark navy base
- gold/amber lines
- cyan/blue accent
- premium industrial SaaS feel
- no truck/steering-wheel/gear cliché
- no icon text

The Android launcher vector is the current branding source of truth. Do not
silently substitute unrelated legacy macOS/web icons.

---

## 12. IARC/content-rating preparation

Final IARC answers must be entered manually from the actual questionnaire shown
by Play Console.

Current product evidence indicates no implemented:

- violence/game violence;
- sexual content/nudity;
- gambling;
- controlled-substance promotion;
- user-to-user chat/social network;
- unrestricted user-generated public content;
- browser/open-web content feed.

H.O.R.U.S contains private company-entered operational records and document
uploads. Those are not public social/user-generated-content feeds.

Do not predict or hardcode the final IARC rating in the repository. Record the
rating after Play Console generates it.

---

## 13. Closed-testing preparation

For a qualifying personal developer account, Production access remains gated by
Google's closed-testing requirement.

Required sequence:

1. complete app entry and mandatory App Content;
2. upload the signed build to Internal Testing first;
3. smoke installation/login/core workflows;
4. resolve artifact/permissions/pre-launch blockers;
5. create Closed Testing;
6. keep at least 12 testers opted in continuously for at least 14 days;
7. preserve meaningful testing/feedback evidence;
8. apply for Production access after Play Console enables the application;
9. do not make the Production submission until #202 final RC approval.

Recruit more than the minimum where practical so a tester dropping out does not
reset the continuous minimum-count requirement.

---

## 14. Manual actions still required before #199 can close

### Mina / Play Console

- [ ] Confirm/create the H.O.R.U.S app entry.
- [ ] Confirm package identity `com.kingnarmar.horus`.
- [ ] Confirm developer/contact verification has no action pending.
- [ ] Open Privacy Policy URL unauthenticated.
- [ ] Open Account Deletion URL unauthenticated.
- [ ] Open Support URL unauthenticated.
- [ ] Create a synthetic Production reviewer/demo account and company.
- [ ] Enter reviewer credentials/instructions directly in Play Console.
- [ ] Complete Ads declaration.
- [ ] Complete Target Audience.
- [ ] Complete Data Safety from this matrix after final artifact verification.
- [ ] Complete Account Deletion / Privacy fields.
- [ ] Complete IARC questionnaire.
- [ ] Upload approved English/Arabic listing copy.
- [ ] Upload approved Play icon/feature graphic/screenshots.
- [ ] Upload final signed AAB to Internal Testing.
- [ ] Review artifact warnings and pre-launch report.
- [ ] Start Closed Testing.
- [ ] Maintain the required tester count/duration.
- [ ] Apply for Production access when eligible.

### Repository / release evidence

- [ ] Build exact Production AAB from the approved final commit.
- [ ] Verify merged manifest permissions.
- [ ] Verify package/version/target SDK/signing.
- [ ] Reconfirm 64-bit and 16 KB compatibility.
- [ ] Scan final artifact for forbidden secrets/service-role/admin material.
- [ ] Record Play upload validation outcome.
- [ ] Record final Data Safety answers after artifact review.
- [ ] Record generated IARC rating.
- [ ] Record testing start/end and production-access result.

---

## 15. Stop conditions

Do not proceed from Internal Testing to Closed Testing if any of the following
is true:

- Data Safety still contradicts the shipping build;
- Privacy/Deletion/Support URLs do not resolve publicly;
- reviewer credentials are not reusable;
- an unexplained sensitive permission appears in the final AAB;
- screenshots contain real personal/company-sensitive data;
- listing copy claims a feature not in the shipping build;
- Production build points to the wrong Supabase environment;
- package/signing identity differs from the approved foundation.

Do not close #199 merely because a documentation or branding PR merges.
Issue #199 closes only when the actual Play Console, artifact, assets and testing
evidence satisfy its acceptance criteria.
