import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/audit/presentation/helpers/audit_change_builder.dart';
import 'package:horus_system/features/fleet/presentation/widgets/fleet_audit_change_row.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('Fleet audit keeps long values readable in ${locale.languageCode}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final l10n = locale.languageCode == 'ar'
          ? AppLocalizationsAr()
          : AppLocalizationsEn();
      const oldFileName = 'Golden Hour Life Partner Ad with a very long name.png';
      const newFileName = 'BootStrap.png';

      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  FleetAuditChangeRow(
                    change: AuditChange(
                      label: l10n.fleetLicenseDocumentFileNameField,
                      oldValue: oldFileName,
                      newValue: newFileName,
                    ),
                  ),
                  FleetAuditChangeRow(
                    change: AuditChange(
                      label: l10n.fleetLicenseDocumentMimeTypeField,
                      oldValue: 'image/jpeg',
                      newValue: 'image/png',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text(l10n.fleetAuditPreviousValueLabel), findsNWidgets(2));
      expect(find.text(l10n.fleetAuditNewValueLabel), findsNWidgets(2));
      expect(find.text(oldFileName), findsOneWidget);
      expect(find.text(newFileName), findsOneWidget);
      expect(find.text('image/png'), findsOneWidget);
      expect(tester.widget<Text>(find.text('image/png')).textDirection, TextDirection.ltr);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Arabic audit values retain RTL direction', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: FleetAuditChangeRow(
            change: AuditChange(
              label: 'الحالة',
              oldValue: 'غير متاح',
              newValue: 'نشط',
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('غير متاح')).textDirection,
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}
