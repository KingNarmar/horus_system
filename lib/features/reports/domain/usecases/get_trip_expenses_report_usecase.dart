import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/trip_expenses_report.dart';
import '../failures/reports_failure_codes.dart';
import '../policies/reports_permission_policy.dart';
import '../repositories/reports_repository.dart';
import '../services/report_source_integrity.dart';
import '../services/reports_context_validator.dart';
import 'report_params.dart';

final class GetTripExpensesReportUseCase
    implements UseCase<TripExpensesReport, ReportParams> {
  final ReportsRepository _repository;

  const GetTripExpensesReportUseCase(this._repository);

  @override
  Future<Result<TripExpensesReport>> call(ReportParams params) async {
    final context = params.currentCompanyContext;
    if (!ReportsPermissionPolicy.canViewFinancialReports(context.role)) {
      return const FailureResult(
        PermissionFailure(code: ReportsFailureCodes.permissionFinancialView),
      );
    }

    final dateFailure = ReportsContextValidator.validateDateRange(
      params.dateRange,
    );
    if (dateFailure != null) return FailureResult(dateFailure);

    final request = ReportsContextValidator.tryBuild(
      context: context,
      range: params.dateRange,
    );
    if (request == null) {
      return FailureResult(ReportsContextValidator.regionalSettingsFailure());
    }

    final result = await _repository.getTripExpensesSource(
      companyId: request.companyId,
      fromDate: request.fromDate,
      toDate: request.toDate,
    );

    return result.when(
      success: (source) {
        final metadataFailure = ReportSourceIntegrity.validateMetadata(
          metadata: source.metadata,
          expectedCompanyId: request.companyId,
          expectedCurrency: request.currency,
          expectedFractionDigits: request.fractionDigits,
          expectedBusinessTimezone: request.businessTimezone,
          expectedFromDate: request.fromDate,
          expectedToDate: request.toDate,
        );
        if (metadataFailure != null) {
          return FailureResult<TripExpensesReport>(metadataFailure);
        }

        if (ReportSourceIntegrity.hasInvalidCounter([
              source.precisionLossCount,
              source.negativeAmountCount,
            ]) ||
            source.precisionLossCount > 0 ||
            source.negativeAmountCount > 0) {
          return const FailureResult<TripExpensesReport>(
            ConflictFailure(
              code: ReportsFailureCodes.conflictFinancialDataInvalid,
            ),
          );
        }

        var total = Money(minorUnits: 0, currency: request.currency);
        final ids = <String>{};
        for (final row in source.rows) {
          if (row.expenseId.trim().isEmpty ||
              !ids.add(row.expenseId) ||
              row.tripId.trim().isEmpty ||
              row.customerId.trim().isEmpty ||
              row.customerName.trim().isEmpty ||
              row.expenseName.trim().isEmpty) {
            return const FailureResult<TripExpensesReport>(
              ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
            );
          }
          if (row.amount.currency != request.currency) {
            return const FailureResult<TripExpensesReport>(
              ConflictFailure(
                code: ReportsFailureCodes.conflictCurrencyMismatch,
              ),
            );
          }
          if (row.amount.isNegative) {
            return const FailureResult<TripExpensesReport>(
              ConflictFailure(
                code: ReportsFailureCodes.conflictFinancialDataInvalid,
              ),
            );
          }
          total = total.add(row.amount);
        }

        return Success(
          TripExpensesReport(
            metadata: source.metadata,
            rows: source.rows,
            totalExpenses: total,
          ),
        );
      },
      failure: (failure) => FailureResult<TripExpensesReport>(failure),
    );
  }
}
