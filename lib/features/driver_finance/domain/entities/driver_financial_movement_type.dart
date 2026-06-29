enum DriverFinancialMovementType {
  advance,
  deduction,
}

extension DriverFinancialMovementTypeX on DriverFinancialMovementType {
  String get value {
    return switch (this) {
      DriverFinancialMovementType.advance => 'advance',
      DriverFinancialMovementType.deduction => 'deduction',
    };
  }

  bool get isAdvance => this == DriverFinancialMovementType.advance;

  bool get isDeduction => this == DriverFinancialMovementType.deduction;
}

DriverFinancialMovementType driverFinancialMovementTypeFromValue(String value) {
  return switch (value) {
    'advance' => DriverFinancialMovementType.advance,
    'deduction' => DriverFinancialMovementType.deduction,
    _ => throw ArgumentError.value(
      value,
      'value',
      'Unsupported driver financial movement type',
    ),
  };
}
