import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/customers/presentation/widgets/customer_form_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
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
