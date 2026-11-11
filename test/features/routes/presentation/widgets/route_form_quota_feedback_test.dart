import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/widgets/app_form_failure_notice.dart';
import 'package:horus_system/features/routes/presentation/widgets/route_form_dialog.dart';
import 'package:horus_system/features/subscriptions/domain/failures/quota_failure_codes.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'Route save rejection stays in the form without a duplicate snackbar: '
      '${locale.languageCode}',
      (tester) async {
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
              body: RouteFormDialog(
                title: l10n.addRouteTitle,
                canEditFreightRate: false,
                financialConfiguration: null,
                onSubmit: (_) async {
                  submits++;
                  return const ConflictFailure(
                    code: QuotaFailureCodes.routesReached,
                  );
                },
              ),
            ),
          ),
        );

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'Dubai');
        await tester.enterText(fields.at(1), 'Sharjah');
        await tester.tap(find.widgetWithText(FilledButton, l10n.saveButton));
        await tester.pumpAndSettle();

        expect(submits, 1);
        expect(find.byType(RouteFormDialog), findsOneWidget);
        expect(find.byType(AppFormFailureNotice), findsOneWidget);
        expect(find.text(l10n.failureQuotaRoutesReached), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.text('Dubai'), findsOneWidget);
        expect(find.text('Sharjah'), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byType(RouteFormDialog))),
          locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
