$ErrorActionPreference = 'Stop'

function Replace-ExactBlock {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Old,
    [Parameter(Mandatory = $true)][string]$New
  )

  $content = Get-Content -Raw -Encoding UTF8 $Path
  if (-not $content.Contains($Old)) {
    throw "Expected block was not found in $Path. No changes were written for this replacement."
  }

  $updated = $content.Replace($Old, $New)
  Set-Content -Encoding UTF8 -NoNewline -Path $Path -Value $updated
}

$englishPath = 'lib/l10n/app_en.arb'
$arabicPath = 'lib/l10n/app_ar.arb'
$extensionPath = 'lib/core/localization/app_localizations_extension.dart'
$testPath = 'test/core/localization/app_localizations_extension_test.dart'

Replace-ExactBlock -Path $englishPath -Old @'
  "phoneNumberLabel": "Phone number",
  "phoneNumberRequired": "Phone number is required.",
  "passwordMinLength": "Password must be at least 6 characters.",
  "createAccountButton": "Create account",
  "checkYourEmailTitle": "Check your email",
'@ -New @'
  "phoneNumberLabel": "Phone number",
  "phoneNumberRequired": "Phone number is required.",
  "passwordMinLength": "Password must be at least 6 characters.",
  "failureAuthInvalidCredentials": "Incorrect email or password.",
  "failureAuthEmailNotConfirmed": "Confirm your email before signing in.",
  "failureAuthAccountAlreadyExists": "An account already exists for this email.",
  "failureAuthWeakPassword": "The password does not meet the security requirements.",
  "failureAuthInvalidEmail": "Enter a valid email address.",
  "failureAuthRateLimited": "Too many attempts. Try again later.",
  "failureAuthError": "We couldn't complete this account action. Try again.",
  "createAccountButton": "Create account",
  "checkYourEmailTitle": "Check your email",
'@

Replace-ExactBlock -Path $arabicPath -Old @'
  "phoneNumberLabel": "رقم الهاتف",
  "phoneNumberRequired": "رقم الهاتف مطلوب.",
  "passwordMinLength": "كلمة المرور يجب ألا تقل عن 6 أحرف.",
  "createAccountButton": "إنشاء الحساب",
  "checkYourEmailTitle": "راجع بريدك الإلكتروني",
'@ -New @'
  "phoneNumberLabel": "رقم الهاتف",
  "phoneNumberRequired": "رقم الهاتف مطلوب.",
  "passwordMinLength": "كلمة المرور يجب ألا تقل عن 6 أحرف.",
  "failureAuthInvalidCredentials": "البريد الإلكتروني أو كلمة المرور غير صحيحة.",
  "failureAuthEmailNotConfirmed": "أكّد بريدك الإلكتروني قبل تسجيل الدخول.",
  "failureAuthAccountAlreadyExists": "يوجد حساب بالفعل لهذا البريد الإلكتروني.",
  "failureAuthWeakPassword": "كلمة المرور لا تستوفي متطلبات الأمان.",
  "failureAuthInvalidEmail": "أدخل عنوان بريد إلكتروني صالحًا.",
  "failureAuthRateLimited": "تمت محاولات كثيرة. حاول مرة أخرى لاحقًا.",
  "failureAuthError": "تعذر إتمام إجراء الحساب. حاول مرة أخرى.",
  "createAccountButton": "إنشاء الحساب",
  "checkYourEmailTitle": "راجع بريدك الإلكتروني",
'@

Replace-ExactBlock -Path $extensionPath -Old @'
  String get _genericServerErrorMessage => failureServerError;

  String get _genericAuthErrorMessage => failureUnexpectedError;
'@ -New @'
  String get _genericServerErrorMessage => failureServerError;

  String get _genericAuthErrorMessage => failureAuthError;
'@

Replace-ExactBlock -Path $extensionPath -Old @'
      FailureCodes.authPhoneRequired => phoneNumberRequired,
      FailureCodes.authEmailNotConfirmed => checkYourEmailTitle,
      FailureCodes.authWeakPassword => passwordMinLength,
      FailureCodes.authInvalidCredentials => _genericAuthErrorMessage,
      FailureCodes.authAccountAlreadyExists => _genericAuthErrorMessage,
      FailureCodes.authInvalidEmail => _genericAuthErrorMessage,
      FailureCodes.authRateLimited => _genericAuthErrorMessage,
      FailureCodes.authError => _genericAuthErrorMessage,
