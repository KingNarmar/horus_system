import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/payments/presentation/localization/payments_localizations.dart';

void main() {
  test('provides English payment lifecycle copy', () {
    final strings = PaymentsLocalizations.forLocale(const Locale('en'));

    expect(strings.title, 'Payments');
    expect(strings.registerPayment, 'Register payment');
    expect(strings.remaining, 'Remaining');
    expect(strings.overpaymentFailure, contains('outstanding balance'));
  });

  test('provides Arabic payment lifecycle copy', () {
    final strings = PaymentsLocalizations.forLocale(const Locale('ar'));

    expect(strings.title, 'المدفوعات');
    expect(strings.registerPayment, 'تسجيل دفعة');
    expect(strings.remaining, 'المتبقي');
    expect(strings.overpaymentFailure, contains('الرصيد المتبقي'));
  });
}
