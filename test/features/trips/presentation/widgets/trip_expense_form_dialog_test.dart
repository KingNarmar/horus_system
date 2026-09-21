import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/trips/presentation/widgets/trip_expense_form_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('uses the trusted business date as the expense default', (
    tester,
  ) async {
    final businessDate = BusinessDate(year: 2026, month: 9, day: 19);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TripExpenseFormDialog(
            initialExpenseDate: businessDate,
            expenseTypes: const [],
            expenseTypesFailure: null,
            onSubmit: (_) async {},
          ),
        ),
      ),
    );

    expect(find.text('2026-09-19'), findsOneWidget);
  });
}
