import 'package:horus_system/features/trips/domain/value_objects/quantity_tons.dart';
import 'package:test/test.dart';

void main() {
  group('QuantityTons', () {
    test('parses tons exactly with three decimal places', () {
      expect(QuantityTons.tryParse('12.345')?.scaledUnits, 12345);
      expect(QuantityTons.tryParse(' 12.3 ')?.scaledUnits, 12300);
      expect(QuantityTons.tryParse('12')?.scaledUnits, 12000);
      expect(QuantityTons.tryParse('0.001')?.scaledUnits, 1);
    });

    test('rejects invalid, negative, and over-precision values', () {
      expect(QuantityTons.tryParse(''), isNull);
      expect(QuantityTons.tryParse('-1'), isNull);
      expect(QuantityTons.tryParse('1.2345'), isNull);
      expect(QuantityTons.tryParse('1,25'), isNull);
      expect(QuantityTons.tryParse('abc'), isNull);
    });

    test('rejects values outside signed bigint range', () {
      expect(QuantityTons.tryParse('9223372036854775.808'), isNull);
    });

    test('serializes an exact database decimal without floating point', () {
      expect(QuantityTons.tryParse('12.345')?.toDecimalString(), '12.345');
      expect(QuantityTons.tryParse('12.3')?.toDecimalString(), '12.300');
      expect(QuantityTons.tryParse('0')?.toDecimalString(), '0.000');
    });
  });
}
