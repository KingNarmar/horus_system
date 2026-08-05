import 'package:horus_system/features/invoices/domain/services/invoice_number_formatter.dart';
import 'package:test/test.dart';

void main() {
  const formatter = InvoiceNumberFormatter();

  test('formats a company-year sequence safely', () {
    final number = formatter.format(prefix: 'inv', year: 2026, sequence: 42);

    expect(number?.value, 'INV-2026-000042');
  });

  test('rejects invalid prefixes and sequence values', () {
    expect(
      formatter.format(prefix: 'bad prefix', year: 2026, sequence: 1),
      isNull,
    );
    expect(formatter.format(prefix: 'INV', year: 2026, sequence: 0), isNull);
  });
}
