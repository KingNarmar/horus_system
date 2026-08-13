import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../trips/domain/usecases/trips_usecases.dart';
import '../entities/trip_net_profit_report.dart';
import '../failures/reports_failure_codes.dart';
import '../policies/reports_permission_policy.dart';
import '../repositories/reports_repository.dart';
import '../services/report_source_integrity.dart';
import '../services/reports_context_validator.dart';
import 'report_params.dart';

final class GetTripNetProfitReportUseCase
    implements UseCase<TripNetProfitReport, ReportParams> {
  static const int _maxExactIntegerInDouble = 1 << 53;

  final ReportsRepository _repository;
  final CalculateTripNetProfitUseCase _calculateTripNetProfitUseCase;

  const GetTripNetProfitReportUseCase({
    required ReportsRepository repository,
    CalculateTripNetProfitUseCase calculateTripNetProfitUseCase =
        const CalculateTripNetProfitUseCase(),
  }) : _repository = repository,
       _calculateTripNetProfitUseCase = calculateTripNetProfitUseCase;

  @override
  Future<Result<TripNetProfitReport>> call(ReportParams params) async {
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

    final result = await _repository.getTripNetProfitSource(
      companyId: request.companyId,
      fromDate: request.fromDate,
      toDate: request.toDate,
    );
    if (result is FailureResult<TripNetProfitReportSource>) {
      return FailureResult(result.failure);
    }

    final source = (result as Success<TripNetProfitReportSource>).data;
    final metadataFailure = ReportSourceIntegrity.validateMetadata(
      metadata: source.metadata,
      expectedCompanyId: request.companyId,
      expectedCurrency: request.currency,
      expectedFractionDigits: request.fractionDigits,
      expectedBusinessTimezone: request.businessTimezone,
      expectedFromDate: request.fromDate,
      expectedToDate: request.toDate,
    );
    if (metadataFailure != null) return FailureResult(metadataFailure);

    if (ReportSourceIntegrity.hasInvalidCounter([
          source.freightPrecisionLossCount,
          source.negativeFreightCount,
          source.expensePrecisionLossCount,
          source.negativeExpenseCount,
        ]) ||
        source.freightPrecisionLossCount > 0 ||
        source.negativeFreightCount > 0 ||
        source.expensePrecisionLossCount > 0 ||
        source.negativeExpenseCount > 0) {
      return const FailureResult(
        ConflictFailure(code: ReportsFailureCodes.conflictFinancialDataInvalid),
      );
    }

    final tripIds = <String>{};
    for (final trip in source.trips) {
      if (trip.tripId.trim().isEmpty ||
          !tripIds.add(trip.tripId) ||
          trip.customerId.trim().isEmpty ||
          trip.customerName.trim().isEmpty) {
        return const FailureResult(
          ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
        );
      }
      if (trip.freight.currency != request.currency) {
        return const FailureResult(
          ConflictFailure(code: ReportsFailureCodes.conflictCurrencyMismatch),
        );
      }
      if (trip.freight.isNegative) {
        return const FailureResult(
          ConflictFailure(
            code: ReportsFailureCodes.conflictFinancialDataInvalid,
          ),
        );
      }
    }

    final expenseIds = <String>{};
    final expensesByTrip = <String, Money>{};
    for (final expense in source.expenses) {
      if (expense.expenseId.trim().isEmpty ||
          !expenseIds.add(expense.expenseId) ||
          !tripIds.contains(expense.tripId)) {
        return const FailureResult(
          ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
        );
      }
      if (expense.amount.currency != request.currency) {
        return const FailureResult(
          ConflictFailure(code: ReportsFailureCodes.conflictCurrencyMismatch),
        );
      }
      if (expense.amount.isNegative) {
        return const FailureResult(
          ConflictFailure(
            code: ReportsFailureCodes.conflictFinancialDataInvalid,
          ),
        );
      }
      final current =
          expensesByTrip[expense.tripId] ??
          Money(minorUnits: 0, currency: request.currency);
      expensesByTrip[expense.tripId] = current.add(expense.amount);
    }

    var totalFreight = Money(minorUnits: 0, currency: request.currency);
    var totalExpenses = Money(minorUnits: 0, currency: request.currency);
    var totalNetProfit = Money(minorUnits: 0, currency: request.currency);
    final rows = <TripNetProfitReportRow>[];

    for (final trip in source.trips) {
      final expenses =
          expensesByTrip[trip.tripId] ??
          Money(minorUnits: 0, currency: request.currency);
      if (!_isExactlyRepresentableAsDouble(trip.freight.minorUnits) ||
          !_isExactlyRepresentableAsDouble(expenses.minorUnits)) {
        return const FailureResult(
          ConflictFailure(
            code: ReportsFailureCodes.conflictFinancialDataInvalid,
          ),
        );
      }
      final netResult = await _calculateTripNetProfitUseCase(
        CalculateTripNetProfitParams(
          freightPrice: trip.freight.minorUnits.toDouble(),
          totalExpenses: expenses.minorUnits.toDouble(),
        ),
      );
      if (netResult is FailureResult<double>) {
        return const FailureResult(
          ConflictFailure(
            code: ReportsFailureCodes.conflictFinancialDataInvalid,
          ),
        );
      }
      final netMinorUnits = (netResult as Success<double>).data;
      if (!netMinorUnits.isFinite ||
          netMinorUnits != netMinorUnits.roundToDouble()) {
        return const FailureResult(
          ConflictFailure(
            code: ReportsFailureCodes.conflictFinancialDataInvalid,
          ),
        );
      }
      final netProfit = Money(
        minorUnits: netMinorUnits.toInt(),
        currency: request.currency,
      );
      rows.add(
        TripNetProfitReportRow(
          trip: trip,
          totalExpenses: expenses,
          netProfit: netProfit,
        ),
      );
      totalFreight = totalFreight.add(trip.freight);
      totalExpenses = totalExpenses.add(expenses);
      totalNetProfit = totalNetProfit.add(netProfit);
    }

    return Success(
      TripNetProfitReport(
        metadata: source.metadata,
        rows: rows,
        totalFreight: totalFreight,
        totalExpenses: totalExpenses,
        totalNetProfit: totalNetProfit,
      ),
    );
  }

  bool _isExactlyRepresentableAsDouble(int value) {
    return value.abs() <= _maxExactIntegerInDouble;
  }
}
