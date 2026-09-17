import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';
import 'package:horus_system/features/driver_finance/presentation/widgets/driver_financial_movement_form_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('submits trusted date and decimal text unchanged', (
    tester,
  ) async {
    final initialDate = BusinessDate(year: 2026, month: 9, day: 8);
    BusinessDate? submittedDate;
    String? submittedAmount;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DriverFinancialMovementFormDialog(
            movementType: DriverFinancialMovementType.advance,
            initialMovementDate: initialDate,
            tripOptions: const [],
            isTripOptionsLoading: false,
            tripOptionsFailure: null,
            onSubmit:
                ({
                  required String amount,
                  required BusinessDate movementDate,
                  String? tripId,
                  String? notes,
                }) async {
                  submittedAmount = amount;
                  submittedDate = movementDate;
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('2026-09-08'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '125.500');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(submittedAmount, '125.500');
    expect(submittedDate, initialDate);
  });
}
