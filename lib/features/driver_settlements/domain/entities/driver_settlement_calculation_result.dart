import 'driver_settlement_balance_direction.dart';

class DriverSettlementCalculationResult {
  final double openingDriverBalance;
  final double advancesTotal;
  final double driverPaidTripExpensesTotal;
  final double returnedCashTotal;
  final double deductionsTotal;
  final double settlementDeductionsTotal;
  final double grossSalary;
  final double salaryDeductionsTotal;
  final double balanceDeductionApplied;
  final double netSalaryPayable;
  final double closingDriverBalance;

  const DriverSettlementCalculationResult({
    required this.openingDriverBalance,
    required this.advancesTotal,
    required this.driverPaidTripExpensesTotal,
    required this.returnedCashTotal,
    required this.deductionsTotal,
    required this.settlementDeductionsTotal,
    required this.grossSalary,
    required this.salaryDeductionsTotal,
    required this.balanceDeductionApplied,
    required this.netSalaryPayable,
    required this.closingDriverBalance,
  });

  DriverSettlementBalanceDirection get balanceDirection {
    if (closingDriverBalance < 0) {
      return DriverSettlementBalanceDirection.driverOwesCompany;
    }

    if (closingDriverBalance > 0) {
      return DriverSettlementBalanceDirection.companyOwesDriver;
    }

    return DriverSettlementBalanceDirection.settled;
  }

  double get balanceAmount {
    return closingDriverBalance.abs();
  }
}
