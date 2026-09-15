import 'package:horus_system/core/domain/services/money_input_parser.dart';
import 'package:test/test.dart';

void main() {
  const parser = MoneyInputParser();

  group('MoneyInputParser', () {
    test('parses exact minor units without floating point', () {
      expect(parser.tryParseMinorUnits('12.34', fractionDigits: 2), 1234);
      expect(parser.tryParseMinorUnits(' 12.3 ', fractionDigits: 2), 1230);
      expect(parser.tryParseMinorUnits('12', fractionDigits: 2), 1200);
      expect(parser.tryParseMinorUnits('12', fractionDigits: 0), 12);
    });

    test('rejects invalid and over-precision values', () {
      expect(parser.tryParseMinorUnits('', fractionDigits: 2), isNull);
      expect(parser.tryParseMinorUnits('-1', fractionDigits: 2), isNull);
      expect(parser.tryParseMinorUnits('1.234', fractionDigits: 2), isNull);
      expect(parser.tryParseMinorUnits('1,20', fractionDigits: 2), isNull);
      expect(parser.tryParseMinorUnits('abc', fractionDigits: 2), isNull);
      expect(parser.tryParseMinorUnits('1', fractionDigits: -1), isNull);
    });

    test('rejects values outside signed bigint range', () {
      expect(
        parser.tryParseMinorUnits('92233720368547758.08', fractionDigits: 2),
        isNull,
      );
    });
  });
}
