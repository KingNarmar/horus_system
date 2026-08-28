$ErrorActionPreference = 'Stop'

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-Utf8 {
  param([Parameter(Mandatory = $true)][string]$Path)
  return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

function Write-Utf8 {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content
  )
  [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Decode-Utf8Base64 {
  param([Parameter(Mandatory = $true)][string]$Value)
  return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Value))
}

function Insert-LinesAfterKeyIfMissing {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$AnchorKey,
    [Parameter(Mandatory = $true)][string]$MissingKey,
    [Parameter(Mandatory = $true)][string]$Lines
  )

  $content = Read-Utf8 $Path
  if ($content.Contains('"' + $MissingKey + '"')) {
    return
  }

  $pattern = '(?m)^.*"' + [regex]::Escape($AnchorKey) + '"\s*:.*(?:\r?\n|$)'
  $match = [regex]::Match($content, $pattern)
  if (-not $match.Success) {
    throw "Anchor key '$AnchorKey' was not found in $Path."
  }

  $updated = $content.Insert($match.Index + $match.Length, $Lines)
  Write-Utf8 -Path $Path -Content $updated
}

function Replace-ExactIfNeeded {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Old,
    [Parameter(Mandatory = $true)][string]$New
  )

  $content = Read-Utf8 $Path
  if ($content.Contains($New)) {
    return
  }
  if (-not $content.Contains($Old)) {
    throw "Expected text was not found in $Path."
  }

  Write-Utf8 -Path $Path -Content $content.Replace($Old, $New)
}

function Replace-RegexBlockIfNeeded {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$NewMarker,
    [Parameter(Mandatory = $true)][string]$Pattern,
    [Parameter(Mandatory = $true)][string]$Replacement
  )

  $content = Read-Utf8 $Path
  if ($content.Contains($NewMarker)) {
    return
  }

  $regex = New-Object System.Text.RegularExpressions.Regex(
    $Pattern,
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )
  $match = $regex.Match($content)
  if (-not $match.Success) {
    throw "Expected test block was not found in $Path."
  }

  $updated = $content.Substring(0, $match.Index) +
    $Replacement +
    $content.Substring($match.Index + $match.Length)

  Write-Utf8 -Path $Path -Content $updated
}

$englishPath = 'lib/l10n/app_en.arb'
$arabicPath = 'lib/l10n/app_ar.arb'
$extensionPath = 'lib/core/localization/app_localizations_extension.dart'
$testPath = 'test/core/localization/app_localizations_extension_test.dart'

$englishLines = @'
  "failureAuthInvalidCredentials": "Incorrect email or password.",
  "failureAuthEmailNotConfirmed": "Confirm your email before signing in.",
  "failureAuthAccountAlreadyExists": "An account already exists for this email.",
  "failureAuthWeakPassword": "The password does not meet the security requirements.",
  "failureAuthInvalidEmail": "Enter a valid email address.",
  "failureAuthRateLimited": "Too many attempts. Try again later.",
  "failureAuthError": "We couldn't complete this account action. Try again.",
'@

Insert-LinesAfterKeyIfMissing `
  -Path $englishPath `
  -AnchorKey 'passwordMinLength' `
  -MissingKey 'failureAuthInvalidCredentials' `
  -Lines $englishLines

