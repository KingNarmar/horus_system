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
    double? totalDriverCharges,
    @Deprecated('Use totalDriverCharges instead.') double? totalDeductions,
    this.totalCashReturns = 0,
  }) : totalDriverCharges = totalDriverCharges ?? totalDeductions ?? 0;

  @Deprecated('Use totalDriverCharges instead.')
  double get totalDeductions => totalDriverCharges;

  double get netBalance {
    return const DriverBalanceCalculator().calculate(
      advancesReceived: totalAdvances,
      driverCharges: totalDriverCharges,
      cashReturned: totalCashReturns,
    );
  }
}
