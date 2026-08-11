import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/invoices/presentation/localization/invoices_localizations.dart';

void main() {
  test('provides matching English and Arabic invoice labels', () {
    final english = InvoicesLocalizations.forLocale(const Locale('en'));
    final arabic = InvoicesLocalizations.forLocale(const Locale('ar'));

    expect(english.title, 'Invoices');
    expect(arabic.title, 'الفواتير');
    expect(english.statusIssued, 'Issued');
    expect(english.statusPartiallyPaid, 'Partially paid');
    expect(arabic.statusPartiallyPaid, 'مدفوعة جزئيًا');
    expect(english.statusPaid, 'Paid');
    expect(arabic.statusPaid, 'مدفوعة');
    expect(arabic.statusCancelled, 'ملغاة');
    expect(english.invoiceHasPaymentsFailure, contains('payments'));
    expect(arabic.invoiceHasPaymentsFailure, contains('مدفوعات'));
    expect(english.newDraft, 'New invoice');
    expect(arabic.tripRequired, 'اختر رحلة واحدة قابلة للفوترة.');
    expect(english.tripOption('LO-1', 'AED 100.00'), 'LO-1 • AED 100.00');
  });
}
