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
    expect(arabic.statusCancelled, 'ملغاة');
    expect(english.newDraft, 'New invoice');
    expect(arabic.tripRequired, 'اختر رحلة واحدة قابلة للفوترة.');
    expect(
      english.tripOption('LO-1', 'AED 100.00'),
      'LO-1 • AED 100.00',
    );
  });
}
