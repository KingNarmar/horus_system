import 'package:horus_system/core/domain/services/driver_balance_calculator.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:test/test.dart';

void main() {
  group('DriverBalanceCalculator', () {
    const calculator = DriverBalanceCalculator();
    final currency = CurrencyCode.tryParse('AED')!;

    Money money(int minorUnits) => Money(
      minorUnits: minorUnits,
      currency: currency,
    );

    test('calculates the balance from the driver perspective', () {
      final balance = calculator.calculate(
        openingBalance: money(-20000),
        advancesReceived: money(700000),
        driverCharges: money(50000),
        creditedTripExpenses: money(710000),
        cashReturned: money(30000),
        salaryRecovery: money(10000),
      );

      expect(balance, money(-20000));
    });

    test('negative balance means the driver still owes the company', () {
      final balance = calculator.calculate(
        openingBalance: money(0),
        advancesReceived: money(700000),
        driverCharges: money(0),
        creditedTripExpenses: money(0),
        cashReturned: money(0),
        salaryRecovery: money(0),
      );

      expect(balance, money(-700000));
    });

    test('positive balance means the company owes the driver', () {
      final balance = calculator.calculate(
        openingBalance: money(0),
        advancesReceived: money(700000),
        driverCharges: money(0),
        creditedTripExpenses: money(720000),
        cashReturned: money(0),
        salaryRecovery: money(0),
      );

      expect(balance, money(20000));
    });

    test('preserves exact minor units without decimal rounding', () {
      final balance = calculator.calculate(
        openingBalance: money(0),
        advancesReceived: money(10005),
        driverCharges: money(0),
        creditedTripExpenses: money(0),
        cashReturned: money(0),
        salaryRecovery: money(0),
      );

      expect(balance.minorUnits, -10005);
    });

    test('rejects mixed currencies', () {
      final usd = CurrencyCode.tryParse('USD')!;

      expect(
        () => calculator.calculate(
          openingBalance: money(0),
          advancesReceived: Money(minorUnits: 1, currency: usd),
          driverCharges: money(0),
          creditedTripExpenses: money(0),
          cashReturned: money(0),
          salaryRecovery: money(0),
        ),
        throwsArgumentError,
      );
    });
  });
}
