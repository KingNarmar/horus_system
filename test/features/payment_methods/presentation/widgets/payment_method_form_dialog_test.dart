import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/payment_methods/presentation/localization/payment_methods_localizations.dart';
import 'package:horus_system/features/payment_methods/presentation/widgets/payment_method_form_dialog.dart';

void main() {
  testWidgets('form validates required name before submission', (tester) async {
    var submitCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentMethodFormDialog(
          onSubmit: (name) async {
            submitCalls += 1;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Payment method name is required.'), findsOneWidget);
    expect(submitCalls, 0);
  });

  test(
    'feature localization contains matching English and Arabic concepts',
    () {
      final english = PaymentMethodsLocalizations.forLocale(const Locale('en'));
      final arabic = PaymentMethodsLocalizations.forLocale(const Locale('ar'));

      expect(english.title, 'Payment methods');
      expect(arabic.title, 'طرق الدفع');
      expect(english.addMethod, isNotEmpty);
      expect(arabic.addMethod, isNotEmpty);
      expect(english.duplicateNameFailure, isNotEmpty);
      expect(arabic.duplicateNameFailure, isNotEmpty);
    },
  );
}
