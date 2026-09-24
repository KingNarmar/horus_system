# H.O.R.U.S Environment and Release Configuration

Issue: #194  
Parent: #191

This document is the source of truth for client-side environment configuration
used by Android and Windows builds.

## Security model

H.O.R.U.S is a public client application. Any value compiled into Android or
Windows artifacts must be treated as extractable by an end user.

Allowed client configuration:

```text
APP_ENV
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
ENABLE_DEBUG_LOGS
```

Never ship:

- Supabase `sb_secret_...` keys.
- Legacy Supabase `service_role` JWTs.
- Database passwords.
- Supabase management credentials.
- JWT signing secrets.
- Server/admin credentials.
- Android keystore passwords or private keys.
- Windows private signing keys or certificate passwords.
- Partner Center credentials.

Supabase authorization continues to rely on RLS, grants, and server-side
security. A publishable/legacy anon client key is not a privileged secret.

## Configuration source

The application does not load `.env` files at runtime and does not bundle an
environment file as a Flutter asset.

Configuration is injected at compile time with Dart environment declarations
through Flutter `--dart-define`.

Required keys:

```text
APP_ENV=development|staging|production
SUPABASE_URL=<client-safe Supabase URL>
SUPABASE_PUBLISHABLE_KEY=<sb_publishable_... or legacy anon JWT>
ENABLE_DEBUG_LOGS=true|false
```

`ENABLE_DEBUG_LOGS` defaults to `false`. It may be enabled only for the
development environment, and application debug logging is additionally disabled
when Flutter is not running in debug mode.

## Environment rules

### Development

- `APP_ENV=development`.
- Local HTTP Supabase URLs are allowed.
- Debug logging may be enabled explicitly.
- A release-mode build configured as development will refuse to initialize.

### Staging

- `APP_ENV=staging`.
- HTTPS is required.
- Debug logging must remain disabled.
- A release-mode build configured as staging will refuse to initialize.

### Production

- `APP_ENV=production`.
- HTTPS is required.
- Debug logging must remain disabled.
- Android and Windows release builds must use this environment.

## Fail-safe startup

Configuration is validated before Supabase initialization.

The application refuses normal startup when:

- `APP_ENV` is missing or unknown.
- Supabase URL is missing or invalid.
- staging/production uses a non-HTTPS URL.
- the client key is missing or has an unknown shape.
- an `sb_secret_...` key is supplied.
- a legacy JWT carries the `service_role` role.
- debug logging is enabled outside development.
- a release build is not configured as production.

Failures are mapped to a typed bootstrap failure. The user sees a localized
English/Arabic startup message. Raw keys, URLs, exception messages, and stack
traces are not shown.

## Development example

PowerShell:

```powershell
$env:HORUS_SUPABASE_URL = "<development-url>"
$env:HORUS_SUPABASE_PUBLISHABLE_KEY = "<development-client-key>"

flutter run -d windows `
  --dart-define=APP_ENV=development `
  --dart-define=SUPABASE_URL="$env:HORUS_SUPABASE_URL" `
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$env:HORUS_SUPABASE_PUBLISHABLE_KEY" `
  --dart-define=ENABLE_DEBUG_LOGS=true
```

Bash:

```bash
export HORUS_SUPABASE_URL="<development-url>"
export HORUS_SUPABASE_PUBLISHABLE_KEY="<development-client-key>"

flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=SUPABASE_URL="$HORUS_SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$HORUS_SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=ENABLE_DEBUG_LOGS=true
```

The `HORUS_...` shell variables are only an input convenience. The Flutter
application reads only the four explicit Dart defines above.

## Production Android build

PowerShell:

```powershell
flutter build appbundle --release `
  --dart-define=APP_ENV=production `
  --dart-define=SUPABASE_URL="$env:HORUS_SUPABASE_URL" `
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$env:HORUS_SUPABASE_PUBLISHABLE_KEY" `
  --dart-define=ENABLE_DEBUG_LOGS=false
```

## Production Windows build

PowerShell:

```powershell
flutter build windows --release `
  --dart-define=APP_ENV=production `
  --dart-define=SUPABASE_URL="$env:HORUS_SUPABASE_URL" `
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$env:HORUS_SUPABASE_PUBLISHABLE_KEY" `
  --dart-define=ENABLE_DEBUG_LOGS=false
```

The same compile-time values are embedded in the Windows release consumed by
the MSIX packaging step.

## Release artifact verification

Source inspection is not sufficient. Verify the exact final Android AAB and
Windows MSIX/release output.

Required checks:

1. No `.env` or `.env.*` file is packaged.
2. No `sb_secret_` marker exists.
3. No known service-role/admin credential is present.
4. Production URL and publishable client configuration are expected to be
   extractable and must not be treated as secrets.
5. Launch with valid production config reaches normal authentication/network
   behavior.
6. A release build with missing or invalid config reaches the safe bootstrap
   failure UI and never initializes the normal application.
7. Existing Android signing/API/ABI/page-size gates remain valid.
8. Existing Windows Store identity, WACK, install, launch, update, and uninstall
   gates remain valid.

## Repository verification

Before merging configuration changes:

```text
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
git diff --check
git status --short
```

No database migration, RLS, grant, trigger, or Supabase schema change is part of
this configuration contract.
