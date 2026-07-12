import 'package:horus_system/features/driver_settlements/data/mappers/driver_settlement_mapper.dart';
import 'package:horus_system/features/driver_settlements/data/models/driver_settlement_item_model.dart';
import 'package:horus_system/features/driver_settlements/data/models/driver_settlement_model.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_direction.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_source_type.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('DriverSettlementModelMapper', () {
    test(
      'maps settlement model to domain entity with calculation and items',
      () {
        final model = _settlementModel(
          items: [
            DriverSettlementItemModel(
              id: 'item-1',
              companyId: _companyId,
              settlementId: _settlementId,
              sourceType: DriverSettlementItemSourceType.tripExpense,
              direction: DriverSettlementItemDirection.companyToDriver,
              amount: 120,
              labelKey: 'driver_settlement_item_trip_expense',
            ),
          ],
        );

        final entity = model.toEntity();

        expect(entity.id, _settlementId);
        expect(entity.companyId, _companyId);
        expect(entity.driverId, _driverId);
        expect(entity.period.start, DateTime(2026, 7));
        expect(entity.calculation.closingDriverBalance, 125);
        expect(entity.status, DriverSettlementStatus.draft);
        expect(entity.items, hasLength(1));
        expect(entity.items.first.amount, 120);
      },
    );

    test('maps draft write data to insert map', () {
      final data = DriverSettlementDraftWriteData(
        companyId: _companyId,
        driverId: _driverId,
        period: DriverSettlementPeriod(
          start: DateTime(2026, 7),
          end: DateTime(2026, 7, 31),
        ),
        calculation: const DriverSettlementCalculationResult(
          openingDriverBalance: 10,
          advancesTotal: 200,
          driverPaidTripExpensesTotal: 50,
          returnedCashTotal: 0,
          deductionsTotal: 25,
          settlementDeductionsTotal: 10,
          grossSalary: 1000,
          salaryDeductionsTotal: 100,
          balanceDeductionApplied: 50,
          netSalaryPayable: 850,
          closingDriverBalance: 125,
        ),
        notes: 'July settlement',
      );

      final map = data.toInsertMap();

      expect(map['company_id'], _companyId);
      expect(map['driver_id'], _driverId);
      expect(map['period_start'], '2026-07-01');
      expect(map['period_end'], '2026-07-31');
      expect(map['status'], 'draft');
      expect(map['closing_driver_balance'], 125);
      expect(map['net_salary_payable'], 850);
    });

    test('maps item to insert map with settlement id', () {
      final item = DriverSettlementItem(
        companyId: _companyId,
        sourceType: DriverSettlementItemSourceType.driverFinancialMovement,
        sourceId: 'movement-1',
        sourceDate: DateTime(2026, 7, 10),
        direction: DriverSettlementItemDirection.driverToCompany,
        amount: 200,
        labelKey: 'driver_settlement_item_advance',
        metadata: const {'movement_type': 'advance'},
      );

      final map = item.toInsertMap(settlementId: _settlementId);

      expect(map['company_id'], _companyId);
      expect(map['settlement_id'], _settlementId);
      expect(map['source_type'], 'driver_financial_movement');
      expect(map['source_id'], 'movement-1');
      expect(map['source_date'], '2026-07-10');
      expect(map['direction'], 'driver_to_company');
      expect(map['metadata'], {'movement_type': 'advance'});
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';
const _settlementId = 'settlement-1';

DriverSettlementModel _settlementModel({
  List<DriverSettlementItemModel> items = const [],
}) {
  return DriverSettlementModel(
    id: _settlementId,
    companyId: _companyId,
    driverId: _driverId,
    periodStart: DateTime(2026, 7),
    periodEnd: DateTime(2026, 7, 31),
    openingDriverBalance: 10,
    advancesTotal: 200,
    driverPaidTripExpensesTotal: 50,
    returnedCashTotal: 0,
    deductionsTotal: 25,
    settlementDeductionsTotal: 10,
    grossSalary: 1000,
    salaryDeductionsTotal: 100,
    balanceDeductionApplied: 50,
    netSalaryPayable: 850,
    closingDriverBalance: 125,
    status: DriverSettlementStatus.draft,
    items: items,
  );
}
