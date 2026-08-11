import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:test/test.dart';

void main() {
  test('serializes stable lifecycle values', () {
    expect(InvoiceStatus.draft.value, 'draft');
    expect(InvoiceStatus.issued.value, 'issued');
    expect(InvoiceStatus.partiallyPaid.value, 'partially_paid');
    expect(InvoiceStatus.paid.value, 'paid');
    expect(InvoiceStatus.cancelled.value, 'cancelled');
  });

  test('parses known values without unsafe fallbacks', () {
    expect(InvoiceStatus.tryFromValue(' ISSUED '), InvoiceStatus.issued);
    expect(
      InvoiceStatus.tryFromValue(' PARTIALLY_PAID '),
      InvoiceStatus.partiallyPaid,
    );
    expect(InvoiceStatus.tryFromValue('PAID'), InvoiceStatus.paid);
    expect(InvoiceStatus.tryFromValue('unknown'), isNull);
  });
}
