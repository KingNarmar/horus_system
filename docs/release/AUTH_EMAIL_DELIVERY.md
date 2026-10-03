# H.O.R.U.S Auth Email Delivery and Branding

Issue: #296

## Purpose

Production H.O.R.U.S must not depend on Supabase's built-in development SMTP
service. Production smoke testing showed messages sent from
`noreply@mail.app.supabase.io` with the default Supabase Auth template.

Supabase documents the built-in sender as a development/testing service with
delivery restrictions and no production SLA. A custom SMTP provider is required
before public email/password signup is considered release-ready.

## Cost constraint

The initial implementation must not add a paid subscription.

Recommended first provider: Resend Free.

At implementation time Resend provides a free transactional-email allowance and
an SMTP relay. Re-check provider limits immediately before Production
activation because third-party quotas can change.

The configuration script is provider-agnostic. A different SMTP provider may be
used without changing Flutter code or email templates.

## Sender identity

Recommended sender after domain verification:

```text
H.O.R.U.S System <auth@kingnarmar.com>
```

The exact From address is supplied through `HORUS_SMTP_FROM`; it is not
hardcoded in source.

Before Production activation, the chosen provider must verify the sender domain.
Publish the provider-required SPF/DKIM DNS records and configure DMARC
appropriately. DNS/provider credentials are external secrets and must not be
committed.

## Source-controlled templates

Templates live under:

```text
supabase/templates/
```

Covered flows:

- account confirmation
- password recovery/reset
- email change
- Supabase-native invitation
- magic link
- reauthentication

The bodies provide concise English plus Arabic guidance.

Confirmation and recovery intentionally use the existing KING NARMAR website
verification pages with `TokenHash`:

```text
https://kingnarmar.com/horus/confirm-email
https://kingnarmar.com/horus/reset-password
```

These pages call Supabase verification from the browser rather than exposing an
authenticated native-app callback. The confirmation design also reduces the
chance that a simple email-link prefetch consumes the one-time token, because
the email first opens a website route and verification is performed by page
logic.

Other flows use Supabase's `ConfirmationURL` or `Token` variables where no
dedicated H.O.R.U.S website handler exists.

## Reproducible configuration

The checked-in script defaults to read-only verification:

```powershell
$env:SUPABASE_ACCESS_TOKEN = "<personal-access-token>"

.\scripts\configure_supabase_auth_email.ps1 `
  -ProjectRef rkhmfbxlduuovlbsxhgy
```

To apply after explicit Production approval, populate provider credentials in
the shell. Example values for Resend are shown only as non-secret setup
guidance:

```powershell
$env:HORUS_SMTP_HOST = "smtp.resend.com"
$env:HORUS_SMTP_PORT = "587"
$env:HORUS_SMTP_USER = "resend"
$env:HORUS_SMTP_PASSWORD = "<provider-api-key>"
$env:HORUS_SMTP_FROM = "auth@kingnarmar.com"
$env:HORUS_SMTP_SENDER_NAME = "H.O.R.U.S System"

.\scripts\configure_supabase_auth_email.ps1 `
  -ProjectRef rkhmfbxlduuovlbsxhgy `
  -Apply
```

Never commit `SUPABASE_ACCESS_TOKEN`, SMTP passwords/API keys, DNS provider
credentials, or other privileged secrets.

The script patches only email delivery/template Auth settings and verifies the
non-secret sender/template configuration after applying it.


### Windows PowerShell request encoding

The configuration script validates its generated JSON locally and sends the
Management API request as explicit UTF-8 bytes. This is required because the
source-controlled Auth templates include Arabic text and Production setup is
commonly run from Windows PowerShell 5.1.

If the Management API rejects a request as malformed JSON, stop immediately and
fix the checked-in script. Do not work around the failure with a Dashboard-only
template or SMTP change.


### Management API request sizing and apply order

Supabase Auth configuration supports partial PATCH updates. H.O.R.U.S therefore
keeps every email subject/template pair in a separate small request and verifies
each one before continuing.

On hosted Free-tier projects, Supabase does not allow Auth email template
customization while the project still uses the default email provider. The
Production apply order is therefore:

1. locally preflight every subject/template payload and verify safe JSON string
   serialization before any write;
2. enable custom SMTP;
3. read back and verify the custom SMTP configuration;
4. apply and verify each Auth email template one at a time;
5. perform a final read-back verification.

Custom SMTP is intentionally not rolled back automatically if a later template
fails. The custom provider is itself the production-capable delivery path, while
the Supabase default sender is development/testing-oriented. A failure after SMTP
activation must be investigated and corrected through the checked-in script.

If any PATCH fails, stop and investigate the checked-in script or provider
configuration. Do not continue with manual Dashboard-only changes.

## Production release gate

Before enabling public Production signup:

1. Verify the SMTP provider account and sender domain.
2. Verify SPF/DKIM and review DMARC.
3. Verify the #295 Production Site URL/redirect configuration.
4. Apply #296 Auth email configuration only after explicit approval.
5. Send confirmation to an address that is not a Supabase organization member.
6. Verify sender name/address and H.O.R.U.S EN/AR body.
7. Confirm the signup link works once and that reuse is handled safely.
8. Verify password-recovery delivery and reset flow.
9. Confirm no SMTP/API credential appears in Flutter artifacts, Git history, or
   user-facing errors.

No database migration, tenant/RLS change, or H.O.R.U.S business audit write is
part of this email-delivery configuration.
