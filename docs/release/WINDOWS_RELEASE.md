# H.O.R.U.S Windows Microsoft Store Release Foundation

Issue: #193  
Parent: #191

This document defines the Windows Microsoft Store packaging baseline for
H.O.R.U.S. It does not replace Partner Center listing/certification work tracked
by #200, production environment hardening tracked by #194, or final release
candidate QA tracked by #202.

## Reserved Microsoft Store product

The Microsoft Store product name reserved in Partner Center is:

```text
HORUS System
```

Treat the Store package identity as permanent once the first package is
published. Do not invent or substitute an Android application ID, repository
name, or local executable name for the Store identity.

## Microsoft Store package identity

The authoritative Partner Center values are:

```text
Package/Identity/Name:                  KingNarmar.HORUSSystem
Package/Identity/Publisher:             CN=E9CE55B8-AEDA-43A1-9E0C-43ADE997A176
Package/Properties/PublisherDisplayName: King Narmar
```

These values are case-sensitive and must match Partner Center exactly.

The Package Family Name, Package SID, and Store ID are Partner Center-managed
identifiers and are not substitutes for the manifest identity fields above.

## Windows executable and product metadata

The production Windows executable is:

```text
horus.exe
```

User-facing Windows product metadata uses:

```text
Display name:     HORUS System
Product name:     HORUS System
Publisher display: King Narmar
```

The repository-level Flutter package name remains `horus_system`; it is not a
Store identity.

## MSIX packaging path

H.O.R.U.S uses the `msix` Dart package as release tooling only:

```yaml
dev_dependencies:
  msix: ^3.18.0
```

The Store package configuration lives in the root `pubspec.yaml`. It is
restricted to the Partner Center identity, x64 architecture, the network client
capability required by the SaaS application, and Store packaging mode.

The initial Store architecture is:

```text
x64
```

Do not add ARM64 or another architecture inside #193 without an explicit,
verified product requirement.

## Version policy

Flutter application versioning remains declared in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

The corresponding first Microsoft Store package version is:

```text
1.0.0.0
```

Microsoft Store package versions use four numeric parts. For Windows 10/11
packages, the fourth part is reserved for Store use and must be `0` when the
package is built.

The release rule is therefore:

- The first three MSIX components must match the Flutter semantic version
  `major.minor.patch`.
- The fourth MSIX component must remain `0`.
- Increasing only Flutter's `+buildNumber` does not create a new Microsoft
  Store package version.
- A later Store release must increase at least one of
  `major.minor.patch`, then update `msix_version` to the matching
  `major.minor.patch.0`.

Example:

```text
Flutter 1.0.0+1 -> MSIX 1.0.0.0
Flutter 1.0.0+2 -> MSIX 1.0.0.0  (not a new Store package version)
Flutter 1.0.1+2 -> MSIX 1.0.1.0
```

Before every Store package build, verify that the first three MSIX components
match the current Flutter version.

## Signing and secret handling

Microsoft Store distribution is the production signing boundary for this MSIX
path. The Store re-signs accepted MSIX/AppX packages after certification.

Do not commit or expose:

- `.pfx` files.
- Certificate passwords.
- Private code-signing keys.
- Partner Center credentials or authentication secrets.

A certificate used only for local sideload testing must remain local and outside
Git. It must not be added to this repository or pasted into issue/PR comments.

The Store MSIX configuration intentionally contains no private signing material.

## Clean Windows release build

From a clean checkout of the release branch:

```powershell
flutter clean
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build windows --release
```

The release output must contain:

```text
build/windows/x64/runner/Release/horus.exe
```

The build must not produce `horus_system.exe` as the production executable.

## Build the Microsoft Store MSIX

After the clean Windows release build:

```powershell
dart run msix:create --build-windows false
```

With the current configuration, the expected package is:

```text
build/windows/x64/runner/Release/horus-system-store.msix
```

Do not use a manually edited generated manifest as the source of truth. The
tracked `pubspec.yaml` configuration must be sufficient to reproduce the
package from a clean checkout.

## Generated package verification

Do not close #193 based only on source configuration. Inspect the exact generated
MSIX and verify:

```text
Identity Name:        KingNarmar.HORUSSystem
Publisher:            CN=E9CE55B8-AEDA-43A1-9E0C-43ADE997A176
PublisherDisplayName: King Narmar
DisplayName:          HORUS System
Version:              1.0.0.0
Architecture:         x64
Executable:           horus.exe
Capability:           internetClient
```

Also confirm that no unexpected restricted capability or private signing
material is present.

## Windows App Certification Kit

Before Store submission:

1. Open Windows App Certification Kit from the installed Windows SDK.
2. Validate the exact generated Store MSIX.
3. Save the certification report as release evidence outside generated source
   folders.
4. Review warnings as well as the final pass/fail result.
5. Fix a real package or manifest failure; do not bypass the certification gate.

The release package must pass WACK before #193 is considered complete.

## Install, launch, update, and uninstall smoke

The release gate includes smoke testing on supported Windows 10/11 environments
as applicable:

- Install the package through an appropriate trusted/local test path or Partner
  Center testing path.
- Launch `HORUS System`.
- Verify the application reaches its normal authentication/application shell.
- Verify basic network connectivity required by the Supabase-backed SaaS client.
- Close and relaunch.
- Verify update behavior with a valid higher Store package version when an
  update test package is available.
- Uninstall and confirm the package is removed cleanly.

Local sideload signing used only for smoke testing is not the Microsoft Store
production signing model.

## Full repository verification

Before Ready/Merge:

```powershell
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
git diff --check
git status --short
```

Additionally verify:

- `flutter build windows --release` succeeds.
- The MSIX is reproducible from the tracked configuration.
- Generated identity matches Partner Center exactly.
- Package version follows the Store version rule.
- WACK passes.
- Windows install/launch/update/uninstall smoke is recorded.
- No unrelated files are included.

## Scope boundaries

Issue #193 changes Windows platform/release configuration only.

It does not change:

- Domain, Data, or Presentation business architecture.
- Supabase, database schema, migrations, RLS, or tenant isolation.
- Audit behavior.
- Business features or Product Completion.
- Production environment handling (#194).
- Privacy/legal/support surfaces (#195).
- Account deletion/data lifecycle (#196).
- Production Supabase audit (#197).
- CI/protected-main release gates (#198).
- Google Play submission readiness (#199).
- Partner Center listing copy/assets/certification submission workflow (#200).
- Final release candidate QA (#202).
- MSI/EXE distribution.

## References

- Flutter Windows deployment:
  https://docs.flutter.dev/deployment/windows
- Microsoft Store MSIX package requirements:
  https://learn.microsoft.com/windows/apps/publish/publish-your-app/msix/app-package-requirements
- Microsoft app identity details:
  https://learn.microsoft.com/windows/apps/publish/view-app-identity-details
- Microsoft MSIX supported platforms:
  https://learn.microsoft.com/windows/msix/supported-platforms
- msix package:
  https://pub.dev/packages/msix
