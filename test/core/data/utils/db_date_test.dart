import 'package:horus_system/core/data/utils/db_date.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:test/test.dart';

void main() {
  group('DbDate', () {
    test('encodes a business date as PostgreSQL date text', () {
      final date = BusinessDate(year: 2026, month: 9, day: 7);

      expect(DbDate.encode(date), '2026-09-07');
    });

    test('decodes strict PostgreSQL date text', () {
      final date = DbDate.decode('2026-09-07');

      expect(date, BusinessDate(year: 2026, month: 9, day: 7));
    });

    test('rejects timestamps and invalid dates', () {
      expect(
        () => DbDate.decode('2026-09-07T00:00:00Z'),
        throwsFormatException,
      );
      expect(() => DbDate.decode('2026-02-29'), throwsFormatException);
      expect(() => DbDate.decode(null), throwsFormatException);
    });

    test('decodes nullable database dates without inventing a value', () {
      expect(DbDate.decodeNullable(null), isNull);
      expect(
        DbDate.decodeNullable('2026-12-31'),
        BusinessDate(year: 2026, month: 12, day: 31),
      );
    });
  });
}
