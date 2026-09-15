import 'currency_code.dart';

final class CurrencyConfiguration {
  static const int minFractionDigits = 0;
  static const int maxFractionDigits = 4;

  final CurrencyCode currency;
  final int fractionDigits;

  const CurrencyConfiguration({
    required this.currency,
    required this.fractionDigits,
  });

  static CurrencyConfiguration? tryCreate({
    required String? currencyCode,
    required int? fractionDigits,
  }) {
    if (currencyCode == null || fractionDigits == null) return null;
    if (fractionDigits < minFractionDigits ||
        fractionDigits > maxFractionDigits) {
      return null;
    }

    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null) return null;

    return CurrencyConfiguration(
      currency: currency,
      fractionDigits: fractionDigits,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CurrencyConfiguration &&
            other.currency == currency &&
            other.fractionDigits == fractionDigits;
  }

  @override
  int get hashCode => Object.hash(currency, fractionDigits);
}
