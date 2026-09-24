# H.O.R.U.S System — Development Setup

## Purpose

This document explains the initial development setup for H.O.R.U.S System.

Core project rule:

```text
SaaS + Multi-Tenant + Responsive/Adaptive + Clean Architecture by the book + SOLID Principles
```

---

## Required Tools

- Flutter SDK
- Git
- VS Code or Android Studio
- GitHub access
- Supabase client configuration for the selected environment

---

## Clone Repository

```bash
git clone https://github.com/KingNarmar/horus_system.git
cd horus_system
```

---

## Configuration

H.O.R.U.S does not load or bundle a runtime `.env` file.

Client-safe configuration is injected explicitly with Flutter
`--dart-define` values. Read
`docs/release/ENVIRONMENT_CONFIGURATION.md` before running or building the
application.

Required compile-time values:

```text
APP_ENV
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
ENABLE_DEBUG_LOGS
```

Never place a Supabase secret/service-role key or other privileged credential
in client configuration.

---

## Install Dependencies

```bash
flutter pub get
```

---

## Run the App

Example for Windows development:

```powershell
$env:HORUS_SUPABASE_URL = "<development-url>"
$env:HORUS_SUPABASE_PUBLISHABLE_KEY = "<development-client-key>"

flutter run -d windows `
  --dart-define=APP_ENV=development `
  --dart-define=SUPABASE_URL="$env:HORUS_SUPABASE_URL" `
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$env:HORUS_SUPABASE_PUBLISHABLE_KEY" `
  --dart-define=ENABLE_DEBUG_LOGS=true
```

A release-mode build must use `APP_ENV=production`.

---

## Required Structure

The project must follow feature-first Clean Architecture:

```text
lib/
  core/
  shared/
  features/
```

Each feature must contain:

```text
data/
domain/
presentation/
```

---

## Supabase Rule

Supabase is an external detail.

Supabase calls are allowed only inside Data Layer data sources and approved
core initialization/DI wiring.

They are forbidden inside:

- Domain
- Cubits
- Widgets

---

## Before Starting Any Issue

Read these files first:

- `PROJECT_ROADMAP.md`
- `docs/architecture/ARCHITECTURE_GUIDELINES.md`
- `docs/github/GITHUB_ISSUES.md`
- `CONTRIBUTING.md`

---

## Final Rule

If implementation speed conflicts with architecture correctness, architecture
correctness wins.
