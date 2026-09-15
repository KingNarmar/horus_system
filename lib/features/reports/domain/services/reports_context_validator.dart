import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../../company/domain/policies/company_financial_readiness_policy.dart';
import '../entities/report_date_range.dart';
import '../failures/reports_failure_codes.dart';

final class ReportsFinancialValidatedRequest {
  final String companyId;
  final CurrencyCode currency;
  final int fractionDigits;
  final String businessTimezone;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ReportsFinancialValidatedRequest({
    required this.companyId,
    required this.currency,
    required this.fractionDigits,
    required this.businessTimezone,
    required this.fromDate,
    required this.toDate,
  });
}

final class ReportsOperationalValidatedRequest {
  final String companyId;
  final String businessTimezone;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ReportsOperationalValidatedRequest({
    required this.companyId,
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

  static Result<ReportsFinancialValidatedRequest> buildFinancial({
    required CurrentCompanyContext context,
    required ReportDateRange range,
  }) {
    final readiness = CompanyFinancialReadinessPolicy.evaluate(context.company);
    final configuration = readiness.configuration;
    if (!readiness.isReady || configuration == null) {
      return const FailureResult(
        ConflictFailure(
          code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
        ),
      );
    }

    final businessTimezone = context.company.businessTimezone?.trim();
    if (businessTimezone == null || businessTimezone.isEmpty) {
      return const FailureResult(
        ConflictFailure(
          code: CompanyFailureCodes.conflictBusinessTimezoneNotConfigured,
        ),
      );
    }

    final normalized = range.normalized();
    return Success(
      ReportsFinancialValidatedRequest(
        companyId: context.companyId,
        currency: configuration.baseCurrency,
        fractionDigits: configuration.fractionDigits,
        businessTimezone: businessTimezone,
        fromDate: normalized.fromDate,
        toDate: normalized.toDate,
      ),
    );
  }

  static Result<ReportsOperationalValidatedRequest> buildOperational({
    required CurrentCompanyContext context,
    required ReportDateRange range,
  }) {
    final businessTimezone = context.company.businessTimezone?.trim();
    if (businessTimezone == null || businessTimezone.isEmpty) {
      return const FailureResult(
        ConflictFailure(
          code: CompanyFailureCodes.conflictBusinessTimezoneNotConfigured,
        ),
      );
    }

    final normalized = range.normalized();
    return Success(
      ReportsOperationalValidatedRequest(
        companyId: context.companyId,
        businessTimezone: businessTimezone,
        fromDate: normalized.fromDate,
        toDate: normalized.toDate,
      ),
    );
  }
}
