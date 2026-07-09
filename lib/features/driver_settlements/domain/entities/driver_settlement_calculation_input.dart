class DriverSettlementCalculationInput {
  final double openingDriverBalance;
  final double advancesTotal;
  final double driverPaidTripExpensesTotal;
  final double returnedCashTotal;
  final double deductionsTotal;
  final double settlementDeductionsTotal;
  final double grossSalary;
  final double salaryDeductionsTotal;
  final double balanceDeductionApplied;

  const DriverSettlementCalculationInput({
    this.openingDriverBalance = 0,
    this.advancesTotal = 0,
    this.driverPaidTripExpensesTotal = 0,
    this.returnedCashTotal = 0,
    this.deductionsTotal = 0,
    this.settlementDeductionsTotal = 0,
    this.grossSalary = 0,
    this.salaryDeductionsTotal = 0,
    this.balanceDeductionApplied = 0,
  });
}
