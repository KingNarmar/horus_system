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
- Supabase access later

---

## Clone Repository

```bash
git clone https://github.com/KingNarmar/horus_system.git
cd horus_system
```

---

## Configuration

Use `.env.example` as the local configuration template.

Real local configuration files must stay local.

---

## Install Dependencies

After the Flutter project is ready:

```bash
flutter pub get
```

---

## Run the App

```bash
flutter run
```

Platform-specific examples:

```bash
flutter run -d chrome
flutter run -d windows
```

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

Supabase calls are allowed only inside Data Layer data sources.

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

If implementation speed conflicts with architecture correctness, architecture correctness wins.
