import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/dashboard/domain/entities/dashboard_source.dart';
import 'package:horus_system/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:horus_system/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:horus_system/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:horus_system/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:test/test.dart';

void main() {
  test('load emits loading then loaded summary', () async {
    final cubit = DashboardCubit(
      GetDashboardSummaryUseCase(_FakeDashboardRepository()),
    );
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([isA<DashboardLoading>(), isA<DashboardLoaded>()]),
    );

    await cubit.load(_context());
    await expectation;

    final state = cubit.state;
    expect(state, isA<DashboardLoaded>());
    expect((state as DashboardLoaded).summary.netProfit.minorUnits, -1611000);

    await cubit.close();
  });
}

CurrentCompanyContext _context() {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
    ),
    role: CompanyRole.owner,
  );
}

final class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<Result<DashboardSource>> getDashboardSource({
    required String companyId,
  }) async {
    final currency = CurrencyCode.tryParse('AED')!;
    return Success(
      DashboardSource(
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
        financialCurrencyMismatchCount: 0,
        expensePrecisionLossCount: 0,
        negativeExpenseCount: 0,
        invalidInvoiceBalanceCount: 0,
      ),
    );
  }
}
