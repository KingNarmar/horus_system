import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:test/test.dart';

void main() {
  group('CurrencyCode', () {
    test('normalizes valid ISO-style codes', () {
      expect(CurrencyCode.tryParse(' aed ')?.value, 'AED');
    });

    test('rejects invalid codes', () {
      expect(CurrencyCode.tryParse('AE'), isNull);
      expect(CurrencyCode.tryParse('AED1'), isNull);
    });
  });

  group('Money', () {
    final aed = CurrencyCode.tryParse('AED')!;
    final usd = CurrencyCode.tryParse('USD')!;

    test('adds and subtracts matching currencies using minor units', () {
      final first = Money(minorUnits: 10025, currency: aed);
      final second = Money(minorUnits: 975, currency: aed);

      expect(first.add(second).minorUnits, 11000);
      expect(first.subtract(second).minorUnits, 9050);
    });

    test('rejects arithmetic across currencies', () {
      final first = Money(minorUnits: 100, currency: aed);
      final second = Money(minorUnits: 100, currency: usd);

      expect(() => first.add(second), throwsArgumentError);
    });
  });
}
