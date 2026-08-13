import '../../../../core/domain/value_objects/currency_code.dart';

final class ReportSourceMetadata {
  final String companyId;
  final CurrencyCode currency;
  final int baseCurrencyFractionDigits;
  final String businessTimezone;
  final DateTime businessDate;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ReportSourceMetadata({
    required this.companyId,
    required this.currency,
    required this.baseCurrencyFractionDigits,
    required this.businessTimezone,
    required this.businessDate,
    required this.fromDate,
    required this.toDate,
  });
}
