# H.O.R.U.S Auth Email Delivery and Branding

Issue: #296

## Purpose

Production H.O.R.U.S must use a production-capable custom SMTP provider and
source-controlled Auth email templates. Supabase's built-in sender is reserved
for development/testing use and must not be treated as the public Production
delivery path.

## Production provider and sender

Production currently uses Brevo custom SMTP on the free tier.

Verified sender identity:

```text
H.O.R.U.S System <horus@auth.kingnarmar.com>
```

The sender domain is externally verified and its provider credentials are not
stored in Git or Flutter artifacts.

The exact SMTP host, user, password, From address, and sender name are supplied
through environment variables when the checked-in configuration script is run.
Never commit provider credentials, Supabase personal access tokens, or DNS
provider credentials.

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

All six templates use the same H.O.R.U.S visual language:

- dark H.O.R.U.S shell with gold and cyan accents;
- email-safe table layout and inline styles;
- clear English and Arabic sections;
- RTL direction for Arabic guidance;
- explicit security guidance;
- visible fallback URLs for link-based flows;
- no external fonts, scripts, or remote presentation dependencies.

Confirmation and recovery intentionally use the KING NARMAR website verification
pages with `TokenHash`:

```text
https://kingnarmar.com/horus/confirm-email
https://kingnarmar.com/horus/reset-password
```

These pages call Supabase verification from the browser rather than exposing an
authenticated native-app callback.

Other flows continue to use Supabase-supported `ConfirmationURL` or `Token`
variables where no dedicated H.O.R.U.S website handler exists.

## Website Auth environment dependency

The H.O.R.U.S website Auth handlers are built from Cloudflare Pages Production
environment variables:

```text
VITE_HORUS_SUPABASE_URL
VITE_HORUS_SUPABASE_ANON_KEY
```

Both values must belong to the same H.O.R.U.S Production Supabase project.

During the #296 Production confirmation smoke test, the website was still built
against a different Supabase project. The Production confirmation token therefore
reached the correct H.O.R.U.S page but failed verification as invalid/expired.
After correcting both Production variables and redeploying Cloudflare Pages, the
same confirmation flow verified successfully.

This website configuration is a release dependency. Do not change either value
without verifying the matching Production project and redeploying the website.

## Reproducible configuration

The checked-in script defaults to read-only verification:

```powershell
$env:SUPABASE_ACCESS_TOKEN = "<personal-access-token>"

.\scripts\configure_supabase_auth_email.ps1 `
  -ProjectRef rkhmfbxlduuovlbsxhgy
```

To apply after explicit Production approval, populate provider credentials only
in the local shell:

```powershell
$env:HORUS_SMTP_HOST = "<provider-smtp-host>"
$env:HORUS_SMTP_PORT = "587"
$env:HORUS_SMTP_USER = "<provider-smtp-user>"
$env:HORUS_SMTP_PASSWORD = "<provider-smtp-secret>"
$env:HORUS_SMTP_FROM = "horus@auth.kingnarmar.com"
$env:HORUS_SMTP_SENDER_NAME = "H.O.R.U.S System"

.\scripts\configure_supabase_auth_email.ps1 `
  -ProjectRef rkhmfbxlduuovlbsxhgy `
  -Apply
```

The script patches only Auth email delivery/template settings and verifies the
non-secret sender/template configuration after applying it.

### Windows PowerShell request encoding

The configuration script validates generated JSON locally and sends Management
API requests as explicit UTF-8 bytes. This is required because the
source-controlled templates contain Arabic text and Production setup is commonly
run from Windows PowerShell 5.1.

If the Management API rejects a request as malformed JSON, stop and fix the
checked-in script. Do not work around the failure with Dashboard-only changes.

### Management API request sizing and apply order

Supabase Auth configuration supports partial PATCH updates. H.O.R.U.S therefore
keeps every email subject/template pair in a separate small request and verifies
each one before continuing.

On hosted Free-tier projects, Auth template customization requires custom SMTP
to be enabled first. The Production apply order is:

1. locally preflight every subject/template payload and verify safe JSON string
   serialization before any write;
2. enable custom SMTP;
3. read back and verify the custom SMTP configuration;
4. apply and verify each Auth email template one at a time;
5. perform a final read-back verification.

The preflight byte-size output is also reviewed when templates change
substantially so a visual redesign cannot silently recreate the earlier
Management API request-size failure.

Custom SMTP is intentionally not rolled back automatically if a later template
fails. The custom provider is itself the production-capable delivery path. A
failure after SMTP activation must be investigated and corrected through the
checked-in script.

## Production release gate

Before closing #296:

1. Verify the SMTP provider account and sender domain.
2. Verify SPF/DKIM and review DMARC.
3. Verify the #295 Production Site URL/redirect configuration.
4. Verify Cloudflare Production H.O.R.U.S Auth environment points to the same
   Production Supabase project.
5. Apply #296 Auth email configuration only after explicit approval.
6. Send a fresh confirmation email and inspect sender, subject, EN/AR rendering,
   branding, and fallback link.
7. Confirm the signup link works once and reuse is handled safely.
8. Verify password-recovery delivery and reset flow.
9. Confirm no SMTP/API credential appears in Flutter artifacts, Git history, or
   user-facing errors.

No database migration, tenant/RLS change, or H.O.R.U.S business audit write is
part of this email-delivery configuration.
