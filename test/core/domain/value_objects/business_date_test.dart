import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:test/test.dart';

void main() {
  group('BusinessDate', () {
    test('creates a valid calendar date', () {
      final date = BusinessDate(year: 2026, month: 9, day: 7);

      expect(date.year, 2026);
      expect(date.month, 9);
      expect(date.day, 7);
    });

    test('rejects invalid calendar dates', () {
      expect(
        () => BusinessDate(year: 2026, month: 2, day: 29),
        throwsArgumentError,
      );
      expect(
        () => BusinessDate(year: 2026, month: 13, day: 1),
        throwsArgumentError,
      );
      expect(
        () => BusinessDate(year: 0, month: 1, day: 1),
        throwsArgumentError,
      );
    });

    test('supports Gregorian leap-year rules', () {
      expect(BusinessDate.tryCreate(year: 2024, month: 2, day: 29), isNotNull);
      expect(BusinessDate.tryCreate(year: 2100, month: 2, day: 29), isNull);
      expect(BusinessDate.tryCreate(year: 2000, month: 2, day: 29), isNotNull);
    });

    test('compares dates without time or timezone semantics', () {
      final first = BusinessDate(year: 2026, month: 9, day: 7);
      final same = BusinessDate(year: 2026, month: 9, day: 7);
      final later = BusinessDate(year: 2027, month: 1, day: 1);

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first.compareTo(same), 0);
      expect(first.isBefore(later), isTrue);
      expect(later.isAfter(first), isTrue);
    });

    test('advances to the next business date without timezone semantics', () {
      expect(
        BusinessDate(year: 2026, month: 9, day: 8).nextDay,
        BusinessDate(year: 2026, month: 9, day: 9),
      );
      expect(
        BusinessDate(year: 2026, month: 9, day: 30).nextDay,
        BusinessDate(year: 2026, month: 10, day: 1),
      );
      expect(
        BusinessDate(year: 2026, month: 12, day: 31).nextDay,
        BusinessDate(year: 2027, month: 1, day: 1),
      );
      expect(
        BusinessDate(year: 2024, month: 2, day: 28).nextDay,
        BusinessDate(year: 2024, month: 2, day: 29),
      );
    });

    test('does not advance beyond the supported calendar range', () {
      expect(
        () => BusinessDate(year: 9999, month: 12, day: 31).nextDay,
        throwsStateError,
      );
    });
  });
}
