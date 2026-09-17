import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/features/driver_settlements/data/mappers/driver_settlement_money_source_snapshot_mapper.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_direction.dart';
import 'package:test/test.dart';

void main() {
  final configuration = CurrencyConfiguration.tryCreate(
    currencyCode: 'AED',
    fractionDigits: 2,
  )!;
  const mapper = DriverSettlementMoneySourceSnapshotMapper();

  test('maps canonical financial sources exactly once in minor units', () {
    final snapshot = mapper.map(
      companyId: 'company-1',
      currencyConfiguration: configuration,
      movementRows: [
        _movement(
          id: 'advance-1',
          type: 'advance',
          minorUnits: 10005,
          date: '2026-07-01',
        ),
        _movement(
          id: 'charge-1',
          type: 'driver_charge',
          minorUnits: 250,
          date: '2026-07-02',
        ),
        _movement(
          id: 'return-1',
          type: 'cash_return',
          minorUnits: 500,
          date: '2026-07-03',
        ),
      ],
      tripExpenseRows: [
        _expense(
          id: 'ledger-1',
          originKind: 'trip_expense',
          originId: 'legacy-expense-1',
          minorUnits: 1250,
          date: '2026-07-04',
          fundingSource: 'driver_advance',
        ),
        _expense(
          id: 'ledger-2',
          originKind: 'manual',
          originId: null,
          minorUnits: 750,
          date: '2026-07-05',
          fundingSource: 'driver_cash',
        ),
      ],
    );

    expect(snapshot.advancesTotal.minorUnits, 10005);
    expect(snapshot.deductionsTotal.minorUnits, 250);
    expect(snapshot.returnedCashTotal.minorUnits, 500);
    expect(snapshot.driverPaidTripExpensesTotal.minorUnits, 2000);
    expect(snapshot.sourceItems, hasLength(5));

    final legacyExpense = snapshot.sourceItems[3];
    expect(legacyExpense.sourceId, 'legacy-expense-1');
    expect(
      legacyExpense.direction,
      DriverSettlementItemDirection.companyToDriver,
    );
    expect(legacyExpense.amount.minorUnits, 1250);

    final canonicalExpense = snapshot.sourceItems[4];
    expect(canonicalExpense.sourceId, 'ledger-2');
    expect(canonicalExpense.amount.minorUnits, 750);
  });

  test('rejects a source whose currency snapshot differs from company', () {
    expect(
      () => mapper.map(
        companyId: 'company-1',
        currencyConfiguration: configuration,
        movementRows: [
          {
            ..._movement(
              id: 'advance-1',
              type: 'advance',
              minorUnits: 100,
              date: '2026-07-01',
            ),
            'currency_code': 'USD',
          },
        ],
        tripExpenseRows: const [],
      ),
      throwsFormatException,
    );
  });

  test('rejects unsupported movement semantics instead of guessing', () {
    expect(
      () => mapper.map(
        companyId: 'company-1',
        currencyConfiguration: configuration,
        movementRows: [
          _movement(
            id: 'movement-1',
            type: 'unknown',
            minorUnits: 100,
            date: '2026-07-01',
          ),
        ],
        tripExpenseRows: const [],
      ),
      throwsFormatException,
    );
  });
}

Map<String, dynamic> _movement({
  required String id,
  required String type,
  required int minorUnits,
  required String date,
}) {
  return {
    'id': id,
    'company_id': 'company-1',
    'driver_id': 'driver-1',
    'trip_id': null,
    'movement_type': type,
    'amount_minor_units': minorUnits,
    'currency_code': 'AED',
    'currency_fraction_digits': 2,
    'movement_date': date,
    'notes': null,
  };
}

Map<String, dynamic> _expense({
  required String id,
  required String originKind,
  required String? originId,
  required int minorUnits,
  required String date,
  required String fundingSource,
}) {
  return {
    'id': id,
    'company_id': 'company-1',
    'trip_id': 'trip-1',
    'description': 'Expense',
    'amount_minor_units': minorUnits,
    'currency_code': 'AED',
    'currency_fraction_digits': 2,
    'funding_source': fundingSource,
    'expense_date': date,
    'origin_kind': originKind,
    'origin_id': originId,
  };
}
