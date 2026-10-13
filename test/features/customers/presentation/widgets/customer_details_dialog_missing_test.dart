import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/customers/presentation/dialogs/customer_details_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets('removed customer dialog renders no stale business fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomerDetailsDialog(customer: null, state: null),
        ),
      ),
    );

    expect(
      find.text('Customer details are no longer available.'),
      findsOneWidget,
    );
    expect(find.byType(CustomerDetailsDialog), findsOneWidget);
  });
}
