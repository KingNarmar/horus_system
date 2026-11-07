import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/routes/domain/entities/route_entity.dart';
import 'package:horus_system/features/routes/presentation/localization/routes_localizations_x.dart';
import 'package:horus_system/features/routes/presentation/widgets/route_form_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  testWidgets('existing Route never exposes initial pricing field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RouteFormDialog(
            title: 'Route',
            canEditFreightRate: true,
            route: const RouteEntity(
              id: 'route-1',
              companyId: 'company-1',
              loadingLocation: 'Dubai',
              unloadingLocation: 'Abu Dhabi',
              isActive: true,
            ),
            financialConfiguration: null,
            onSubmit: (_) async => true,
          ),
        ),
      ),
    );
    expect(
      find.text(AppLocalizationsEn().routeDefaultFreightRatePerTonLabel),
      findsNothing,
    );
  });

  for (final roleCanEdit in [false, true]) {
    testWidgets('Route freight field visibility: $roleCanEdit', (tester) async {
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
