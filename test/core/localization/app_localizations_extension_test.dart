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