'@ -New @'
      FailureCodes.authPhoneRequired => phoneNumberRequired,
      FailureCodes.authInvalidCredentials => failureAuthInvalidCredentials,
      FailureCodes.authEmailNotConfirmed => failureAuthEmailNotConfirmed,
      FailureCodes.authAccountAlreadyExists => failureAuthAccountAlreadyExists,
      FailureCodes.authWeakPassword => failureAuthWeakPassword,
      FailureCodes.authInvalidEmail => failureAuthInvalidEmail,
      FailureCodes.authRateLimited => failureAuthRateLimited,
      FailureCodes.authError => failureAuthError,
'@

Replace-ExactBlock -Path $testPath -Old @'
    testWidgets('maps stable Auth failure codes to safe English messages', (
      tester,
    ) async {
      final l10n = await _pumpLocalizations(tester, const Locale('en'));

      const genericCodes = <String>[
        FailureCodes.authInvalidCredentials,
        FailureCodes.authAccountAlreadyExists,
        FailureCodes.authInvalidEmail,
        FailureCodes.authRateLimited,
        FailureCodes.authError,
      ];

      for (final code in genericCodes) {
        expect(
          l10n.localizedErrorMessage(AuthFailure(code: code)),
          'Unexpected error occurred.',
        );
      }

      expect(
        l10n.localizedErrorMessage(
          const AuthFailure(code: FailureCodes.authEmailNotConfirmed),
        ),
        'Check your email',
      );
      expect(
        l10n.localizedErrorMessage(
          const AuthFailure(code: FailureCodes.authWeakPassword),
        ),
        'Password must be at least 6 characters.',
      );
    });

    testWidgets('maps stable Auth failure codes to safe Arabic messages', (
      tester,
    ) async {
      final l10n = await _pumpLocalizations(tester, const Locale('ar'));

      const genericCodes = <String>[
        FailureCodes.authInvalidCredentials,
        FailureCodes.authAccountAlreadyExists,
        FailureCodes.authInvalidEmail,
        FailureCodes.authRateLimited,
        FailureCodes.authError,
      ];

      for (final code in genericCodes) {
        expect(
          l10n.localizedErrorMessage(AuthFailure(code: code)),
          'حدث خطأ غير متوقع.',
        );
      }

      expect(
        l10n.localizedErrorMessage(
          const AuthFailure(code: FailureCodes.authEmailNotConfirmed),
        ),
        'راجع بريدك الإلكتروني',
      );
      expect(
        l10n.localizedErrorMessage(
          const AuthFailure(code: FailureCodes.authWeakPassword),
        ),
        'كلمة المرور يجب ألا تقل عن 6 أحرف.',
      );
    });
'@ -New @'
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

    testWidgets(
      'maps stable Auth failure codes to actionable Arabic messages',
      (tester) async {
        final l10n = await _pumpLocalizations(tester, const Locale('ar'));

        const cases = <String, String>{
          FailureCodes.authInvalidCredentials:
              'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
          FailureCodes.authEmailNotConfirmed:
              'أكّد بريدك الإلكتروني قبل تسجيل الدخول.',
          FailureCodes.authAccountAlreadyExists:
              'يوجد حساب بالفعل لهذا البريد الإلكتروني.',
          FailureCodes.authWeakPassword:
              'كلمة المرور لا تستوفي متطلبات الأمان.',
          FailureCodes.authInvalidEmail: 'أدخل عنوان بريد إلكتروني صالحًا.',
          FailureCodes.authRateLimited:
              'تمت محاولات كثيرة. حاول مرة أخرى لاحقًا.',
          FailureCodes.authError: 'تعذر إتمام إجراء الحساب. حاول مرة أخرى.',
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

Replace-ExactBlock -Path $testPath -Old @'
        'Unexpected error occurred.',
      );

      final arabic = await _pumpLocalizations(tester, const Locale('ar'));
'@ -New @'
        "We couldn't complete this account action. Try again.",
      );

      final arabic = await _pumpLocalizations(tester, const Locale('ar'));
'@

Replace-ExactBlock -Path $testPath -Old @'
        'حدث خطأ غير متوقع.',
      );
    });
'@ -New @'
        'تعذر إتمام إجراء الحساب. حاول مرة أخرى.',
      );
    });
'@

Remove-Item -LiteralPath $PSCommandPath
Write-Host 'Issue #170 Auth localization fix applied. Temporary helper removed.'
