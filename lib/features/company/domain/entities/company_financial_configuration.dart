import '../../../../core/domain/value_objects/currency_code.dart';

final class CompanyFinancialConfiguration {
  static const int minFractionDigits = 0;
  static const int maxFractionDigits = 4;

  final CurrencyCode baseCurrency;
  final int fractionDigits;

  const CompanyFinancialConfiguration({
    required this.baseCurrency,
    required this.fractionDigits,
  });

  static CompanyFinancialConfiguration? tryCreate({
    required String? baseCurrencyCode,
    required int? fractionDigits,
  }) {
    if (baseCurrencyCode == null ||
        fractionDigits == null ||
        !isValidFractionDigits(fractionDigits)) {
      return null;
    }

    final currency = CurrencyCode.tryParse(baseCurrencyCode);
    if (currency == null) return null;

    return CompanyFinancialConfiguration(
      baseCurrency: currency,
      fractionDigits: fractionDigits,
    );
  }

  static bool isValidFractionDigits(int value) {
    return value >= minFractionDigits && value <= maxFractionDigits;
  }
}
