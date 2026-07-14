import '../../../../core/domain/services/driver_balance_calculator.dart';

class DriverBalance {
  final String companyId;
  final String driverId;
  final double totalAdvances;
  final double totalDriverCharges;
  final double totalCashReturns;

  const DriverBalance({
    required this.companyId,
    required this.driverId,
    required this.totalAdvances,
    required this.totalDriverCharges,
    this.totalCashReturns = 0,
  });

  double get netBalance {
    return const DriverBalanceCalculator().calculate(
      advancesReceived: totalAdvances,
      driverCharges: totalDriverCharges,
      cashReturned: totalCashReturns,
    );
  }
}
