import '../../../../core/domain/value_objects/money.dart';
import 'driver_settlement_balance_direction.dart';

final class DriverSettlementMoneyCalculationResult {
  final Money openingDriverBalance;
  final Money advancesTotal;
  final Money driverPaidTripExpensesTotal;
  final Money returnedCashTotal;
  final Money deductionsTotal;
  final Money settlementDeductionsTotal;
  final Money grossSalary;
  final Money salaryDeductionsTotal;
  final Money balanceDeductionApplied;
  final Money netSalaryPayable;
  final Money closingDriverBalance;

  const DriverSettlementMoneyCalculationResult({
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
    if (closingDriverBalance.isNegative) {
      return DriverSettlementBalanceDirection.driverOwesCompany;
    }
    if (closingDriverBalance.isPositive) {
      return DriverSettlementBalanceDirection.companyOwesDriver;
    }
    return DriverSettlementBalanceDirection.settled;
  }

  int get balanceAmountMinorUnits => closingDriverBalance.minorUnits.abs();
}
