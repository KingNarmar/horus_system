import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:test/test.dart';

void main() {
  test('serializes stable lifecycle values', () {
    expect(InvoiceStatus.draft.value, 'draft');
    expect(InvoiceStatus.issued.value, 'issued');
    expect(InvoiceStatus.cancelled.value, 'cancelled');
  });

  test('parses known values without unsafe fallbacks', () {
    expect(InvoiceStatus.tryFromValue(' ISSUED '), InvoiceStatus.issued);
    expect(InvoiceStatus.tryFromValue('unknown'), isNull);
  });
}