$arInvalidCredentials = Decode-Utf8Base64 '2KfZhNio2LHZitivINin2YTYpdmE2YPYqtix2YjZhtmKINij2Ygg2YPZhNmF2Kkg2KfZhNmF2LHZiNixINi62YrYsSDYtdit2YrYrdipLg=='
$arEmailNotConfirmed = Decode-Utf8Base64 '2KPZg9mR2K8g2KjYsdmK2K/ZgyDYp9mE2KXZhNmD2KrYsdmI2YbZiiDZgtio2YQg2KrYs9is2YrZhCDYp9mE2K/YrtmI2YQu'
$arAccountAlreadyExists = Decode-Utf8Base64 '2YrZiNis2K8g2K3Ys9in2Kgg2KjYp9mE2YHYudmEINmE2YfYsNinINin2YTYqNix2YrYryDYp9mE2KXZhNmD2KrYsdmI2YbZii4='
$arWeakPassword = Decode-Utf8Base64 '2YPZhNmF2Kkg2KfZhNmF2LHZiNixINmE2Kcg2KrYs9iq2YjZgdmKINmF2KrYt9mE2KjYp9iqINin2YTYo9mF2KfZhi4='
$arInvalidEmail = Decode-Utf8Base64 '2KPYr9iu2YQg2LnZhtmI2KfZhiDYqNix2YrYryDYpdmE2YPYqtix2YjZhtmKINi12KfZhNit2YvYpy4='
$arRateLimited = Decode-Utf8Base64 '2KrZhdiqINmF2K3Yp9mI2YTYp9iqINmD2KvZitix2KkuINit2KfZiNmEINmF2LHYqSDYo9iu2LHZiSDZhNin2K3ZgtmL2Kcu'
$arError = Decode-Utf8Base64 '2KrYudiw2LEg2KXYqtmF2KfZhSDYpdis2LHYp9ihINin2YTYrdiz2KfYqC4g2K3Yp9mI2YQg2YXYsdipINij2K7YsdmJLg=='

$arabicLines = @"
  `"failureAuthInvalidCredentials`": `"$arInvalidCredentials`",
  `"failureAuthEmailNotConfirmed`": `"$arEmailNotConfirmed`",
  `"failureAuthAccountAlreadyExists`": `"$arAccountAlreadyExists`",
  `"failureAuthWeakPassword`": `"$arWeakPassword`",
  `"failureAuthInvalidEmail`": `"$arInvalidEmail`",
  `"failureAuthRateLimited`": `"$arRateLimited`",
  `"failureAuthError`": `"$arError`",
"@

Insert-LinesAfterKeyIfMissing `
  -Path $arabicPath `
  -AnchorKey 'passwordMinLength' `
  -MissingKey 'failureAuthInvalidCredentials' `
  -Lines $arabicLines

Replace-ExactIfNeeded `
  -Path $extensionPath `
  -Old 'String get _genericAuthErrorMessage => failureUnexpectedError;' `
  -New 'String get _genericAuthErrorMessage => failureAuthError;'

Replace-ExactIfNeeded -Path $extensionPath `
  -Old 'FailureCodes.authEmailNotConfirmed => checkYourEmailTitle,' `
  -New 'FailureCodes.authEmailNotConfirmed => failureAuthEmailNotConfirmed,'
Replace-ExactIfNeeded -Path $extensionPath `
  -Old 'FailureCodes.authWeakPassword => passwordMinLength,' `
  -New 'FailureCodes.authWeakPassword => failureAuthWeakPassword,'
Replace-ExactIfNeeded -Path $extensionPath `
  -Old 'FailureCodes.authInvalidCredentials => _genericAuthErrorMessage,' `
  -New 'FailureCodes.authInvalidCredentials => failureAuthInvalidCredentials,'
Replace-ExactIfNeeded -Path $extensionPath `
  -Old 'FailureCodes.authAccountAlreadyExists => _genericAuthErrorMessage,' `
  -New 'FailureCodes.authAccountAlreadyExists => failureAuthAccountAlreadyExists,'
Replace-ExactIfNeeded -Path $extensionPath `
  -Old 'FailureCodes.authInvalidEmail => _genericAuthErrorMessage,' `
  -New 'FailureCodes.authInvalidEmail => failureAuthInvalidEmail,'
Replace-ExactIfNeeded -Path $extensionPath `
  -Old 'FailureCodes.authRateLimited => _genericAuthErrorMessage,' `
  -New 'FailureCodes.authRateLimited => failureAuthRateLimited,'
Replace-ExactIfNeeded -Path $extensionPath `
  -Old 'FailureCodes.authError => _genericAuthErrorMessage,' `
  -New 'FailureCodes.authError => failureAuthError,'

