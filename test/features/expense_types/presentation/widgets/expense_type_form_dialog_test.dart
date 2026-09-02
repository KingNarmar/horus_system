import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/expense_types/presentation/localization/expense_types_localizations.dart';
import 'package:horus_system/features/expense_types/presentation/widgets/expense_type_form_dialog.dart';

void main() {
  testWidgets('form validates required name before submission', (tester) async {
    var submitCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ExpenseTypeFormDialog(
          onSubmit: (name) async {
            submitCalls += 1;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Expense type name is required.'), findsOneWidget);
    expect(submitCalls, 0);
  });

  test(
    'feature localization contains matching English and Arabic concepts',
    () {
      final english = ExpenseTypesLocalizations.forLocale(const Locale('en'));
      final arabic = ExpenseTypesLocalizations.forLocale(const Locale('ar'));

      expect(english.title, 'Expense types');
      expect(arabic.title, 'أنواع المصروفات');
      expect(english.addType, isNotEmpty);
      expect(arabic.addType, isNotEmpty);
      expect(english.duplicateNameFailure, isNotEmpty);
      expect(arabic.duplicateNameFailure, isNotEmpty);
      expect(english.confirmDeactivateBody, isNotEmpty);
      expect(arabic.confirmDeactivateBody, isNotEmpty);
    },
  );
}
