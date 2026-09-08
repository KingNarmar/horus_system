import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/utils/business_date_date_time_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('BusinessDateDateTimeAdapter', () {
    test('copies picker components into a BusinessDate', () {
      final value = BusinessDateDateTimeAdapter.fromDateTime(
        DateTime(2026, 9, 7, 23, 59),
      );

      expect(value, BusinessDate(year: 2026, month: 9, day: 7));
    });

    test('creates a picker DateTime without timezone conversion', () {
      final value = BusinessDateDateTimeAdapter.toDateTime(
        BusinessDate(year: 2026, month: 9, day: 7),
      );

      expect(value.year, 2026);
      expect(value.month, 9);
      expect(value.day, 7);
      expect(value.hour, 0);
      expect(value.isUtc, isFalse);
    });
  });
}
