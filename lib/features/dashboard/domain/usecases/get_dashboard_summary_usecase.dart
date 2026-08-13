import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../entities/dashboard_source.dart';
import '../entities/dashboard_summary.dart';
import '../failures/dashboard_failure_codes.dart';
import '../policies/dashboard_permission_policy.dart';
import '../repositories/dashboard_repository.dart';

final class GetDashboardSummaryParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetDashboardSummaryParams({required this.currentCompanyContext});
}

final class GetDashboardSummaryUseCase
    extends UseCase<DashboardSummary, GetDashboardSummaryParams> {
  final DashboardRepository _repository;

  GetDashboardSummaryUseCase(this._repository);

  @override
  Future<Result<DashboardSummary>> call(
    GetDashboardSummaryParams params,
  ) async {
    final context = params.currentCompanyContext;

    if (!DashboardPermissionPolicy.canViewDashboard(context.role)) {
      return const FailureResult(
        PermissionFailure(code: DashboardFailureCodes.permissionView),
      );
    }

    final company = context.company;
    final currencyCode = company.baseCurrencyCode;
    final fractionDigits = company.baseCurrencyFractionDigits;
    final businessTimezone = company.businessTimezone;

    if (currencyCode == null ||
        fractionDigits == null ||
        businessTimezone == null) {
      return const FailureResult(
        ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      );
    }

    final expectedCurrency = CurrencyCode.tryParse(currencyCode);
    if (expectedCurrency == null || fractionDigits < 0 || fractionDigits > 4) {
      return const FailureResult(
        ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      );
    }

    final result = await _repository.getDashboardSource(
      companyId: context.companyId,
    );

    return result.when(
      success: (source) => _composeSummary(
        source: source,
        expectedCompanyId: context.companyId,
        expectedCurrency: expectedCurrency,
        expectedFractionDigits: fractionDigits,
        expectedBusinessTimezone: businessTimezone,
      ),
      failure: (failure) => FailureResult<DashboardSummary>(failure),
    );
  }

  Result<DashboardSummary> _composeSummary({
    required DashboardSource source,
    required String expectedCompanyId,
    required CurrencyCode expectedCurrency,
    required int expectedFractionDigits,
    required String expectedBusinessTimezone,
  }) {
    if (source.companyId != expectedCompanyId ||
        source.baseCurrencyFractionDigits != expectedFractionDigits ||
        source.businessTimezone != expectedBusinessTimezone ||
        !_hasValidCounts(source)) {
      return const FailureResult(
        ConflictFailure(code: DashboardFailureCodes.conflictSourceInvalid),
      );
    }

    if (source.revenue.currency != expectedCurrency ||
        source.tripExpenses.currency != expectedCurrency ||
        source.companyExpenses.currency != expectedCurrency ||
        source.financialCurrencyMismatchCount > 0) {
      return const FailureResult(
        ConflictFailure(code: DashboardFailureCodes.conflictCurrencyMismatch),
      );
    }

    if (source.revenue.isNegative ||
        source.tripExpenses.isNegative ||
        source.companyExpenses.isNegative ||
        source.expensePrecisionLossCount > 0 ||
        source.negativeExpenseCount > 0 ||
        source.invalidInvoiceBalanceCount > 0) {
      return const FailureResult(
        ConflictFailure(
          code: DashboardFailureCodes.conflictFinancialDataInvalid,
        ),
      );
    }

    final totalExpenses = source.tripExpenses.add(source.companyExpenses);
    final netProfit = source.revenue.subtract(totalExpenses);

    return Success(
      DashboardSummary(
        businessDate: source.businessDate,
        baseCurrencyFractionDigits: expectedFractionDigits,
        todayTrips: source.todayTrips,
        runningTrips: source.runningTrips,
        deliveredTrips: source.deliveredTrips,
        availableVehicles: source.availableVehicles,
        vehiclesOnTrip: source.vehiclesOnTrip,
        unpaidInvoices: source.unpaidInvoices,
        totalRevenue: source.revenue,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
      ),
    );
  }

  bool _hasValidCounts(DashboardSource source) {
    return source.todayTrips >= 0 &&
        source.runningTrips >= 0 &&
        source.deliveredTrips >= 0 &&
        source.availableVehicles >= 0 &&
        source.vehiclesOnTrip >= 0 &&
        source.unpaidInvoices >= 0 &&
        source.financialCurrencyMismatchCount >= 0 &&
        source.expensePrecisionLossCount >= 0 &&
        source.negativeExpenseCount >= 0 &&
        source.invalidInvoiceBalanceCount >= 0;
  }
}
