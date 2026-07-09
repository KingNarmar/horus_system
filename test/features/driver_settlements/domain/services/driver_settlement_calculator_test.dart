import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_balance_direction.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_input.dart';
import 'package:horus_system/features/driver_settlements/domain/services/driver_settlement_calculator.dart';
import 'package:test/test.dart';

void main() {
  group('DriverSettlementCalculator', () {
    const calculator = DriverSettlementCalculator();

    test('calculates driver owed balance when advances exceed deductions', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(
          openingDriverBalance: 100,
          advancesTotal: 500,
          driverPaidTripExpensesTotal: 250,
          returnedCashTotal: 50,
          deductionsTotal: 75,
          settlementDeductionsTotal: 25,
          grossSalary: 1200,
          salaryDeductionsTotal: 100,
          balanceDeductionApplied: 200,
        ),
      );

      expect(result.closingDriverBalance, 200);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.driverOwesCompany,
      );
      expect(result.balanceAmount, 200);
      expect(result.netSalaryPayable, 900);
    });

    test('calculates company owed balance when driver paid more than advances', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(
          advancesTotal: 100,
          driverPaidTripExpensesTotal: 350,
        ),
      );

      expect(result.closingDriverBalance, -250);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.companyOwesDriver,
      );
      expect(result.balanceAmount, 250);
    });

    test('rounds money values to two decimals', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(
          advancesTotal: 10.005,
          driverPaidTripExpensesTotal: 0,
          grossSalary: 1000.555,
        ),
      );

      expect(result.advancesTotal, 10.01);
      expect(result.closingDriverBalance, 10.01);
      expect(result.netSalaryPayable, 1000.56);
    });
  });
}
