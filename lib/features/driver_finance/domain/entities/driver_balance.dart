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

  double get netBalance => totalAdvances - totalDeductions;
}
