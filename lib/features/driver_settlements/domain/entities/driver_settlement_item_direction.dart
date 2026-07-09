enum DriverSettlementItemDirection {
  companyToDriver,
  driverToCompany,
  neutral;

  String get value {
    return switch (this) {
      DriverSettlementItemDirection.companyToDriver => 'company_to_driver',
      DriverSettlementItemDirection.driverToCompany => 'driver_to_company',
      DriverSettlementItemDirection.neutral => 'neutral',
    };
  }

  static DriverSettlementItemDirection fromValue(String value) {
    return DriverSettlementItemDirection.values.firstWhere(
      (direction) => direction.value == value,
      orElse: () => DriverSettlementItemDirection.neutral,
    );
  }
}
