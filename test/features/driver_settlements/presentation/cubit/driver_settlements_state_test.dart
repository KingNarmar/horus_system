import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_driver_option.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlements_state.dart';

void main() {
  group('DriverSettlementsLoaded', () {
    test('keeps inactive drivers available for historical labels', () {
      final state = _state();

      expect(state.driverLabel('driver-inactive'), 'Old Driver');
      expect(
        state.activeDriverOptions.map((option) => option.id),
        ['driver-active'],
      );
    });

    test('filters settlements by localized driver display name', () {
      final state = _state(searchQuery: 'old driver', includeVoided: true);

      expect(state.settlements, hasLength(1));
      expect(state.settlements.single.driverId, 'driver-inactive');
    });

    test('matches localized status search terms supplied by presentation', () {
      final state = _state(searchQuery: 'ملغاة', includeVoided: true);

      final settlements = state.filteredSettlements(
        statusSearchTerms: {
          DriverSettlementStatus.voided: const ['Voided', 'ملغاة'],
        },
      );

      expect(settlements, hasLength(1));
      expect(settlements.single.status, DriverSettlementStatus.voided);
    });

    test('hides voided settlements unless includeVoided is enabled', () {
      expect(_state().settlements, hasLength(1));
      expect(_state(includeVoided: true).settlements, hasLength(2));
    });

    test('filters by driver and status together', () {
      final state = _state(
        includeVoided: true,
        driverIdFilter: 'driver-inactive',
        statusFilter: DriverSettlementStatus.voided,
      );

      expect(state.settlements, hasLength(1));
      expect(state.settlements.single.status, DriverSettlementStatus.voided);
    });
  });
}

DriverSettlementsLoaded _state({
  String searchQuery = '',
  bool includeVoided = false,
  String? driverIdFilter,
  DriverSettlementStatus? statusFilter,
}) {
  return DriverSettlementsLoaded(
    currentCompanyContext: const CurrentCompanyContext(
      company: Company(id: 'company-1', name: 'Test Company'),
      role: CompanyRole.accountant,
    ),
    allSettlements: [
      _settlement(
        id: 'draft-1',
        driverId: 'driver-active',
        status: DriverSettlementStatus.draft,
      ),
      _settlement(
        id: 'voided-1',
        driverId: 'driver-inactive',
        status: DriverSettlementStatus.voided,
      ),
    ],
    driverOptions: const [
      DriverSettlementDriverOption(
        id: 'driver-active',
        displayName: 'Active Driver',
        isActive: true,
      ),
      DriverSettlementDriverOption(
        id: 'driver-inactive',
        displayName: 'Old Driver',
        isActive: false,
      ),
    ],
    canManageDriverSettlements: true,
    searchQuery: searchQuery,
    includeVoided: includeVoided,
    driverIdFilter: driverIdFilter,
    statusFilter: statusFilter,
  );
}

DriverSettlement _settlement({
  required String id,
  required String driverId,
  required DriverSettlementStatus status,
}) {
  return DriverSettlement(
    id: id,
    companyId: 'company-1',
    driverId: driverId,
    period: DriverSettlementPeriod(
      start: DateTime(2026, 6, 1),
      end: DateTime(2026, 6, 30),
    ),
    calculation: const DriverSettlementCalculationResult(
      openingDriverBalance: 0,
      advancesTotal: 100,
      driverPaidTripExpensesTotal: 20,
      returnedCashTotal: 0,
      deductionsTotal: 10,
      settlementDeductionsTotal: 0,
      grossSalary: 1000,
      salaryDeductionsTotal: 50,
      balanceDeductionApplied: 20,
      netSalaryPayable: 930,
      closingDriverBalance: 70,
    ),
    status: status,
  );
}
