import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';

final class DriverSettlementResolvedMoneyInputs {
  final CurrencyConfiguration currencyConfiguration;
  final Money grossSalary;
  final Money salaryDeductionsTotal;
  final Money balanceDeductionApplied;
  final Money settlementDeductionsTotal;

  const DriverSettlementResolvedMoneyInputs({
    required this.currencyConfiguration,
    required this.grossSalary,
    required this.salaryDeductionsTotal,
    required this.balanceDeductionApplied,
    required this.settlementDeductionsTotal,
  });
}
