import 'package:horus_system/features/driver_finance/data/mappers/driver_money_balance_mapper.dart';
import 'package:test/test.dart';

void main() {
  const mapper = DriverMoneyBalanceSourceMapper();

  group('DriverMoneyBalanceSourceMapper', () {
    test('maps checkpoint and canonical sources in exact minor units', () {
      final balance = mapper
          .map(
            companyId: 'company-1',
            driverId: 'driver-1',
            currencyCode: 'AED',
            currencyFractionDigits: 2,
            checkpointRow: const {
              'settlement_id': 'settlement-1',
              'period_end': '2026-08-31',
              'snapshot_created_at': '2026-09-01T08:00:00Z',
              'closing_driver_balance_minor_units': -560000,
              'currency_code': 'AED',
              'currency_fraction_digits': 2,
            },
            movementRows: const [
              {
                'movement_type': 'advance',
                'amount_minor_units': 10000,
                'currency_code': 'AED',
                'currency_fraction_digits': 2,
              },
              {
                'movement_type': 'driver_charge',
                'amount_minor_units': 5000,
                'currency_code': 'AED',
                'currency_fraction_digits': 2,
              },
              {
                'movement_type': 'cash_return',
                'amount_minor_units': 2500,
                'currency_code': 'AED',
                'currency_fraction_digits': 2,
              },
            ],
            expenseLedgerRows: const [
              {
                'funding_source': 'driver_advance',
                'amount_minor_units': 4000,
                'currency_code': 'AED',
                'currency_fraction_digits': 2,
              },
              {
                'funding_source': 'driver_cash',
                'amount_minor_units': 6000,
                'currency_code': 'AED',
                'currency_fraction_digits': 2,
              },
            ],
          )
          .toEntity();

      expect(balance.openingBalance.minorUnits, -560000);
      expect(balance.totalAdvances.minorUnits, 10000);
      expect(balance.totalDriverCharges.minorUnits, 5000);
      expect(balance.totalTripExpenseCredits.minorUnits, 10000);
      expect(balance.totalCashReturns.minorUnits, 2500);
      expect(balance.netBalance.minorUnits, -562500);
      expect(balance.currency.value, 'AED');
      expect(balance.currencyFractionDigits, 2);
    });

    test('preserves three-decimal currency minor units without rounding', () {
      final balance = mapper
          .map(
            companyId: 'company-1',
            driverId: 'driver-1',
            currencyCode: 'KWD',
            currencyFractionDigits: 3,
            checkpointRow: null,
            movementRows: const [
              {
                'movement_type': 'advance',
                'amount_minor_units': 1001,
                'currency_code': 'KWD',
                'currency_fraction_digits': 3,
              },
            ],
            expenseLedgerRows: const [
              {
                'funding_source': 'driver_cash',
                'amount_minor_units': 2,
                'currency_code': 'KWD',
                'currency_fraction_digits': 3,
              },
            ],
          )
          .toEntity();

      expect(balance.netBalance.minorUnits, -999);
      expect(balance.currencyFractionDigits, 3);
    });

    test('rejects a source row in another currency', () {
      expect(
        () => mapper.map(
          companyId: 'company-1',
          driverId: 'driver-1',
          currencyCode: 'AED',
          currencyFractionDigits: 2,
          checkpointRow: null,
          movementRows: const [
            {
              'movement_type': 'advance',
              'amount_minor_units': 100,
              'currency_code': 'USD',
              'currency_fraction_digits': 2,
            },
          ],
          expenseLedgerRows: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a source row with another fraction-digit snapshot', () {
      expect(
        () => mapper.map(
          companyId: 'company-1',
          driverId: 'driver-1',
          currencyCode: 'AED',
          currencyFractionDigits: 2,
          checkpointRow: null,
          movementRows: const [],
          expenseLedgerRows: const [
            {
              'funding_source': 'driver_cash',
              'amount_minor_units': 100,
              'currency_code': 'AED',
              'currency_fraction_digits': 3,
            },
          ],
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
