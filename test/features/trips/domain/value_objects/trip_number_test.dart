import 'package:horus_system/features/trips/domain/value_objects/trip_number.dart';
import 'package:test/test.dart';

void main() {
  group('TripNumber', () {
    test('normalizes a canonical Trip reference', () {
      final number = TripNumber.tryParse(' trp-2026-000042 ');

      expect(number?.value, 'TRP-2026-000042');
    });

    test('rejects malformed Trip references', () {
      expect(TripNumber.tryParse('TRP-26-42'), isNull);
      expect(TripNumber.tryParse('INV-2026-000042'), isNull);
      expect(TripNumber.tryParse('TRP-1999-000001'), isNull);
      expect(TripNumber.tryParse('TRP-2026-000000'), isNull);
      expect(TripNumber.tryParse('TRP-2026-0000000'), isNull);
    });

    test('compares by canonical value', () {
      final first = TripNumber.tryParse('TRP-2026-000042');
      final second = TripNumber.tryParse('trp-2026-000042');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
