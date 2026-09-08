import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/invoices/data/utils/invoice_data_parser.dart';
import 'package:test/test.dart';

void main() {
  group('Invoice business-date parsing', () {
    test('requiredDate preserves exact calendar date', () {
      expect(
        InvoiceDataParser.requiredDate('2026-09-07', 'issue_date'),
        BusinessDate(year: 2026, month: 9, day: 7),
      );
    });

    test('optionalDate preserves null', () {
      expect(InvoiceDataParser.optionalDate(null, 'due_date'), isNull);
    });

    test('date parser rejects timestamp-shaped values', () {
      expect(
        () => InvoiceDataParser.requiredDate(
          '2026-09-07T00:00:00Z',
          'issue_date',
        ),
        throwsFormatException,
      );
    });

    test('timestamp parser remains a distinct UTC instant boundary', () {
      final parsed = InvoiceDataParser.requiredDateTime(
        '2026-09-07T12:30:00+04:00',
        'created_at',
      );

      expect(parsed, DateTime.utc(2026, 9, 7, 8, 30));
      expect(parsed.isUtc, isTrue);
    });
  });
}
