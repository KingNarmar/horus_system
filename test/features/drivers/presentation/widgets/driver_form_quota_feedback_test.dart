import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/widgets/app_form_failure_notice.dart';
import 'package:horus_system/features/drivers/presentation/widgets/driver_form_dialog.dart';
import 'package:horus_system/features/subscriptions/domain/failures/quota_failure_codes.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'Driver save rejection preserves input in the shared failure notice: '
      '${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        var submits = 0;
        final l10n = locale.languageCode == 'ar'
            ? AppLocalizationsAr()
            : AppLocalizationsEn();

        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DriverFormDialog(
                currentBusinessDate: BusinessDate(
                  year: 2026,
                  month: 11,
                  day: 11,
                ),
                onSubmit: (_) async {
                  submits++;
                  return const ConflictFailure(
                    code: QuotaFailureCodes.driversReached,
                  );
                },
              ),
            ),
          ),
        );

        await tester.enterText(
          find.byType(TextFormField).first,
          'Driver remains editable',
        );
        await tester.tap(find.widgetWithText(FilledButton, l10n.saveButton));
        await tester.pumpAndSettle();

        expect(submits, 1);
        expect(find.byType(DriverFormDialog), findsOneWidget);
        expect(find.byType(AppFormFailureNotice), findsOneWidget);
        expect(find.text(l10n.failureQuotaDriversReached), findsOneWidget);
        expect(find.text('Driver remains editable'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(
          Directionality.of(tester.element(find.byType(DriverFormDialog))),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
