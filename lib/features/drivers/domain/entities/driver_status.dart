enum DriverStatus {
  active,
  inactive,
}

extension DriverStatusX on DriverStatus {
  bool get isActive => this == DriverStatus.active;
}
