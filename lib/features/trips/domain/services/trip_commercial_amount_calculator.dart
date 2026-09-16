import '../../../../core/domain/value_objects/money.dart';
import '../value_objects/quantity_tons.dart';

final class TripCommercialAmountCalculator {
  static final BigInt _maxSignedBigInt = BigInt.parse('9223372036854775807');

  const TripCommercialAmountCalculator();

  Money? tryCalculate({
    required QuantityTons quantityTons,
    required Money agreedFreightRatePerTon,
  }) {
    if (agreedFreightRatePerTon.isNegative) return null;

    final numerator =
        BigInt.from(agreedFreightRatePerTon.minorUnits) *
        BigInt.from(quantityTons.scaledUnits);
    final denominator = BigInt.from(QuantityTons.scale);
    final halfDenominator = denominator ~/ BigInt.from(2);
    final roundedMinorUnits = (numerator + halfDenominator) ~/ denominator;

    if (roundedMinorUnits > _maxSignedBigInt) return null;

    return Money(
      minorUnits: roundedMinorUnits.toInt(),
      currency: agreedFreightRatePerTon.currency,
    );
  }
}
