# H.O.R.U.S Android Release Build

Issue: #192  
Parent release-readiness issue: #191

## Permanent Android Identity

The production Android identity is:

```text
Application ID: com.kingnarmar.horus
Namespace:      com.kingnarmar.horus
Display name:   H.O.R.U.S
```

Treat the application ID as permanent after the first Google Play publication. Do not create release variants with a different production application ID unless a deliberate migration/product decision is approved.

## SDK Baseline

The Android production build explicitly targets:

```text
compileSdk = 36
targetSdk  = 36
```

`minSdk` and `ndkVersion` continue to use the Flutter-supported project values unless a focused compatibility issue approves a change.

## Network Permission

`android.permission.INTERNET` is declared in the main production manifest because H.O.R.U.S requires network access for its Supabase-backed SaaS functionality.

The production application must not depend on debug-only manifest permissions.

## Release Signing Model

H.O.R.U.S uses a private upload keystore for Android release artifacts.

The repository contains only:

```text
android/key.properties.example
```

The following files must remain local/private and must never be committed:

```text
android/key.properties
*.jks
*.keystore
```

`android/.gitignore` already excludes those files.

The release Gradle configuration must not silently fall back to the debug signing key. A release task fails when `android/key.properties` is absent.

### 1. Generate the upload keystore

Run locally from a secure machine with a JDK installed:

```bash
keytool -genkeypair -v \
  -keystore android/horus-upload.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

On Windows PowerShell, the same command can be entered on one line.

Store the keystore and its passwords in a secure password/secret-management location. Losing the upload key creates release-operational work and must be avoided.

### 2. Create the private key properties file

Copy:

```text
android/key.properties.example
```

to:

```text
android/key.properties
```

Then replace all placeholder values with the real local values.

Example shape only:

```properties
storePassword=<private-store-password>
keyPassword=<private-key-password>
keyAlias=upload
storeFile=../horus-upload.jks
```

Do not commit the real file.

## Clean Release Build

From the repository root:

```bash
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter clean
flutter build appbundle --release
git diff --check
```

Expected Android App Bundle:

```text
build/app/outputs/bundle/release/app-release.aab
```

The release build must fail rather than use the debug key when release signing configuration is missing.

## Verify Package Identity and Manifest

The final bundle must use:

```text
com.kingnarmar.horus
```

and the merged release manifest must contain:

```text
android.permission.INTERNET
```

Use Android Studio App Inspection/Analyze APK tools or `bundletool` to inspect the built AAB. With a local `bundletool` JAR, for example:

```bash
java -jar bundletool.jar dump manifest \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --module=base
```

Confirm the package name, application label resource, launcher activity, and INTERNET permission in the final artifact rather than relying only on source files.

## Verify Target API

The final production artifact must target Android API 36 for this release baseline.

Verify the generated release manifest/bundle metadata and Google Play validation before submission. Do not assume a successful local compilation alone proves the target API used by the uploaded artifact.

## Verify Signing

The AAB must be signed by the configured release upload key, never the Flutter/Android debug key.

A local verification option is:

```bash
jarsigner -verify -verbose -certs \
  build/app/outputs/bundle/release/app-release.aab
```

For production submission, also verify the upload certificate fingerprint against the certificate registered/expected in Google Play Console.

## Verify 64-bit Native Support

Inspect the native libraries packaged in the final AAB. The bundle must include required 64-bit native architecture support for the native code it ships.

A simple inspection option is:

```bash
unzip -l build/app/outputs/bundle/release/app-release.aab
```

Review entries under `base/lib/` and confirm 64-bit ABI coverage, including `arm64-v8a` for Android ARM devices when native libraries are present.

Google Play validation remains authoritative for the Store artifact.

## Verify 16 KB Page-Size Compatibility

16 KB compatibility must be verified against the final AAB/native libraries, not inferred from Gradle configuration alone.

Using a current `bundletool` version:

```bash
java -jar bundletool.jar dump config \
  --bundle=build/app/outputs/bundle/release/app-release.aab
```

Confirm the bundle's page-alignment configuration is compatible with 16 KB devices. Where native `.so` files are packaged, also verify the ELF alignment using the current Android tooling/guidance applicable at release time.

Any incompatible third-party/native library must be addressed through a focused compatibility change; do not bypass the validation.

## Branding Boundary

Issue #192 does not invent or approve a new launcher icon.

Existing launcher assets remain until approved H.O.R.U.S branding assets are available. Store listing graphics and final branding work belong to the appropriate release/listing scope.

## Security Rules

- Never commit the upload keystore or passwords.
- Never place a Supabase service-role/admin key in the Android application.
- Only client-safe configuration may ship in the app.
- Environment/configuration hardening is tracked separately by Issue #194.
- Google Play Console setup/listing/compliance is tracked separately by Issue #199.
- Google Play Billing implementation is tracked separately and is not part of Issue #192.

## Verification Gate

Issue #192 is not complete until all of the following are verified:

- Flutter dependency resolution succeeds.
- Dart formatting check passes.
- Flutter analyze passes.
- Flutter tests pass.
- A clean signed release AAB builds successfully.
- Final artifact uses `com.kingnarmar.horus`.
- Final merged manifest contains INTERNET permission.
- Final artifact targets API 36.
- Release artifact is not signed with the debug key.
- Required 64-bit support is present.
- 16 KB page-size compatibility is verified.
- `git diff --check` passes.
- No signing secret or unrelated change appears in the PR.
