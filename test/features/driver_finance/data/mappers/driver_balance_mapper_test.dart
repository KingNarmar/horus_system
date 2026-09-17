import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/features/driver_finance/data/mappers/driver_balance_mapper.dart';
import 'package:test/test.dart';

void main() {
  const mapper = DriverBalanceSourceMapper();

  group('DriverBalanceSourceMapper', () {
    test('uses finalized closing balance as the canonical checkpoint', () {
      final balance = mapper
          .map(
            companyId: 'company-1',
            driverId: 'driver-1',
            checkpointRow: {
              'settlement_id': 'settlement-1',
              'period_end': '2026-08-31',
              'snapshot_created_at': '2026-09-01T08:00:00Z',
              'closing_driver_balance': -5600,
            },
            movementRows: const [],
            expenseLedgerRows: const [],
          )
          .toEntity();

      expect(balance.checkpoint?.settlementId, 'settlement-1');
      expect(
        balance.checkpoint?.periodEnd,
        BusinessDate(year: 2026, month: 8, day: 31),
      );
      expect(
        balance.checkpoint?.snapshotCreatedAt,
        DateTime.utc(2026, 9, 1, 8),
      );
      expect(balance.checkpoint?.snapshotCreatedAt.isUtc, isTrue);
      expect(balance.openingBalance, -5600);
      expect(balance.netBalance, -5600);
    });

    test('maps every approved post-checkpoint source exactly once', () {
      final balance = mapper
          .map(
            companyId: 'company-1',
            driverId: 'driver-1',
            checkpointRow: {
              'settlement_id': 'settlement-1',
              'period_end': '2026-08-31',
              'snapshot_created_at': '2026-09-01T08:00:00Z',
              'closing_driver_balance': -5600,
            },
            movementRows: const [
              {'movement_type': 'advance', 'amount': 100},
              {'movement_type': 'driver_charge', 'amount': 50},
              {'movement_type': 'cash_return', 'amount': 25},
            ],
            expenseLedgerRows: const [
              {
                'funding_source': 'driver_advance',
                'amount_minor_units': 4000,
                'currency_fraction_digits': 2,
              },
              {
                'funding_source': 'driver_cash',
                'amount_minor_units': 6000,
                'currency_fraction_digits': 2,
              },
            ],
          )
          .toEntity();

      expect(balance.totalAdvances, 100);
      expect(balance.totalDriverCharges, 50);
      expect(balance.totalTripExpenseCredits, 100);
      expect(balance.totalCashReturns, 25);
      expect(balance.netBalance, -5625);
    });

    test('respects canonical ledger currency fraction digits', () {
      final balance = mapper
          .map(
            companyId: 'company-1',
            driverId: 'driver-1',
            checkpointRow: null,
            movementRows: const [],
            expenseLedgerRows: const [
              {
                'funding_source': 'driver_cash',
                'amount_minor_units': 12345,
                'currency_fraction_digits': 3,
              },
            ],
          )
          .toEntity();

      expect(balance.totalTripExpenseCredits, 12.35);
      expect(balance.netBalance, 12.35);
    });

    test('starts from zero when no finalized checkpoint exists', () {
      final balance = mapper
          .map(
            companyId: 'company-1',
            driverId: 'driver-1',
            checkpointRow: null,
            movementRows: const [
              {'movement_type': 'advance', 'amount': 500},
            ],
            expenseLedgerRows: const [],
          )
          .toEntity();

      expect(balance.checkpoint, isNull);
      expect(balance.openingBalance, 0);
      expect(balance.netBalance, -500);
    });

    test('rejects incomplete checkpoint rows', () {
      expect(
        () => mapper.map(
          companyId: 'company-1',
          driverId: 'driver-1',
          checkpointRow: const {
            'settlement_id': 'settlement-1',
            'closing_driver_balance': -5600,
          },
          movementRows: const [],
          expenseLedgerRows: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-date-only checkpoint period end', () {
      expect(
        () => mapper.map(
          companyId: 'company-1',
          driverId: 'driver-1',
          checkpointRow: const {
            'settlement_id': 'settlement-1',
            'period_end': '2026-08-31T00:00:00Z',
            'snapshot_created_at': '2026-09-01T08:00:00Z',
            'closing_driver_balance': -5600,
          },
          movementRows: const [],
          expenseLedgerRows: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects checkpoint snapshot without trusted timestamp offset', () {
      expect(
        () => mapper.map(
          companyId: 'company-1',
          driverId: 'driver-1',
          checkpointRow: const {
            'settlement_id': 'settlement-1',
            'period_end': '2026-08-31',
            'snapshot_created_at': '2026-09-01T08:00:00',
            'closing_driver_balance': -5600,
          },
          movementRows: const [],
          expenseLedgerRows: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unsupported persistence values', () {
      expect(
        () => mapper.map(
          companyId: 'company-1',
          driverId: 'driver-1',
          checkpointRow: null,
          movementRows: const [
            {'movement_type': 'deduction', 'amount': 100},
          ],
          expenseLedgerRows: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unsupported canonical funding source', () {
      expect(
        () => mapper.map(
          companyId: 'company-1',
          driverId: 'driver-1',
          checkpointRow: null,
          movementRows: const [],
          expenseLedgerRows: const [
            {
              'funding_source': 'company',
              'amount_minor_units': 1000,
              'currency_fraction_digits': 2,
            },
          ],
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
