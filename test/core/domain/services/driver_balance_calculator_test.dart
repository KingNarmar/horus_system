import 'package:horus_system/core/domain/services/driver_balance_calculator.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:test/test.dart';

void main() {
  group('DriverBalanceCalculator', () {
    const calculator = DriverBalanceCalculator();

    test('calculates the balance from the driver perspective', () {
      final balance = calculator.calculate(
        openingBalance: -200,
        advancesReceived: 7000,
        driverCharges: 500,
        creditedTripExpenses: 7100,
        cashReturned: 300,
        salaryRecovery: 100,
      );

      expect(balance, -200);
    });

    test('negative balance means the driver still owes the company', () {
      final balance = calculator.calculate(advancesReceived: 7000);

      expect(balance, -7000);
    });

    test('positive balance means the company owes the driver', () {
      final balance = calculator.calculate(
        advancesReceived: 7000,
        creditedTripExpenses: 7200,
      );

      expect(balance, 200);
    });

    test('rounds money to two decimals', () {
      expect(calculator.calculate(advancesReceived: 10.005), -10.01);
      expect(calculator.roundMoney(1000.555), 1000.56);
    });

    test('calculates exact money without decimal rounding assumptions', () {
      final currency = CurrencyCode.tryParse('BHD')!;

      final balance = calculator.calculateMoney(
        openingBalance: Money(minorUnits: -2000, currency: currency),
        advancesReceived: Money(minorUnits: 7000, currency: currency),
        driverCharges: Money(minorUnits: 500, currency: currency),
        creditedTripExpenses: Money(minorUnits: 7100, currency: currency),
        cashReturned: Money(minorUnits: 300, currency: currency),
        salaryRecovery: Money(minorUnits: 100, currency: currency),
      );

      expect(balance, Money(minorUnits: -2000, currency: currency));
    });

    test('rejects mixed currencies in exact money calculation', () {
      final aed = CurrencyCode.tryParse('AED')!;
      final usd = CurrencyCode.tryParse('USD')!;

      expect(
        () => calculator.calculateMoney(
          openingBalance: Money(minorUnits: 0, currency: aed),
          advancesReceived: Money(minorUnits: 100, currency: usd),
          driverCharges: Money(minorUnits: 0, currency: aed),
          creditedTripExpenses: Money(minorUnits: 0, currency: aed),
          cashReturned: Money(minorUnits: 0, currency: aed),
          salaryRecovery: Money(minorUnits: 0, currency: aed),
        ),
        throwsArgumentError,
      );
    });
  });
}
