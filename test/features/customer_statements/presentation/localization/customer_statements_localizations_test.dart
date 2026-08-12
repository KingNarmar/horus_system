import 'package:flutter/widgets.dart';
import 'package:horus_system/features/customer_statements/presentation/localization/customer_statements_localizations.dart';
import 'package:test/test.dart';

void main() {
  test('provides English customer statement copy', () {
    final strings = CustomerStatementsLocalizations.forLocale(
      const Locale('en'),
    );

    expect(strings.appShellLabel, 'Customer Statements');
    expect(strings.openingBalance, 'Opening balance');
    expect(
      strings.customerOption(name: 'Customer', isActive: false),
      contains('Inactive'),
    );
  });

  test('provides Arabic customer statement copy', () {
    final strings = CustomerStatementsLocalizations.forLocale(
      const Locale('ar'),
    );

    expect(strings.appShellLabel, 'كشوف حساب العملاء');
    expect(strings.openingBalance, 'الرصيد الافتتاحي');
    expect(
      strings.customerOption(name: 'عميل', isActive: false),
      contains('غير نشط'),
    );
  });
}
