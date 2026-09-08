import 'package:horus_system/core/data/utils/db_timestamp.dart';
import 'package:test/test.dart';

void main() {
  group('DbTimestamp', () {
    test('decodes a UTC timestamp as a UTC instant', () {
      final value = DbTimestamp.decode('2026-09-07T08:30:00.000Z');

      expect(value, DateTime.utc(2026, 9, 7, 8, 30));
      expect(value.isUtc, isTrue);
    });

    test('normalizes an offset timestamp to UTC', () {
      final value = DbTimestamp.decode('2026-09-07T12:30:00+04:00');

      expect(value, DateTime.utc(2026, 9, 7, 8, 30));
      expect(value.isUtc, isTrue);
    });

    test('rejects timezone-less values at the database boundary', () {
      expect(
        () => DbTimestamp.decode('2026-09-07T08:30:00'),
        throwsFormatException,
      );
      expect(() => DbTimestamp.decode('2026-09-07'), throwsFormatException);
      expect(
        () => DbTimestamp.decode(DateTime(2026, 9, 7, 8, 30)),
        throwsFormatException,
      );
    });

    test('preserves nullable timestamps without inventing a value', () {
      expect(DbTimestamp.decodeNullable(null), isNull);
      expect(
        DbTimestamp.decodeNullable('2026-09-07T08:30:00Z'),
        DateTime.utc(2026, 9, 7, 8, 30),
      );
    });

    test('encodes an instant as UTC ISO text', () {
      expect(
        DbTimestamp.encode(DateTime.utc(2026, 9, 7, 8, 30)),
        '2026-09-07T08:30:00.000Z',
      );
      expect(DbTimestamp.encodeNullable(null), isNull);
    });
  });
}
