import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/routes/presentation/widgets/route_form_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  for (final roleCanEdit in [false, true]) {
    testWidgets('Route freight field visibility: $roleCanEdit', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RouteFormDialog(
              title: 'Route',
              canEditFreightRate: roleCanEdit,
              financialConfiguration: null,
              onSubmit: (_) async => true,
            ),
          ),
        ),
      );
      final finder = find.text(
        AppLocalizationsEn().routeDefaultFreightRatePerTonLabel,
      );
      expect(finder, roleCanEdit ? findsOneWidget : findsNothing);
    });
  }
}
