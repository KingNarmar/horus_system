enum ExpenseFundingSource {
  company,
  driverAdvance,
  driverCash,
  customer,
  other,
}

extension ExpenseFundingSourceX on ExpenseFundingSource {
  String get value {
    return switch (this) {
      ExpenseFundingSource.company => 'company',
      ExpenseFundingSource.driverAdvance => 'driver_advance',
      ExpenseFundingSource.driverCash => 'driver_cash',
      ExpenseFundingSource.customer => 'customer',
      ExpenseFundingSource.other => 'other',
    };
  }

  static ExpenseFundingSource fromValue(String? value) {
    return switch (value) {
      'driver_advance' => ExpenseFundingSource.driverAdvance,
      'driver_cash' => ExpenseFundingSource.driverCash,
      'customer' => ExpenseFundingSource.customer,
      'other' => ExpenseFundingSource.other,
      _ => ExpenseFundingSource.company,
    };
  }
}
