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
            tripExpenseRows: const [],
          )
          .toEntity();

      expect(balance.checkpoint?.settlementId, 'settlement-1');
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
            tripExpenseRows: const [
              {'paid_by': 'driver_advance', 'amount': 40},
              {'paid_by': 'driver_cash', 'amount': 60},
            ],
          )
          .toEntity();

      expect(balance.totalAdvances, 100);
      expect(balance.totalDriverCharges, 50);
      expect(balance.totalTripExpenseCredits, 100);
      expect(balance.totalCashReturns, 25);
      expect(balance.netBalance, -5625);
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
            tripExpenseRows: const [],
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
          tripExpenseRows: const [],
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
          tripExpenseRows: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
