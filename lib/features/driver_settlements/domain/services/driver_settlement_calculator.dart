import '../entities/driver_settlement_calculation_input.dart';
import '../entities/driver_settlement_calculation_result.dart';

class DriverSettlementCalculator {
  const DriverSettlementCalculator();

  DriverSettlementCalculationResult calculate(
    DriverSettlementCalculationInput input,
  ) {
    final closingDriverBalance = _money(
      input.openingDriverBalance +
          input.advancesTotal -
          input.driverPaidTripExpensesTotal -
          input.returnedCashTotal -
          input.deductionsTotal -
          input.settlementDeductionsTotal,
    );

    final netSalaryPayable = _money(
      input.grossSalary -
          input.balanceDeductionApplied -
          input.salaryDeductionsTotal,
    );

    return DriverSettlementCalculationResult(
      openingDriverBalance: _money(input.openingDriverBalance),
      advancesTotal: _money(input.advancesTotal),
      driverPaidTripExpensesTotal: _money(input.driverPaidTripExpensesTotal),
      returnedCashTotal: _money(input.returnedCashTotal),
      deductionsTotal: _money(input.deductionsTotal),
      settlementDeductionsTotal: _money(input.settlementDeductionsTotal),
      grossSalary: _money(input.grossSalary),
      salaryDeductionsTotal: _money(input.salaryDeductionsTotal),
      balanceDeductionApplied: _money(input.balanceDeductionApplied),
      netSalaryPayable: netSalaryPayable,
      closingDriverBalance: closingDriverBalance,
    );
  }

  double _money(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