$englishTestBlock = @'
    testWidgets(
      'maps stable Auth failure codes to actionable English messages',
      (tester) async {
        final l10n = await _pumpLocalizations(tester, const Locale('en'));

        const cases = <String, String>{
          FailureCodes.authInvalidCredentials: 'Incorrect email or password.',
          FailureCodes.authEmailNotConfirmed:
              'Confirm your email before signing in.',
          FailureCodes.authAccountAlreadyExists:
              'An account already exists for this email.',
          FailureCodes.authWeakPassword:
              'The password does not meet the security requirements.',
          FailureCodes.authInvalidEmail: 'Enter a valid email address.',
          FailureCodes.authRateLimited: 'Too many attempts. Try again later.',
          FailureCodes.authError:
              "We couldn't complete this account action. Try again.",
        };

        for (final entry in cases.entries) {
          expect(
            l10n.localizedErrorMessage(AuthFailure(code: entry.key)),
            entry.value,
          );
        }
      },
    );

'@

Replace-RegexBlockIfNeeded `
  -Path $testPath `
  -NewMarker 'maps stable Auth failure codes to actionable English messages' `
  -Pattern "    testWidgets\('maps stable Auth failure codes to safe English messages'.*?(?=    testWidgets\('maps stable Auth failure codes to safe Arabic messages')" `
  -Replacement $englishTestBlock

$arabicTestBlock = @"
    testWidgets(
      'maps stable Auth failure codes to actionable Arabic messages',
      (tester) async {
        final l10n = await _pumpLocalizations(tester, const Locale('ar'));

        const cases = <String, String>{
          FailureCodes.authInvalidCredentials:
              '$arInvalidCredentials',
          FailureCodes.authEmailNotConfirmed:
              '$arEmailNotConfirmed',
          FailureCodes.authAccountAlreadyExists:
              '$arAccountAlreadyExists',
          FailureCodes.authWeakPassword:
              '$arWeakPassword',
          FailureCodes.authInvalidEmail: '$arInvalidEmail',
          FailureCodes.authRateLimited:
              '$arRateLimited',
          FailureCodes.authError: '$arError',
        };

        for (final entry in cases.entries) {
          expect(
            l10n.localizedErrorMessage(AuthFailure(code: entry.key)),
            entry.value,
          );
        }
      },
    );

"@

Replace-RegexBlockIfNeeded `
  -Path $testPath `
  -NewMarker 'maps stable Auth failure codes to actionable Arabic messages' `
  -Pattern "    testWidgets\('maps stable Auth failure codes to safe Arabic messages'.*?(?=    testWidgets\('does not expose raw unknown Auth failure messages')" `
  -Replacement $arabicTestBlock

$unknownAuthTestBlock = @"
    testWidgets(
      'does not expose raw unknown Auth failure messages through safe fallback',
      (tester) async {
        final english = await _pumpLocalizations(tester, const Locale('en'));

        expect(
          english.localizedErrorMessage(
            const AuthFailure(
              code: 'future_auth_failure',
              message: 'private backend auth detail',
            ),
          ),
          `"We couldn't complete this account action. Try again.`",
        );

        final arabic = await _pumpLocalizations(tester, const Locale('ar'));

        expect(
          arabic.localizedErrorMessage(
            const AuthFailure(
              code: 'future_auth_failure',
              message: 'private backend auth detail',
            ),
          ),
          '$arError',
        );
      },
    );

"@

Replace-RegexBlockIfNeeded `
  -Path $testPath `
  -NewMarker 'does not expose raw unknown Auth failure messages through safe fallback' `
  -Pattern "    testWidgets\('does not expose raw unknown Auth failure messages'.*?(?=    testWidgets\('localizes audit validation failure codes in English')" `
  -Replacement $unknownAuthTestBlock

Remove-Item -LiteralPath $PSCommandPath
Write-Host 'Issue #170 Auth localization fix applied. Temporary helper removed.'
