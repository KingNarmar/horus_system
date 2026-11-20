import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_code.dart';

final class ReportSourceMetadata {
  final String companyId;
  final CurrencyCode currency;
  final int baseCurrencyFractionDigits;
  final String businessTimezone;
  final BusinessDate businessDate;

  /// Server source-read start, not document generation time.
  /// Null while older hosted environments await the migration.
  final DateTime? sourceAsOfUtc;
  final BusinessDate? fromDate;
  final BusinessDate? toDate;

  const ReportSourceMetadata({
    required this.companyId,
    required this.currency,
    required this.baseCurrencyFractionDigits,
    required this.businessTimezone,
    required this.businessDate,
    this.sourceAsOfUtc,
    required this.fromDate,
    required this.toDate,
  });
}

final class OperationalReportSourceMetadata {
  final String companyId;
  final String businessTimezone;
  final BusinessDate businessDate;

  /// Server source-read start, not document generation time.
  /// Null while older hosted environments await the migration.
  final DateTime? sourceAsOfUtc;
  final BusinessDate? fromDate;
  final BusinessDate? toDate;

  const OperationalReportSourceMetadata({
    required this.companyId,
    required this.businessTimezone,
    required this.businessDate,
    this.sourceAsOfUtc,
    required this.fromDate,
    required this.toDate,
  });
}
