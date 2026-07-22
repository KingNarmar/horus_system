import '../../../../core/domain/services/driver_balance_calculator.dart';
import 'driver_balance_checkpoint.dart';

class DriverBalance {
  final String companyId;
  final String driverId;
  final DriverBalanceCheckpoint? checkpoint;
  final double totalAdvances;
  final double totalDriverCharges;
  final double totalTripExpenseCredits;
  final double totalCashReturns;

  const DriverBalance({
    required this.companyId,
    required this.driverId,
    required this.totalAdvances,
    required this.totalDriverCharges,
    this.checkpoint,
    this.totalTripExpenseCredits = 0,
    this.totalCashReturns = 0,
  });

  double get openingBalance => checkpoint?.closingBalance ?? 0;

  double get netBalance {
    return const DriverBalanceCalculator().calculate(
      openingBalance: openingBalance,
      advancesReceived: totalAdvances,
      driverCharges: totalDriverCharges,
      creditedTripExpenses: totalTripExpenseCredits,
      cashReturned: totalCashReturns,
    );
  }
}
