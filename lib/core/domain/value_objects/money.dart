import 'currency_code.dart';

final class Money {
  final int minorUnits;
  final CurrencyCode currency;

  const Money({required this.minorUnits, required this.currency});

  bool get isNegative => minorUnits < 0;
  bool get isZero => minorUnits == 0;
  bool get isPositive => minorUnits > 0;

  bool hasSameCurrency(Money other) => currency == other.currency;

  Money add(Money other) {
    _ensureSameCurrency(other);
    return Money(minorUnits: minorUnits + other.minorUnits, currency: currency);
  }

  Money subtract(Money other) {
    _ensureSameCurrency(other);
    return Money(minorUnits: minorUnits - other.minorUnits, currency: currency);
  }

  void _ensureSameCurrency(Money other) {
    if (!hasSameCurrency(other)) {
      throw ArgumentError('Money currencies must match.');
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Money &&
            other.minorUnits == minorUnits &&
            other.currency == currency;
  }

  @override
  int get hashCode => Object.hash(minorUnits, currency);
}
