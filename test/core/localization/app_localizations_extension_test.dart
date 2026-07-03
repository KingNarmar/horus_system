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
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
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

      final message = capturedContext.l10n.localizedErrorMessage(
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
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
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

      final message = capturedContext.l10n.localizedErrorMessage(
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
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
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

      final message = capturedContext.l10n.localizedErrorMessage(
        const UnexpectedFailure(message: 'Null check operator used on null'),
      );

      expect(message, 'Unexpected error occurred.');
    });
  });
}
