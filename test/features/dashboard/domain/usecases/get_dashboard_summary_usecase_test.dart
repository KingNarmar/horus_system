import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/dashboard/domain/entities/dashboard_source.dart';
import 'package:horus_system/features/dashboard/domain/failures/dashboard_failure_codes.dart';
import 'package:horus_system/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:horus_system/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('composes total expenses and net profit in Domain', () async {
    final repository = _FakeDashboardRepository();
    final useCase = GetDashboardSummaryUseCase(repository);

    final result = await useCase(
      GetDashboardSummaryParams(
        currentCompanyContext: _context(CompanyRole.owner),
      ),
    );

    final summary = result.dataOrNull;
    expect(summary, isNotNull);
    expect(repository.lastCompanyId, 'company-1');
    expect(summary!.todayTrips, 0);
    expect(summary.runningTrips, 0);
    expect(summary.deliveredTrips, 3);
    expect(summary.availableVehicles, 2);
    expect(summary.vehiclesOnTrip, 1);
    expect(summary.unpaidInvoices, 0);
    expect(summary.totalRevenue.minorUnits, 120000);
    expect(summary.totalExpenses.minorUnits, 1731000);
    expect(summary.netProfit.minorUnits, -1611000);
  });

  test('driver is denied before repository access', () async {
    final repository = _FakeDashboardRepository();
    final useCase = GetDashboardSummaryUseCase(repository);

    final result = await useCase(
      GetDashboardSummaryParams(
        currentCompanyContext: _context(CompanyRole.driver),
      ),
    );

    expect(result.failureOrNull?.code, DashboardFailureCodes.permissionView);
    expect(repository.lastCompanyId, isNull);
  });

  test('rejects source currency mismatch', () async {
    final repository = _FakeDashboardRepository(
      sourceBuilder: (companyId) =>
          _source(companyId, financialCurrencyMismatchCount: 1),
    );
    final useCase = GetDashboardSummaryUseCase(repository);

    final result = await useCase(
      GetDashboardSummaryParams(
        currentCompanyContext: _context(CompanyRole.accountant),
      ),
    );

    expect(
      result.failureOrNull?.code,
      DashboardFailureCodes.conflictCurrencyMismatch,
    );
  });

  test('rejects invalid financial source data', () async {
    final repository = _FakeDashboardRepository(
      sourceBuilder: (companyId) =>
          _source(companyId, invalidInvoiceBalanceCount: 1),
    );
    final useCase = GetDashboardSummaryUseCase(repository);

    final result = await useCase(
      GetDashboardSummaryParams(
        currentCompanyContext: _context(CompanyRole.viewer),
      ),
    );

    expect(
      result.failureOrNull?.code,
      DashboardFailureCodes.conflictFinancialDataInvalid,
    );
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
    ),
    role: role,
  );
}

DashboardSource _source(
  String companyId, {
  int financialCurrencyMismatchCount = 0,
  int invalidInvoiceBalanceCount = 0,
}) {
  final currency = CurrencyCode.tryParse('AED')!;
  return DashboardSource(
    companyId: companyId,
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    businessDate: DateTime(2026, 8, 12),
    todayTrips: 0,
    runningTrips: 0,
    deliveredTrips: 3,
    availableVehicles: 2,
    vehiclesOnTrip: 1,
    unpaidInvoices: 0,
    revenue: Money(minorUnits: 120000, currency: currency),
    tripExpenses: Money(minorUnits: 980000, currency: currency),
    companyExpenses: Money(minorUnits: 751000, currency: currency),
    financialCurrencyMismatchCount: financialCurrencyMismatchCount,
    expensePrecisionLossCount: 0,
    negativeExpenseCount: 0,
    invalidInvoiceBalanceCount: invalidInvoiceBalanceCount,
  );
}

final class _FakeDashboardRepository implements DashboardRepository {
  final DashboardSource Function(String companyId) sourceBuilder;
  String? lastCompanyId;

  _FakeDashboardRepository({
    DashboardSource Function(String companyId)? sourceBuilder,
  }) : sourceBuilder = sourceBuilder ?? _source;

  @override
  Future<Result<DashboardSource>> getDashboardSource({
    required String companyId,
  }) async {
    lastCompanyId = companyId;
    return Success(sourceBuilder(companyId));
  }
}
