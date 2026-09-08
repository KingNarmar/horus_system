import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:test/test.dart';

void main() {
  group('BusinessLocalDateTime', () {
    test('preserves wall-clock components without timezone semantics', () {
      final value = BusinessLocalDateTime(
        year: 2026,
        month: 9,
        day: 7,
        hour: 23,
        minute: 45,
      );

      expect(value.year, 2026);
      expect(value.month, 9);
      expect(value.day, 7);
      expect(value.hour, 23);
      expect(value.minute, 45);
    });

    test('rejects invalid date and clock components', () {
      expect(
        BusinessLocalDateTime.tryCreate(
          year: 2026,
          month: 2,
          day: 29,
          hour: 10,
          minute: 0,
        ),
        isNull,
      );
      expect(
        BusinessLocalDateTime.tryCreate(
          year: 2026,
          month: 9,
          day: 7,
          hour: 24,
          minute: 0,
        ),
        isNull,
      );
      expect(
        BusinessLocalDateTime.tryCreate(
          year: 2026,
          month: 9,
          day: 7,
          hour: 10,
          minute: 60,
        ),
        isNull,
      );
    });

    test('supports equality and chronological wall-clock ordering', () {
      final first = BusinessLocalDateTime(
        year: 2026,
        month: 9,
        day: 7,
        hour: 23,
        minute: 59,
      );
      final same = BusinessLocalDateTime(
        year: 2026,
        month: 9,
        day: 7,
        hour: 23,
        minute: 59,
      );
      final later = BusinessLocalDateTime(
        year: 2026,
        month: 9,
        day: 8,
        hour: 0,
        minute: 0,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first.isBefore(later), isTrue);
      expect(later.isAfter(first), isTrue);
    });
  });
}
