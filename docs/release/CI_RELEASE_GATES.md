# H.O.R.U.S CI and Protected-Main Release Gates

Issue: #198  
Parent: #191

This document defines the repository CI contract used to protect `main` before
production release. It complements the platform release foundations in #192,
#193, and the production configuration contract in #194.

## Workflow

The tracked workflow is:

```text
.github/workflows/ci.yml
```

It runs for pull requests targeting `main` and for pushes to `main`.

The approved Flutter toolchain for this gate is pinned in the workflow to:

```text
Flutter 3.41.9 stable
```

The repository Dart constraint remains the source-of-truth compatibility
boundary in `pubspec.yaml`.

## Required checks

The stable required check names are:

```text
Quality Gate
Android Release Build
Windows Release Build
```

### Quality Gate

The quality job runs:

```text
flutter pub get
dart format --set-exit-if-changed lib test
flutter test test/architecture
flutter analyze
flutter test
```

Architecture tests are run explicitly before the full suite so dependency-rule,
tenant-boundary, audit, localization, and other architecture regressions fail
with a focused diagnostic before the complete regression suite.

### Android Release Build

CI validates that the Android release App Bundle can be produced from a clean
checkout while preserving the release-signing fail-closed design from #192.

The job creates a disposable CI-only keystore inside the ephemeral runner,
writes the temporary `android/key.properties`, builds the release AAB, verifies
that the expected artifact exists, and removes the temporary signing files.

The generated keystore:

- is created only inside the runner;
- is not stored in GitHub Secrets;
- is not the production Google Play upload key;
- must never be used to submit a Store artifact.

### Windows Release Build

CI builds the x64 Windows release executable and validates the tracked Microsoft
Store MSIX packaging configuration from #193.

It verifies the expected outputs:

```text
build/windows/x64/runner/Release/horus.exe
build/windows/x64/runner/Release/horus-system-store.msix
```

## CI configuration is not production configuration

Release-build validation must not depend on a real production Supabase project
until one exists.

The workflow therefore uses synthetic, non-secret, client-safe compile-time
values only to prove that release compilation and packaging remain healthy.

The CI values must never be treated as a deployable environment and the
resulting Android or Windows artifacts must never be submitted to Google Play or
Microsoft Store.

Real production artifacts must still follow
`docs/release/ENVIRONMENT_CONFIGURATION.md` and use the approved production
Supabase project and production signing/submission process.

## Secret handling

The workflow must remain safe for pull-request execution.

Rules:

- repository contents permission is read-only;
- no production Supabase secret/service-role/admin key is required;
- no Android production signing key is required;
- no Windows private signing key is required;
- no Partner Center credential is required;
- secret values must never be printed to workflow logs;
- Store publishing is not automated by this workflow.

## Protected-main configuration

After the workflow names are confirmed green on a pull request, configure
GitHub branch protection or a repository ruleset for `main`.

Required protection:

1. Require a pull request before merging.
2. Require the following status checks before merging:
   - `Quality Gate`
   - `Android Release Build`
   - `Windows Release Build`
3. Require the branch to be up to date before merging when GitHub offers that
   setting for the selected protection model.
4. Do not enable auto-merge as part of #198.
5. Preserve the H.O.R.U.S review protocol: Final PR Review, explicit Ready
   approval, and a separate explicit Merge approval.

The protection state is a GitHub repository setting, not application code.

## Verification

Before #198 can close:

- the workflow must run on its implementation pull request;
- all three stable checks must pass;
- formatting, architecture tests, analyzer, and full tests must execute as
  separate failing steps inside the required Quality Gate;
- Android release AAB validation must pass without production secrets;
- Windows release and MSIX validation must pass without production secrets;
- `main` must report branch protection/ruleset enforcement with the required
  checks after configuration;
- no workflow log may expose a privileged credential;
- the repository diff must remain scoped to CI/release-governance work;
- no Domain, Data, Presentation, Supabase schema, RLS, grant, or migration change
  belongs to this issue.

## Local verification remains required

CI does not replace the project verification or manual smoke rules. Before
Ready/Merge, continue to run as applicable:

```text
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
git diff --check
git status --short
```

Final release-candidate smoke and Store submission remain tracked by #202.
