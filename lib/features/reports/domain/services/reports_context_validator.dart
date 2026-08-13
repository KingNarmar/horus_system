import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../entities/report_date_range.dart';
import '../failures/reports_failure_codes.dart';

final class ReportsValidatedRequest {
  final String companyId;
  final CurrencyCode currency;
  final int fractionDigits;
  final String businessTimezone;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ReportsValidatedRequest({
    required this.companyId,
    required this.currency,
    required this.fractionDigits,
    required this.businessTimezone,
    required this.fromDate,
    required this.toDate,
  });
}

abstract final class ReportsContextValidator {
  static Failure? validateDateRange(ReportDateRange range) {
    final normalized = range.normalized();
    if (normalized.isInvalid) {
      return const ValidationFailure(
        code: ReportsFailureCodes.validationDateRange,
      );
    }
    return null;
  }

  static ReportsValidatedRequest? tryBuild({
    required CurrentCompanyContext context,
    required ReportDateRange range,
  }) {
    final company = context.company;
    final currencyCode = company.baseCurrencyCode;
    final fractionDigits = company.baseCurrencyFractionDigits;
    final businessTimezone = company.businessTimezone?.trim();
    if (currencyCode == null ||
        fractionDigits == null ||
        businessTimezone == null ||
        businessTimezone.isEmpty) {
      return null;
    }

    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null || fractionDigits < 0 || fractionDigits > 4) {
      return null;
    }

    final normalized = range.normalized();
    return ReportsValidatedRequest(
      companyId: context.companyId,
      currency: currency,
      fractionDigits: fractionDigits,
      businessTimezone: businessTimezone,
      fromDate: normalized.fromDate,
      toDate: normalized.toDate,
    );
  }

  static Failure regionalSettingsFailure() {
    return const ConflictFailure(
      code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
    );
  }
}
