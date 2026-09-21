import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/driver_settlements/data/mappers/driver_settlement_mapper.dart';
import 'package:horus_system/features/driver_settlements/data/models/driver_settlement_item_model.dart';
import 'package:horus_system/features/driver_settlements/data/models/driver_settlement_model.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_direction.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_source_type.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_item.dart';
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
        expect(entity.period.start, _date(2026, 7, 1));
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
          start: _date(2026, 7, 1),
          end: _date(2026, 7, 31),
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
        sourceDate: _date(2026, 7, 10),
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

    test(
      'maps exact settlement snapshot without floating point conversion',
      () {
        final currency = CurrencyCode.tryParse('KWD')!;
        final data = DriverSettlementMoneyDraftWriteData(
          companyId: _companyId,
          driverId: _driverId,
          period: DriverSettlementPeriod(
            start: _date(2026, 7, 1),
            end: _date(2026, 7, 31),
          ),
          compensationRevisionId: 'revision-1',
          currencyFractionDigits: 3,
          calculation: DriverSettlementMoneyCalculationResult(
            openingDriverBalance: Money(minorUnits: -12345, currency: currency),
            advancesTotal: Money(minorUnits: 2000, currency: currency),
            driverPaidTripExpensesTotal: Money(
              minorUnits: 1005,
              currency: currency,
            ),
            returnedCashTotal: Money(minorUnits: 500, currency: currency),
            deductionsTotal: Money(minorUnits: 250, currency: currency),
            settlementDeductionsTotal: Money(
              minorUnits: 100,
              currency: currency,
            ),
            grossSalary: Money(minorUnits: 123456, currency: currency),
            salaryDeductionsTotal: Money(minorUnits: 456, currency: currency),
            balanceDeductionApplied: Money(
              minorUnits: 1000,
              currency: currency,
            ),
            netSalaryPayable: Money(minorUnits: 122000, currency: currency),
            closingDriverBalance: Money(minorUnits: -13190, currency: currency),
          ),
          notes: 'Exact KWD snapshot',
        );

        final map = data.toMoneyInsertMap();

        expect(map['compensation_revision_id'], 'revision-1');
        expect(map['currency_code'], 'KWD');
        expect(map['currency_fraction_digits'], 3);
        expect(map['opening_driver_balance'], '-12.345');
        expect(map['opening_driver_balance_minor_units'], -12345);
        expect(map['driver_paid_trip_expenses_total'], '1.005');
        expect(map['driver_paid_trip_expenses_total_minor_units'], 1005);
        expect(map['gross_salary'], '123.456');
        expect(map['gross_salary_minor_units'], 123456);
        expect(map['net_salary_payable'], '122.000');
        expect(map['net_salary_payable_minor_units'], 122000);
        expect(map['closing_driver_balance'], '-13.190');
        expect(map['closing_driver_balance_minor_units'], -13190);
        expect(map['status'], 'draft');
      },
    );

    test('maps exact settlement item with currency snapshot', () {
      final currency = CurrencyCode.tryParse('KWD')!;
      final item = DriverSettlementMoneyItem(
        companyId: _companyId,
        sourceType: DriverSettlementItemSourceType.tripExpense,
        sourceId: 'ledger-1',
        sourceDate: _date(2026, 7, 10),
        direction: DriverSettlementItemDirection.companyToDriver,
        amount: Money(minorUnits: 1005, currency: currency),
        labelKey: 'driver_settlement_item_trip_expense',
        metadata: const {'funding_source': 'driver_cash'},
      );

      final map = item.toMoneyInsertMap(
        settlementId: _settlementId,
        currencyFractionDigits: 3,
      );

      expect(map['settlement_id'], _settlementId);
      expect(map['amount'], '1.005');
      expect(map['amount_minor_units'], 1005);
      expect(map['currency_code'], 'KWD');
      expect(map['currency_fraction_digits'], 3);
      expect(map['metadata'], {'funding_source': 'driver_cash'});
    });

    test('finalize payload leaves lifecycle metadata to the database', () {
      const data = DriverSettlementFinalizeData(
        companyId: _companyId,
        settlementId: _settlementId,
      );

      expect(data.toUpdateMap(), {'status': 'finalized'});
    });

    test('void payload leaves lifecycle metadata to the database', () {
      const data = DriverSettlementVoidData(
        companyId: _companyId,
        settlementId: _settlementId,
        reason: 'duplicate settlement',
      );

      expect(data.toUpdateMap(), {
        'status': 'voided',
        'void_reason': 'duplicate settlement',
      });
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';
const _settlementId = 'settlement-1';

BusinessDate _date(int year, int month, int day) {
  return BusinessDate(year: year, month: month, day: day);
}

DriverSettlementModel _settlementModel({
  List<DriverSettlementItemModel> items = const [],
}) {
  return DriverSettlementModel(
    id: _settlementId,
    companyId: _companyId,
    driverId: _driverId,
    periodStart: _date(2026, 7, 1),
    periodEnd: _date(2026, 7, 31),
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
