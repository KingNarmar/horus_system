import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/driver_finance/data/mappers/driver_balance_activity_mapper.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_activity_entry.dart';
import 'package:test/test.dart';

void main() {
  const mapper = DriverBalanceActivityMapper();

  group('DriverBalanceActivityMapper', () {
    test('joins sources with canonical snapshot and exact minor units', () {
      final result = mapper.map(
        companyId: 'company-1',
        driverId: 'driver-1',
        currencyCode: 'KWD',
        currencyFractionDigits: 3,
        checkpointRow: {
          'settlement_id': 'settlement-1',
          'period_end': '2026-09-30',
          'snapshot_created_at': '2026-10-01T08:00:00Z',
          'closing_driver_balance_minor_units': 3000,
          'currency_code': 'KWD',
          'currency_fraction_digits': 3,
        },
        movementRows: [
          _movement(
            id: 'advance-1',
            type: 'advance',
            amount: 1000,
            date: '2026-10-10',
            created: '2026-10-10T10:00:00Z',
          ),
          _movement(
            id: 'charge-1',
            type: 'driver_charge',
            amount: 300,
            date: '2026-10-11',
            created: '2026-10-11T10:00:00Z',
          ),
          _movement(
            id: 'return-1',
            type: 'cash_return',
            amount: 100,
            date: '2026-10-12',
            created: '2026-10-12T10:00:00Z',
          ),
        ],
        expenseLedgerRows: [_expense(id: 'ledger-1', amount: 200)],
      );

      final balance = result.canonicalBalance;
      expect(balance.checkpoint?.settlementId, 'settlement-1');
      expect(balance.openingBalance.minorUnits, 3000);
      expect(balance.netBalance.minorUnits, 2000);
      expect(result.entries.length, 4);
      expect(
        result.entries.map((entry) => entry.balanceImpact.minorUnits).toList(),
        [-1000, -300, 100, 200],
      );
      expect(
        result.entries.last.source,
        DriverBalanceActivitySource.tripExpense,
      );
      expect(result.entries.last.stableId, 'tripExpense:ledger-1');
      expect(result.entries.last.tripId, 'trip-1');
      expect(result.entries.last.description, 'Diesel');
      expect(
        result.entries.last.businessDate,
        BusinessDate(year: 2026, month: 10, day: 13),
      );
      expect(
        balance.openingBalance.minorUnits +
            result.entries.fold<int>(
              0,
              (sum, entry) => sum + entry.balanceImpact.minorUnits,
            ),
        balance.netBalance.minorUnits,
      );
    });

    test('does not include voided or non-driver-funded expenses', () {
      for (final invalid in [
        _expense(id: 'voided', amount: 200, voided: true),
        _expense(id: 'company-paid', amount: 200, funding: 'company'),
      ]) {
        expect(
          () => mapper.map(
            companyId: 'company-1',
            driverId: 'driver-1',
            currencyCode: 'KWD',
            currencyFractionDigits: 3,
            checkpointRow: null,
            movementRows: const [],
            expenseLedgerRows: [invalid],
          ),
          throwsA(isA<FormatException>()),
        );
      }
    });

    test('rejects currency-mismatched source amounts', () {
      final expense = _expense(id: 'ledger-1', amount: 100);
      expense['currency_code'] = 'AED';
      expect(
        () => mapper.map(
          companyId: 'company-1',
          driverId: 'driver-1',
          currencyCode: 'KWD',
          currencyFractionDigits: 3,
          checkpointRow: null,
          movementRows: const [],
          expenseLedgerRows: [expense],
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

Map<String, dynamic> _movement({
  required String id,
  required String type,
  required int amount,
  required String date,
  required String created,
}) {
  return {
    'id': id,
    'company_id': 'company-1',
    'driver_id': 'driver-1',
    'trip_id': null,
    'movement_type': type,
    'amount_minor_units': amount,
    'currency_code': 'KWD',
    'currency_fraction_digits': 3,
    'movement_date': date,
    'created_at': created,
  };
}

Map<String, dynamic> _expense({
  required String id,
  required int amount,
  bool voided = false,
  String funding = 'driver_cash',
}) {
  return {
    'id': id,
    'company_id': 'company-1',
    'trip_id': 'trip-1',
    'funding_source': funding,
    'is_voided': voided,
    'description': 'Diesel',
    'notes': 'Receipt',
    'amount_minor_units': amount,
    'currency_code': 'KWD',
    'currency_fraction_digits': 3,
    'expense_date': '2026-10-13',
    'created_at': '2026-10-13T10:00:00Z',
  };
}
