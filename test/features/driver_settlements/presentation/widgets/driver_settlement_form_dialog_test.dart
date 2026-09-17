import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/driver_settlements/presentation/widgets/driver_settlement_form_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

import 'driver_settlement_form_dialog_test_support.dart';

void main() {
  group('DriverSettlementFormDialog PC-09', () {
    testWidgets('requires a driver and exposes no manual gross salary field', (
      tester,
    ) async {
      await setFormTestSurfaceSize(tester, const Size(390, 844));
      final harness = SettlementFormTestHarness.create();
      addTearDown(harness.cubit.close);
      await harness.cubit.loadDriverSettlements(formTestCompanyContext);

      await _pumpForm(tester, harness);

      final startTop = tester
          .getTopLeft(find.byKey(const ValueKey('driverSettlementPeriodStart')))
          .dy;
      final endTop = tester
          .getTopLeft(find.byKey(const ValueKey('driverSettlementPeriodEnd')))
          .dy;
      expect(endTop, greaterThan(startTop));
      expect(
        find.byKey(const ValueKey('driverSettlementGrossSalary')),
        findsNothing,
      );

      final saveButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('driverSettlementSaveDraftButton')),
      );
      expect(saveButton.onPressed, isNull);

      await tester.tap(
        find.byKey(const ValueKey('driverSettlementCalculatePreviewButton')),
      );
      await tester.pump();

      expect(find.text('Select a driver.'), findsOneWidget);
      expect(harness.moneyRepository.snapshotCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows auto-resolved compensation as read-only preview data', (
      tester,
    ) async {
      await setFormTestSurfaceSize(tester, const Size(800, 1000));
      final harness = SettlementFormTestHarness.create();
      addTearDown(harness.cubit.close);
      await harness.cubit.loadDriverSettlements(formTestCompanyContext);

      await _pumpForm(tester, harness);

      await tester.tap(
        find.byKey(const ValueKey('driverSettlementDriverField')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Driver One').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('driverSettlementCalculatePreviewButton')),
      );
      await tester.tap(
        find.byKey(const ValueKey('driverSettlementCalculatePreviewButton')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gross salary'), findsOneWidget);
      expect(find.text('1000.00 AED'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('driverSettlementGrossSalary')),
        findsNothing,
      );
      expect(harness.moneyRepository.snapshotCalls, 1);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpForm(
  WidgetTester tester,
  SettlementFormTestHarness harness,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider.value(
          value: harness.cubit,
          child: DriverSettlementFormDialog(
            driverOptions: const [formTestActiveDriver],
            businessDate: formTestDate(2026, 7, 31),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
