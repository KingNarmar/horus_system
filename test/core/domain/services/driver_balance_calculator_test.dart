import 'package:horus_system/core/domain/services/driver_balance_calculator.dart';
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
  });
}
