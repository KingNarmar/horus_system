import 'package:horus_system/features/driver_settlements/data/mappers/driver_settlement_source_snapshot_mapper.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_direction.dart';
import 'package:test/test.dart';

void main() {
  const mapper = DriverSettlementSourceSnapshotMapper();

  group('DriverSettlementSourceSnapshotMapper', () {
    test('maps all approved sources without losing payment metadata', () {
      final snapshot = mapper.map(
        companyId: 'company-1',
        openingDriverBalance: -100,
        movementRows: [
          _movement(id: 'advance-1', type: 'advance', amount: 7000),
          _movement(id: 'charge-1', type: 'driver_charge', amount: 500),
          _movement(id: 'return-1', type: 'cash_return', amount: 150),
        ],
        tripExpenseRows: [
          _tripExpense(
            id: 'ledger-advance',
            fundingSource: 'driver_advance',
            amountMinorUnits: 500000,
            originKind: 'legacy_trip_expense',
            originId: 'expense-advance',
          ),
          _tripExpense(
            id: 'expense-cash',
            fundingSource: 'driver_cash',
            amountMinorUnits: 20000,
          ),
        ],
      );

      expect(snapshot.openingDriverBalance, -100);
      expect(snapshot.advancesTotal, 7000);
      expect(snapshot.deductionsTotal, 500);
      expect(snapshot.returnedCashTotal, 150);
      expect(snapshot.driverPaidTripExpensesTotal, 5200);
      expect(snapshot.sourceItems, hasLength(5));

      final advance = snapshot.sourceItems[0];
      final charge = snapshot.sourceItems[1];
      final cashReturn = snapshot.sourceItems[2];
      final advanceExpense = snapshot.sourceItems[3];
      final cashExpense = snapshot.sourceItems[4];

      expect(advance.labelKey, 'driver_settlement_item_advance');
      expect(advance.direction, DriverSettlementItemDirection.driverToCompany);
      expect(charge.labelKey, 'driver_settlement_item_driver_charge');
      expect(charge.direction, DriverSettlementItemDirection.driverToCompany);
      expect(cashReturn.labelKey, 'driver_settlement_item_cash_return');
      expect(
        cashReturn.direction,
        DriverSettlementItemDirection.companyToDriver,
      );
      expect(advanceExpense.sourceId, 'expense-advance');
      expect(advanceExpense.metadata['paid_by'], 'driver_advance');
      expect(cashExpense.sourceId, 'expense-cash');
      expect(cashExpense.metadata['paid_by'], 'driver_cash');
    });

    test('rounds source totals to money precision', () {
      final snapshot = mapper.map(
        companyId: 'company-1',
        openingDriverBalance: 0,
        movementRows: [
          _movement(id: 'return-1', type: 'cash_return', amount: 0.105),
          _movement(id: 'return-2', type: 'cash_return', amount: 0.105),
        ],
        tripExpenseRows: const [],
      );

      expect(snapshot.returnedCashTotal, 0.21);
    });

    test('rejects movement types outside the database contract', () {
      expect(
        () => mapper.map(
          companyId: 'company-1',
          openingDriverBalance: 0,
          movementRows: [
            _movement(id: 'legacy-1', type: 'deduction', amount: 100),
          ],
          tripExpenseRows: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _movement({
  required String id,
  required String type,
  required num amount,
}) {
  return {
    'id': id,
    'movement_type': type,
    'amount': amount,
    'movement_date': '2026-07-01',
    'trip_id': null,
    'notes': null,
  };
}

Map<String, dynamic> _tripExpense({
  required String id,
  required String fundingSource,
  required int amountMinorUnits,
  String originKind = 'manual',
  String? originId,
}) {
  return {
    'id': id,
    'trip_id': 'trip-1',
    'description': 'Fuel',
    'amount_minor_units': amountMinorUnits,
    'currency_fraction_digits': 2,
    'funding_source': fundingSource,
    'expense_date': '2026-07-01',
    'origin_kind': originKind,
    'origin_id': originId,
    'notes': null,
  };
}
