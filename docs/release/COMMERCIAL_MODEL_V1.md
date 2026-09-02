# H.O.R.U.S System — V1 Commercial Model and Billing Decision

Issue: #201  
Parent release-readiness issue: #191  
Decision date: 2026-09-02

## Decision Summary

H.O.R.U.S will ultimately launch as a paid SaaS product with self-service subscription purchasing available from the Android application.

The Google Play Billing implementation is intentionally deferred in the development sequence until the higher-priority release-readiness work is complete. This is a sequencing decision, not a decision to remove in-app purchasing from the product.

Before a paid public release is activated, the billing, entitlement, plan-limit, licensing, payout, and operational requirements defined below must be completed and verified.

## Android Commercial Model

The intended paid Android model is Google Play in-app subscriptions.

When monetization is activated:

- The Play-distributed Android application must use the compliant Google Play billing path for paid digital SaaS functionality unless a deliberately approved regional/program exception is adopted later.
- No ad-hoc external checkout link may be introduced into the Play-distributed application as a shortcut around the approved billing model.
- Purchase success on the Flutter client must never directly grant a company entitlement.
- Google Play purchase state must be verified server-side before H.O.R.U.S changes company subscription state.
- Restore, renewal, cancellation, expiration, refund, revocation, grace-period, account-hold, upgrade, and downgrade behavior must be designed explicitly.

## SaaS Entitlement Ownership

H.O.R.U.S subscriptions are company-scoped, not device-scoped and not user-scoped.

A purchase may be initiated by an authorized company user, but the resulting entitlement belongs to the H.O.R.U.S company tenant.

The canonical flow must remain conceptually:

```text
Google Play Billing
        ↓
purchase token / purchase state
        ↓
server-side verification
        ↓
company-scoped subscription state
        ↓
H.O.R.U.S Domain entitlements
        ↓
all supported platforms for that company
```

The Flutter client must not become the source of truth for paid access.

## Cross-Platform Rule

Company entitlement must be platform-independent.

If a company purchases a valid subscription through Android, the same company entitlement must be visible when authorized users sign in on Windows or another supported H.O.R.U.S platform.

Platform billing SDK details belong in outer infrastructure/Data boundaries. Domain must remain pure and must not depend on Google Play, Microsoft Store, Flutter billing packages, purchase tokens, or store-specific APIs.

## Windows Model

Windows must consume the same company-scoped backend entitlement source as Android.

A separate Windows purchase mechanism is not required to be implemented as part of Issue #201. The exact Windows commerce path may be decided in a focused implementation issue before Windows paid distribution if needed.

Windows must never maintain an independent entitlement truth that can conflict with the H.O.R.U.S company subscription state.

## Current Pre-Monetization State

At the time of this decision:

- Subscription and plan foundations exist.
- Production checkout is not implemented.
- Google Play Billing is not implemented.
- Paid-plan enforcement is not yet complete.
- Existing development subscription plans do not represent an approved production pricing contract.

Therefore, current development plan records, prices, and placeholders must not be treated as the final commercial offer.

## Self-Service Registration Before Monetization

Self-service account and company creation may remain available while paid billing is deferred.

However:

- Registration must not be described as a paid subscription purchase.
- No paid entitlement may be inferred merely from account or company creation.
- Trial duration, free access, paid conversion rules, and production prices must be explicitly approved before monetization is activated.

## Issue #32 — Plan-Limit Checks

Issue #32 is not required merely to continue the non-billing release-readiness work.

It becomes a release blocker before real paid plan contracts are activated if those plans promise enforceable limits or gated functionality.

Before monetization, the product must define and verify the limits and feature entitlements for each sellable plan, then enforce those rules through the correct Domain and backend/security boundaries.

## Required Billing Implementation Work Before Paid Release

The paid release must not be enabled until focused implementation work covers at least:

1. Production plan and pricing contract.
2. Trial/free-access policy, if any.
3. Google Play subscription products, base plans, and offers.
4. Flutter Google Play purchase and restore flows.
5. Server-side Google purchase-token verification.
6. Company-to-purchase association rules.
7. Backend entitlement synchronization.
8. Subscription lifecycle synchronization for renewals, cancellations, expiration, refunds, revocations, grace periods, and account holds.
9. Upgrade and downgrade rules.
10. Issue #32 plan-limit and feature-entitlement enforcement where required by the approved plans.
11. Typed failures and localized EN/AR presentation for billing states.
12. Structured company-scoped audit for important subscription state changes.
13. Multi-tenant and role-security verification.
14. Android store-policy verification against the policy in force at release time.
15. Financial reconciliation and support procedures.

Billing work must be split into focused PR-sized issues rather than implemented as one large cross-layer change.

## Commercial and Licensing Gate

The developer account and payout configuration are operational concerns separate from H.O.R.U.S Domain entitlements.

Before the first real paid customer transaction is accepted, Mina must confirm and complete the business/trade licensing, banking/payout, tax/VAT, identity, and merchant requirements applicable at that time.

The commercial launch must not rely on collecting paid customer revenue first and obtaining required licensing afterward.

Because legal, tax, store, banking, and merchant rules can change, their current requirements must be re-verified from official sources immediately before monetization is activated.

## Architecture Invariants

Future billing implementation must preserve all existing H.O.R.U.S rules:

- SaaS and multi-tenant isolation.
- Company-scoped entitlements.
- Presentation -> Domain <- Data dependency direction.
- Pure Domain with no store SDK dependencies.
- Supabase/external APIs only in permitted outer layers.
- Cubits call Use Cases only.
- No financial or entitlement calculations in Widgets.
- No frontend-only security or tenant isolation.
- Typed Failures and stable failure codes.
- English and Arabic localization together.
- Structured company-scoped audit.
- Responsive/adaptive behavior across supported platforms.
- Focused, testable, maintainable implementation.

## Release Sequencing Decision

The approved sequence is:

```text
Complete higher-priority release-readiness work
        ↓
Finalize production plans / trial / pricing
        ↓
Complete required commercial and licensing readiness
        ↓
Implement and verify Google Play Billing + backend entitlements
        ↓
Implement required plan-limit enforcement
        ↓
Complete store submission verification
        ↓
Enable paid public release
```

Closed/internal testing may occur earlier, but paid public monetization must not be enabled until the relevant commercial gates are complete.

## Issue #201 Completion Boundary

Issue #201 is a decision/documentation issue. It does not implement billing.

It is complete when this commercial model is approved and the future implementation dependencies are explicit.

The implementation itself must be tracked by focused follow-up issues and must be completed before a paid public release.
