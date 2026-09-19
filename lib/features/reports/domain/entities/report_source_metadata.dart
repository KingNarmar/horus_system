import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_code.dart';

final class ReportSourceMetadata {
  final String companyId;
  final CurrencyCode currency;
  final int baseCurrencyFractionDigits;
  final String businessTimezone;
  final BusinessDate businessDate;
  final BusinessDate? fromDate;
  final BusinessDate? toDate;

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

final class OperationalReportSourceMetadata {
  final String companyId;
  final String businessTimezone;
  final BusinessDate businessDate;
  final BusinessDate? fromDate;
  final BusinessDate? toDate;

  const OperationalReportSourceMetadata({
    required this.companyId,
    required this.businessTimezone,
    required this.businessDate,
    required this.fromDate,
    required this.toDate,
  });
}
