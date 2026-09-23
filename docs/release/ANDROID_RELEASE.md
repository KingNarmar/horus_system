# H.O.R.U.S Android Release Foundation

Issue: #192  
Parent: #191

This document defines the Android production-release baseline for H.O.R.U.S.
It does not replace Google Play Console compliance work tracked by #199 or
production configuration hardening tracked by #194.

## Permanent production identity

The approved Android production identity is:

```text
Application ID: com.kingnarmar.horus
Namespace:      com.kingnarmar.horus
Display name:   H.O.R.U.S
```

Treat the application ID as permanent once the first Play application is
created or published. Do not introduce a second production identity without an
explicit release migration decision.

## Android SDK baseline

The production Android module explicitly uses:

```text
compileSdk = 36
targetSdk  = 36
```

The final Store artifact must be inspected to confirm its target SDK. A
successful local compilation alone is not sufficient evidence.

`minSdk` and `ndkVersion` continue to use the Flutter-supported project
values unless a focused compatibility issue approves a change.

## Production network permission

H.O.R.U.S is a Supabase-backed SaaS application. The main production manifest
therefore declares:

```text
android.permission.INTERNET
```

Release behavior must never depend on a debug-only manifest permission.

## Release signing model

H.O.R.U.S uses a private Android upload key for locally signed release bundles.
For Google Play distribution, keep the upload key separate from the Play app
signing key and verify both identities in Play Console as applicable.

The repository contains only the template:

```text
android/key.properties.example
```

The following are private and must never be committed:

```text
android/key.properties
*.jks
*.keystore
```

The Gradle release configuration intentionally fails closed when a release task
is requested without `android/key.properties`. It must never fall back to the
debug key.

### Generate the private upload keystore

Run on a secure machine with a JDK installed:

```bash
keytool -genkeypair -v \
  -keystore android/horus-upload.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Store the keystore and passwords in an approved private credential and backup
location. Do not place them in Git, source code, issue comments, build logs, or
Store listing content.

### Configure local signing

Copy:

```text
android/key.properties.example
```

to:

```text
android/key.properties
```

and replace all placeholders with the real private values.

Expected shape:

```properties
storePassword=<private-store-password>
keyPassword=<private-key-password>
keyAlias=upload
storeFile=../horus-upload.jks
```

## Clean release gate

From a clean checkout:

```bash
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter clean
flutter build appbundle --release
git diff --check
git status --short
```

The release build must fail when signing configuration is absent.

Expected AAB:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Final artifact verification

Do not close #192 based only on source inspection. Verify the exact generated
AAB.

### Package and manifest

Confirm:

```text
package/applicationId = com.kingnarmar.horus
targetSdkVersion      = 36
permission            = android.permission.INTERNET
```

A current `bundletool` can inspect the final bundle, for example:

```bash
java -jar bundletool.jar dump manifest \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --module=base
```

### Signing certificate

Verify the AAB is signed with the approved upload key and not a debug
certificate:

```bash
jarsigner -verify -verbose -certs \
  build/app/outputs/bundle/release/app-release.aab
```

Record and compare the upload-certificate fingerprint with the expected Play
Console upload certificate before submission. Do not commit private signing
material while collecting this evidence.

### 64-bit native support

Inspect `base/lib/` in the final AAB when native libraries are present.
Required native functionality must include supported 64-bit ABI coverage,
including `arm64-v8a` for Android ARM devices.

### 16 KB page-size compatibility

16 KB compatibility must be proven against the final artifact and its native
libraries; do not infer it only from Gradle settings.

Verification should include, as applicable:

1. AAB bundle configuration and page-alignment inspection.
2. ELF LOAD-segment alignment for packaged 64-bit native `.so` files.
3. APK ZIP alignment using current Android Build Tools.
4. Runtime smoke on a 16 KB emulator or device when available.
5. Google Play artifact validation.

Any incompatible dependency or native library must be fixed in a focused
compatibility change. Do not bypass the release gate.

## Gradle wrapper reproducibility

`android/gradlew`, `android/gradlew.bat`, and
`android/gradle/wrapper/gradle-wrapper.jar` are intentionally tracked. This
allows a clean checkout to use the repository's Gradle wrapper instead of
depending on untracked locally generated files.

## Branding boundary

Issue #192 locks the production package identity and Android display name. It
does not invent or redesign launcher artwork. Existing launcher assets remain
until approved H.O.R.U.S branding assets are provided through the appropriate
release or listing scope.

## Security boundaries

- Never commit keystores, signing passwords, service-role keys, or admin keys.
- Only client-safe configuration may ship in the Android application.
- Production environment and configuration hardening belongs to #194.
- Google Play Console compliance, listing, and testing belongs to #199.
- Permanent CI and protected-main gates belong to #198.
- Business features, tenant and RLS behavior, billing, and Product Completion
  are outside #192 unless a verified release blocker proves otherwise.

## Definition of done for #192

- Production application ID and namespace are locked.
- Main manifest contains INTERNET permission.
- Android release targets API 36.
- Release signing fails closed without required signing configuration.
- Clean signed AAB builds reproducibly.
- Upload signing certificate is verified.
- No signing secret is committed.
- Required 64-bit support is verified.
- 16 KB page-size compatibility is verified against the final artifact.
- Full Flutter quality gate passes.
- Repository diff and status checks are clean.
