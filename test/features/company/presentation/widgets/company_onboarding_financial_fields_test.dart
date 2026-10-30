import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/presentation/widgets/company_onboarding_financial_fields.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets(
      'onboarding financial fields require explicit values in ${locale.languageCode}',
      (tester) async {
        final formKey = GlobalKey<FormState>();
        final prefix = TextEditingController();
        addTearDown(prefix.dispose);

        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: CompanyOnboardingFinancialFields(
                    selectedCurrency: null,
                    fractionDigits: null,
                    invoicePrefixController: prefix,
                    onCurrencyChanged: (_) {},
                    onFractionDigitsChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        expect(formKey.currentState!.validate(), isFalse);
        await tester.pump();

        if (locale.languageCode == 'ar') {
          expect(find.text('اختر العملة الأساسية.'), findsOneWidget);
          expect(find.text('اختر عدد الخانات العشرية للعملة.'), findsOneWidget);
          expect(find.text('اكتب بادئة رقم الفاتورة.'), findsOneWidget);
        } else {
          expect(find.text('Select a base currency.'), findsOneWidget);
          expect(find.text('Select the currency fraction digits.'), findsOneWidget);
          expect(find.text('Enter an invoice prefix.'), findsOneWidget);
        }

        expect(tester.takeException(), isNull);
      },
    );
  }
}
