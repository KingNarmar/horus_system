import '../../../../core/domain/services/driver_balance_calculator.dart';
import '../entities/driver_settlement_calculation_input.dart';
import '../entities/driver_settlement_calculation_result.dart';

class DriverSettlementCalculator {
  final DriverBalanceCalculator _balanceCalculator;

  const DriverSettlementCalculator({
    DriverBalanceCalculator balanceCalculator = const DriverBalanceCalculator(),
  }) : _balanceCalculator = balanceCalculator;

  DriverSettlementCalculationResult calculate(
    DriverSettlementCalculationInput input,
  ) {
    final closingDriverBalance = _balanceCalculator.calculate(
      openingBalance: input.openingDriverBalance,
      advancesReceived: input.advancesTotal,
      driverCharges:
          input.deductionsTotal + input.settlementDeductionsTotal,
      creditedTripExpenses: input.driverPaidTripExpensesTotal,
      cashReturned: input.returnedCashTotal,
      salaryRecovery: input.balanceDeductionApplied,
    );

    final netSalaryPayable = _balanceCalculator.roundMoney(
      input.grossSalary -
          input.balanceDeductionApplied -
          input.salaryDeductionsTotal,
    );

    return DriverSettlementCalculationResult(
      openingDriverBalance: _balanceCalculator.roundMoney(
        input.openingDriverBalance,
      ),
      advancesTotal: _balanceCalculator.roundMoney(input.advancesTotal),
      driverPaidTripExpensesTotal: _balanceCalculator.roundMoney(
        input.driverPaidTripExpensesTotal,
      ),
      returnedCashTotal: _balanceCalculator.roundMoney(
        input.returnedCashTotal,
      ),
      deductionsTotal: _balanceCalculator.roundMoney(input.deductionsTotal),
      settlementDeductionsTotal: _balanceCalculator.roundMoney(
        input.settlementDeductionsTotal,
      ),
      grossSalary: _balanceCalculator.roundMoney(input.grossSalary),
      salaryDeductionsTotal: _balanceCalculator.roundMoney(
        input.salaryDeductionsTotal,
      ),
      balanceDeductionApplied: _balanceCalculator.roundMoney(
        input.balanceDeductionApplied,
      ),
      netSalaryPayable: netSalaryPayable,
      closingDriverBalance: closingDriverBalance,
    );
  }
}
