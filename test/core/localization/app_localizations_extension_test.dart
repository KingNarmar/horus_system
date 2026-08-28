import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/localization/app_localizations_extension.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  group('CommonErrorLocalizationsX', () {
    testWidgets('does not expose raw server failure messages in English', (
      tester,
    ) async {
      final l10n = await _pumpLocalizations(tester, const Locale('en'));

      final message = l10n.localizedErrorMessage(
        const ServerFailure(
          code: '23505',
          message: 'duplicate key value violates unique constraint',
        ),
      );

      expect(message, 'Server error occurred.');
    });

    testWidgets('does not expose raw server failure messages in Arabic', (
      tester,
    ) async {
      final l10n = await _pumpLocalizations(tester, const Locale('ar'));

      final message = l10n.localizedErrorMessage(
        const ServerFailure(
          code: FailureCodes.serverError,
          message: 'relation public.secret_table does not exist',
        ),
      );

      expect(message, 'حدث خطأ في الخادم.');
    });

    testWidgets('does not expose raw unexpected failure messages', (
      tester,
    ) async {
      final l10n = await _pumpLocalizations(tester, const Locale('en'));

      final message = l10n.localizedErrorMessage(
        const UnexpectedFailure(message: 'Null check operator used on null'),
      );

      expect(message, 'Unexpected error occurred.');
    });

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

    testWidgets('does not expose raw unknown Auth failure messages', (
      tester,
    ) async {
      final english = await _pumpLocalizations(tester, const Locale('en'));

      expect(
        english.localizedErrorMessage(
          const AuthFailure(
            code: 'future_auth_failure',
            message: 'private backend auth detail',
          ),
        ),
        'Unexpected error occurred.',
      );

      final arabic = await _pumpLocalizations(tester, const Locale('ar'));

      expect(
        arabic.localizedErrorMessage(
          const AuthFailure(
            code: 'future_auth_failure',
            message: 'private backend auth detail',
          ),
        ),
        'حدث خطأ غير متوقع.',
      );
    });

    testWidgets('localizes audit validation failure codes in English', (
      tester,
    ) async {
      final l10n = await _pumpLocalizations(tester, const Locale('en'));

      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationAuditEntityIdRequired,
          ),
        ),
        'Audit entity id is required.',
      );
      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationAuditDescriptionRequired,
          ),
        ),
        'Audit description is required.',
      );
      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationCompanyIdRequired,
          ),
        ),
        'Company id is required.',
      );
    });

    testWidgets('localizes audit validation failure codes in Arabic', (
      tester,
    ) async {
      final l10n = await _pumpLocalizations(tester, const Locale('ar'));

      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationAuditEntityIdRequired,
          ),
        ),
        'معرّف سجل المراجعة مطلوب.',
      );
      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationAuditDescriptionRequired,
          ),
        ),
        'وصف سجل المراجعة مطلوب.',
      );
      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationCompanyIdRequired,
          ),
        ),
        'معرّف الشركة مطلوب.',
      );
    });

    testWidgets('localizes customer failure codes in English', (tester) async {
      final l10n = await _pumpLocalizations(tester, const Locale('en'));

      expect(
        l10n.localizedErrorMessage(
          const PermissionFailure(code: FailureCodes.permissionCustomersView),
        ),
        'Customers access is not allowed.',
      );
      expect(
        l10n.localizedErrorMessage(
          const PermissionFailure(
            code: FailureCodes.permissionCustomersManagement,
          ),
        ),
        'Customers management is not allowed.',
      );
      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationCustomerIdRequired,
          ),
        ),
        'Customer id is required.',
      );
      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationCustomerNameRequired,
          ),
        ),
        'Customer name is required.',
      );
      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationCreditLimitNegative,
          ),
        ),
        'Credit limit cannot be negative.',
      );
    });

    testWidgets('localizes customer failure codes in Arabic', (tester) async {
      final l10n = await _pumpLocalizations(tester, const Locale('ar'));

      expect(
        l10n.localizedErrorMessage(
          const PermissionFailure(code: FailureCodes.permissionCustomersView),
        ),
        'لا يوجد صلاحية للوصول إلى العملاء.',
      );
      expect(
        l10n.localizedErrorMessage(
          const PermissionFailure(
            code: FailureCodes.permissionCustomersManagement,
          ),
        ),
        'لا يوجد صلاحية لإدارة العملاء.',
      );
      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationCustomerIdRequired,
          ),
        ),
        'معرّف العميل مطلوب.',
      );
      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationCustomerNameRequired,
          ),
        ),
        'اسم العميل مطلوب.',
      );
      expect(
        l10n.localizedErrorMessage(
          const ValidationFailure(
            code: FailureCodes.validationCreditLimitNegative,
          ),
        ),
        'حد الائتمان لا يمكن أن يكون رقمًا سالبًا.',
      );
    });
  });
}

Future<AppLocalizations> _pumpLocalizations(
  WidgetTester tester,
  Locale locale,
) async {
  late BuildContext capturedContext;

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  return capturedContext.l10n;
}
