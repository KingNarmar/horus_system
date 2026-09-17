import '../../../../core/domain/services/driver_balance_calculator.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'driver_balance_checkpoint.dart';

class DriverBalance {
  final String companyId;
  final String driverId;
  final DriverBalanceCheckpoint? checkpoint;
  final Money totalAdvances;
  final Money totalDriverCharges;
  final Money totalTripExpenseCredits;
  final Money totalCashReturns;

  const DriverBalance({
    required this.companyId,
    required this.driverId,
    required this.totalAdvances,
    required this.totalDriverCharges,
    required this.totalTripExpenseCredits,
    required this.totalCashReturns,
    this.checkpoint,
  });

  Money get openingBalance {
    return checkpoint?.closingBalance ??
        Money(minorUnits: 0, currency: totalAdvances.currency);
  }

  Money get netBalance {
    final currency = totalAdvances.currency;
    return const DriverBalanceCalculator().calculate(
      openingBalance: openingBalance,
      advancesReceived: totalAdvances,
      driverCharges: totalDriverCharges,
      creditedTripExpenses: totalTripExpenseCredits,
      cashReturned: totalCashReturns,
      salaryRecovery: Money(minorUnits: 0, currency: currency),
    );
  }
}
