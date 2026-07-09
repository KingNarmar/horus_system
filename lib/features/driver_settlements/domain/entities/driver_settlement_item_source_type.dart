enum DriverSettlementItemSourceType {
  driverFinancialMovement,
  tripExpense,
  manualAdjustment;

  String get value {
    return switch (this) {
      DriverSettlementItemSourceType.driverFinancialMovement =>
        'driver_financial_movement',
      DriverSettlementItemSourceType.tripExpense => 'trip_expense',
      DriverSettlementItemSourceType.manualAdjustment => 'manual_adjustment',
    };
  }

  static DriverSettlementItemSourceType fromValue(String value) {
    return DriverSettlementItemSourceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DriverSettlementItemSourceType.manualAdjustment,
    );
  }
}
