import '../../../../core/domain/value_objects/money.dart';

final class DriverSettlementMoneyCalculationInput {
  final Money openingDriverBalance;
  final Money advancesTotal;
  final Money driverPaidTripExpensesTotal;
  final Money returnedCashTotal;
  final Money deductionsTotal;
  final Money settlementDeductionsTotal;
  final Money grossSalary;
  final Money salaryDeductionsTotal;
  final Money balanceDeductionApplied;

  const DriverSettlementMoneyCalculationInput({
    required this.openingDriverBalance,
    required this.advancesTotal,
    required this.driverPaidTripExpensesTotal,
    required this.returnedCashTotal,
    required this.deductionsTotal,
    required this.settlementDeductionsTotal,
    required this.grossSalary,
    required this.salaryDeductionsTotal,
    required this.balanceDeductionApplied,
  });
}
