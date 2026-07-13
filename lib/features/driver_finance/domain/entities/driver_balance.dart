import '../../../../core/domain/services/driver_balance_calculator.dart';

class DriverBalance {
  final String companyId;
  final String driverId;
  final double totalAdvances;
  final double totalDeductions;

  const DriverBalance({
    required this.companyId,
    required this.driverId,
    required this.totalAdvances,
    required this.totalDeductions,
  });

  double get netBalance {
    return const DriverBalanceCalculator().calculate(
      advancesReceived: totalAdvances,
      driverCharges: totalDeductions,
    );
  }
}
