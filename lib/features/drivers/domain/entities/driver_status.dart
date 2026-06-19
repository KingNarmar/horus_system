enum DriverStatus {
  active,
  inactive;

  bool get isActive => this == DriverStatus.active;
}
