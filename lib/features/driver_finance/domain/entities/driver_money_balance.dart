import '../../../../core/domain/services/driver_balance_calculator.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'driver_money_balance_checkpoint.dart';

final class DriverMoneyBalance {
  final String companyId;
  final String driverId;
  final CurrencyCode currency;
  final int currencyFractionDigits;
  final DriverMoneyBalanceCheckpoint? checkpoint;
  final Money totalAdvances;
  final Money totalDriverCharges;
  final Money totalTripExpenseCredits;
  final Money totalCashReturns;

  const DriverMoneyBalance({
    required this.companyId,
    required this.driverId,
    required this.currency,
    required this.currencyFractionDigits,
    required this.totalAdvances,
    required this.totalDriverCharges,
    required this.totalTripExpenseCredits,
    required this.totalCashReturns,
    this.checkpoint,
  });

  Money get openingBalance =>
      checkpoint?.closingBalance ?? Money(minorUnits: 0, currency: currency);

  Money get netBalance {
    final zero = Money(minorUnits: 0, currency: currency);
    return const DriverBalanceCalculator().calculateMoney(
      openingBalance: openingBalance,
      advancesReceived: totalAdvances,
      driverCharges: totalDriverCharges,
      creditedTripExpenses: totalTripExpenseCredits,
      cashReturned: totalCashReturns,
      salaryRecovery: zero,
    );
  }
}
