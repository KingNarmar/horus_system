# Supabase Auth URL Configuration

Issue: #295

This document is the source of truth for H.O.R.U.S hosted Supabase Auth URL
configuration. These settings are service configuration, not database schema,
and therefore do not belong in SQL migrations.

## Why this exists

Production smoke testing on 2026-09-30 proved that the production confirmation
email contained:

```text
redirect_to=http://localhost:3000
```

The first verification request successfully confirmed the account. A later
request reused the same one-time token and correctly failed as expired/invalid.
The localhost redirect itself is a configuration defect and must not exist in
Production.

H.O.R.U.S deliberately uses an HTTPS website result page after Supabase has
processed the default confirmation link. Android and Windows do not need to
receive an Auth session from that link.

## Canonical URLs

### Production

Site URL:

```text
https://kingnarmar.com/horus/auth/confirmed
```

Allowed redirects:

```text
https://kingnarmar.com/horus/auth/confirmed
https://kingnarmar.com/horus/confirm
https://kingnarmar.com/horus/confirm-email
https://kingnarmar.com/horus/reset-password
```

Production redirect URLs must use HTTPS and must never target localhost or a
loopback address.

### Development

The website development server uses:

```text
http://localhost:5173
```

The checked-in configuration script defines the corresponding H.O.R.U.S Auth
paths for local testing.

## Reproducible management

Use:

```powershell
$env:SUPABASE_ACCESS_TOKEN = "<personal-access-token>"

.\scripts\configure_supabase_auth.ps1 `
  -Environment production `
  -ProjectRef rkhmfbxlduuovlbsxhgy
```

The default mode is read-only verification. It prints the current and expected
Site URL and does not change the project.

Only after explicit production approval, apply:

```powershell
.\scripts\configure_supabase_auth.ps1 `
  -Environment production `
  -ProjectRef rkhmfbxlduuovlbsxhgy `
  -Apply
```

The script patches only `site_url` and `uri_allow_list`, then reads the Auth
configuration back and verifies the canonical values.

Never commit the Supabase access token.

## Application behavior

Flutter registration intentionally does not provide an `emailRedirectTo`
override for the current email/password signup flow. The hosted Supabase Auth
Site URL is the canonical default destination, so the same server-side
configuration applies consistently to Windows and Android without custom native
deep-link handling.

If a future flow needs to return an authenticated session directly to a native
client, implement that as a separate reviewed deep-link feature rather than
overloading this confirmation-result flow.

## Website behavior

`/horus/auth/confirmed` is a result page. Supabase has already attempted the
one-time verification before redirecting there.

The page:
- treats a redirect with no Auth error as a successful confirmation result;
- recognizes `otp_expired` as a used-or-expired one-time link;
- tells a user who may already be confirmed to return to H.O.R.U.S and sign in;
- does not display raw Supabase error descriptions.

The existing `/horus/confirm-email` page remains the token-hash verification
surface for custom email templates. It is not the default Site URL.

## Verification

After any change:

1. Read the hosted Auth config and confirm the exact Site URL.
2. Confirm the Production allow list contains no localhost entries.
3. Build/deploy the website route before changing Production Auth.
4. Create a fresh test account using the Production app.
5. Inspect the generated confirmation URL or Auth logs and confirm there is no
   localhost redirect.
6. Click the link once and verify the website success result.
7. Reuse the same link and verify the website shows safe used/expired guidance.
8. Return to H.O.R.U.S and verify the confirmed account can sign in.

Do not delete the Production test account or other Production data as part of
this verification without explicit approval.
