import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/trips/domain/services/trip_commercial_amount_calculator.dart';
import 'package:horus_system/features/trips/domain/value_objects/quantity_tons.dart';
import 'package:test/test.dart';

void main() {
  const calculator = TripCommercialAmountCalculator();
  final aed = CurrencyCode.tryParse('AED')!;

  group('TripCommercialAmountCalculator', () {
    test('calculates exact commercial amount without floating point', () {
      final result = calculator.tryCalculate(
        quantityTons: QuantityTons.tryParse('10.125')!,
        agreedFreightRatePerTon: Money(minorUnits: 1235, currency: aed),
      );

      expect(result, Money(minorUnits: 12504, currency: aed));
    });

    test('rounds half up exactly once at the final minor unit', () {
      final halfMinorUnit = calculator.tryCalculate(
        quantityTons: QuantityTons.tryParse('0.001')!,
        agreedFreightRatePerTon: Money(minorUnits: 500, currency: aed),
      );
      final belowHalfMinorUnit = calculator.tryCalculate(
        quantityTons: QuantityTons.tryParse('0.001')!,
        agreedFreightRatePerTon: Money(minorUnits: 499, currency: aed),
      );

      expect(halfMinorUnit, Money(minorUnits: 1, currency: aed));
      expect(belowHalfMinorUnit, Money(minorUnits: 0, currency: aed));
    });

    test('retains rate currency and handles zero values', () {
      final result = calculator.tryCalculate(
        quantityTons: QuantityTons.tryParse('0')!,
        agreedFreightRatePerTon: Money(minorUnits: 1235, currency: aed),
      );

      expect(result, Money(minorUnits: 0, currency: aed));
    });

    test('rejects negative rates', () {
      final result = calculator.tryCalculate(
        quantityTons: QuantityTons.tryParse('1')!,
        agreedFreightRatePerTon: Money(minorUnits: -1, currency: aed),
      );

      expect(result, isNull);
    });

    test('rejects commercial amounts outside signed bigint range', () {
      final result = calculator.tryCalculate(
        quantityTons: QuantityTons.tryParse('2')!,
        agreedFreightRatePerTon: Money(
          minorUnits: 9223372036854775807,
          currency: aed,
        ),
      );

      expect(result, isNull);
    });
  });
}
