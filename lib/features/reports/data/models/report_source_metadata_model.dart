import 'report_model_parsing.dart';

final class ReportSourceMetadataModel {
  final String companyId;
  final String baseCurrencyCode;
  final int baseCurrencyFractionDigits;
  final String businessTimezone;
  final DateTime businessDate;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ReportSourceMetadataModel({
    required this.companyId,
    required this.baseCurrencyCode,
    required this.baseCurrencyFractionDigits,
    required this.businessTimezone,
    required this.businessDate,
    required this.fromDate,
    required this.toDate,
  });

  factory ReportSourceMetadataModel.fromRoot(Map<String, dynamic> root) {
    final company = requiredMap(root['company'], 'company');
    final period = requiredMap(root['period'], 'period');
    return ReportSourceMetadataModel(
      companyId: requiredString(company['company_id'], 'company_id'),
      baseCurrencyCode: requiredString(
        company['base_currency_code'],
        'base_currency_code',
      ),
      baseCurrencyFractionDigits: requiredInt(
        company['base_currency_fraction_digits'],
        'base_currency_fraction_digits',
      ),
      businessTimezone: requiredString(
        company['business_timezone'],
        'business_timezone',
      ),
      businessDate: requiredDate(company['business_date'], 'business_date'),
      fromDate: optionalDate(period['from_date'], 'from_date'),
      toDate: optionalDate(period['to_date'], 'to_date'),
    );
  }
}
