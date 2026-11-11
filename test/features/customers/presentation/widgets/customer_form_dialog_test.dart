import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/widgets/app_form_failure_notice.dart';
import 'package:horus_system/features/subscriptions/domain/failures/quota_failure_codes.dart';
import 'package:horus_system/features/customers/presentation/widgets/customer_form_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'quota refusal keeps customer inputs and shows localized failure: ${locale.languageCode}',
      (tester) async {
        var submitted = 0;
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CustomerFormDialog(
                onSubmit: (_) async {
                  submitted++;
                  return const ConflictFailure(
                    code: QuotaFailureCodes.customersReached,
                  );
                },
              ),
            ),
          ),
        );

        await tester.enterText(
          find.byType(TextFormField).first,
          'Customer preserved',
        );
        await tester.tap(
          find.widgetWithText(
            FilledButton,
            locale.languageCode == 'ar'
                ? AppLocalizationsAr().saveButton
                : AppLocalizationsEn().saveButton,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final expected = locale.languageCode == 'ar'
            ? AppLocalizationsAr().failureQuotaCustomersReached
            : AppLocalizationsEn().failureQuotaCustomersReached;
        expect(submitted, 1);
        expect(find.text('Customer preserved'), findsOneWidget);
        expect(find.text(expected), findsOneWidget);
        expect(find.byType(AppFormFailureNotice), findsOneWidget);
        // Error must be visible without scrolling long form fields.
        final noticeTop = tester
            .getTopLeft(find.byType(AppFormFailureNotice))
            .dy;
        final formScrollTop = tester
            .getTopLeft(find.byType(SingleChildScrollView).first)
            .dy;
        expect(noticeTop, lessThan(formScrollTop));
        expect(find.byType(CustomerFormDialog), findsOneWidget);
        if (locale.languageCode == 'ar') {
          expect(
            Directionality.of(tester.element(find.byType(CustomerFormDialog))),
            TextDirection.rtl,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('rejects malformed optional customer email before submission', (
    tester,
  ) async {
    var submitCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomerFormDialog(
            onSubmit: (_) async {
              submitCalls++;
              return null;
            },
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Customer');
    await tester.enterText(fields.at(3), 'invalid-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(submitCalls, 0);
  });
}
