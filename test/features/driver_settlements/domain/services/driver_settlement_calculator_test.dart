import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_balance_direction.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_input.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_calculation_input.dart';
import 'package:horus_system/features/driver_settlements/domain/services/driver_settlement_calculator.dart';
import 'package:test/test.dart';

void main() {
  group('DriverSettlementCalculator driver-perspective balance contract', () {
    const calculator = DriverSettlementCalculator();

    test('advance received decreases the driver balance', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(advancesTotal: 7000),
      );

      expect(result.closingDriverBalance, -7000);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.driverOwesCompany,
      );
      expect(result.balanceAmount, 7000);
    });

    test('advance-funded trip expense reduces outstanding advance', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(
          advancesTotal: 7000,
          driverPaidTripExpensesTotal: 5000,
        ),
      );

      expect(result.closingDriverBalance, -2000);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.driverOwesCompany,
      );
      expect(result.balanceAmount, 2000);
    });

    test('cash returned to company reduces outstanding driver debt', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(
          openingDriverBalance: -2000,
          returnedCashTotal: 500,
        ),
      );

      expect(result.closingDriverBalance, -1500);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.driverOwesCompany,
      );
    });

    test('personal trip expense can create an amount owed to driver', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(
          advancesTotal: 7000,
          driverPaidTripExpensesTotal: 7200,
        ),
      );

      expect(result.closingDriverBalance, 200);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.companyOwesDriver,
      );
      expect(result.balanceAmount, 200);
    });

    test('driver charge decreases the driver balance', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(deductionsTotal: 500),
      );

      expect(result.closingDriverBalance, -500);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.driverOwesCompany,
      );
    });

    test('driver charge plus personal expense leaves driver owing 400', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(
          deductionsTotal: 500,
          driverPaidTripExpensesTotal: 100,
        ),
      );

      expect(result.closingDriverBalance, -400);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.driverOwesCompany,
      );
      expect(result.balanceAmount, 400);
    });

    test('salary recovery changes both net salary and driver balance', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(
          openingDriverBalance: -500,
          grossSalary: 1000,
          balanceDeductionApplied: 300,
        ),
      );

      expect(result.netSalaryPayable, 700);
      expect(result.closingDriverBalance, -200);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.driverOwesCompany,
      );
    });

    test('salary-only deduction does not change custody balance', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(
          openingDriverBalance: -500,
          grossSalary: 1000,
          salaryDeductionsTotal: 100,
        ),
      );

      expect(result.netSalaryPayable, 900);
      expect(result.closingDriverBalance, -500);
    });

    test('settlement charge decreases the driver balance', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(settlementDeductionsTotal: 75),
      );

      expect(result.closingDriverBalance, -75);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.driverOwesCompany,
      );
    });

    test('positive balance means company owes driver', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(openingDriverBalance: 250),
      );

      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.companyOwesDriver,
      );
      expect(result.balanceAmount, 250);
    });

    test('negative balance means driver owes company', () {
      final result = calculator.calculate(
        const DriverSettlementCalculationInput(openingDriverBalance: -250),
      );

      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.driverOwesCompany,
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
      expect(result.closingDriverBalance, -10.01);
      expect(result.netSalaryPayable, 1000.56);
    });
  });

  group('DriverSettlementCalculator exact-money contract', () {
    const calculator = DriverSettlementCalculator();

    test('calculates salary and balance entirely in minor units', () {
      final result = calculator.calculateMoney(
        DriverSettlementMoneyCalculationInput(
          openingDriverBalance: _money(-50000),
          advancesTotal: _money(10000),
          driverPaidTripExpensesTotal: _money(2500),
          returnedCashTotal: _money(5000),
          deductionsTotal: _money(1000),
          settlementDeductionsTotal: _money(500),
          grossSalary: _money(500000),
          salaryDeductionsTotal: _money(10000),
          balanceDeductionApplied: _money(20000),
        ),
      );

      expect(result.netSalaryPayable.minorUnits, 470000);
      expect(result.closingDriverBalance.minorUnits, -34000);
      expect(result.balanceAmountMinorUnits, 34000);
      expect(
        result.balanceDirection,
        DriverSettlementBalanceDirection.driverOwesCompany,
      );
    });

    test('supports currencies with non-two-decimal minor-unit semantics', () {
      final kwd = CurrencyCode.tryParse('KWD')!;
      final result = calculator.calculateMoney(
        DriverSettlementMoneyCalculationInput(
          openingDriverBalance: Money(minorUnits: 0, currency: kwd),
          advancesTotal: Money(minorUnits: 10005, currency: kwd),
          driverPaidTripExpensesTotal: Money(minorUnits: 5, currency: kwd),
          returnedCashTotal: Money(minorUnits: 0, currency: kwd),
          deductionsTotal: Money(minorUnits: 0, currency: kwd),
          settlementDeductionsTotal: Money(minorUnits: 0, currency: kwd),
          grossSalary: Money(minorUnits: 1000555, currency: kwd),
          salaryDeductionsTotal: Money(minorUnits: 0, currency: kwd),
          balanceDeductionApplied: Money(minorUnits: 0, currency: kwd),
        ),
      );

      expect(result.closingDriverBalance.minorUnits, -10000);
      expect(result.netSalaryPayable.minorUnits, 1000555);
      expect(result.netSalaryPayable.currency, kwd);
    });

    test('rejects mixed currencies instead of silently converting', () {
      final usd = CurrencyCode.tryParse('USD')!;

      expect(
        () => calculator.calculateMoney(
          DriverSettlementMoneyCalculationInput(
            openingDriverBalance: _money(0),
            advancesTotal: Money(minorUnits: 10000, currency: usd),
            driverPaidTripExpensesTotal: _money(0),
            returnedCashTotal: _money(0),
            deductionsTotal: _money(0),
            settlementDeductionsTotal: _money(0),
            grossSalary: _money(500000),
            salaryDeductionsTotal: _money(0),
            balanceDeductionApplied: _money(0),
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

Money _money(int minorUnits) {
  return Money(minorUnits: minorUnits, currency: CurrencyCode.tryParse('AED')!);
}
