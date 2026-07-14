enum DriverFinancialMovementType {
  advance,
  driverCharge,
  cashReturn;

  @Deprecated('Use DriverFinancialMovementType.driverCharge instead.')
  static const deduction = DriverFinancialMovementType.driverCharge;
}

extension DriverFinancialMovementTypeX on DriverFinancialMovementType {
  String get value {
    return switch (this) {
      DriverFinancialMovementType.advance => 'advance',
      DriverFinancialMovementType.driverCharge => 'driver_charge',
      DriverFinancialMovementType.cashReturn => 'cash_return',
    };
  }

  bool get isAdvance => this == DriverFinancialMovementType.advance;

  bool get isDriverCharge => this == DriverFinancialMovementType.driverCharge;

  bool get isCashReturn => this == DriverFinancialMovementType.cashReturn;

  bool get canLinkTrip => isDriverCharge;

  @Deprecated('Use isDriverCharge instead.')
  bool get isDeduction => isDriverCharge;
}

DriverFinancialMovementType driverFinancialMovementTypeFromValue(String value) {
  return switch (value) {
    'advance' => DriverFinancialMovementType.advance,
    'driver_charge' || 'deduction' => DriverFinancialMovementType.driverCharge,
    'cash_return' => DriverFinancialMovementType.cashReturn,
    _ => throw ArgumentError.value(
      value,
      'value',
      'Unsupported driver financial movement type',
    ),
  };
}
