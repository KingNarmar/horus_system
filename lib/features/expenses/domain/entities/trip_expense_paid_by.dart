enum TripExpensePaidBy { company, driverAdvance, driverCash, customer, other }

extension TripExpensePaidByX on TripExpensePaidBy {
  String get value {
    return switch (this) {
      TripExpensePaidBy.company => 'company',
      TripExpensePaidBy.driverAdvance => 'driver_advance',
      TripExpensePaidBy.driverCash => 'driver_cash',
      TripExpensePaidBy.customer => 'customer',
      TripExpensePaidBy.other => 'other',
    };
  }

  static TripExpensePaidBy fromValue(String? value) {
    return switch (value) {
      'driver_advance' => TripExpensePaidBy.driverAdvance,
      'driver_cash' => TripExpensePaidBy.driverCash,
      'customer' => TripExpensePaidBy.customer,
      'other' => TripExpensePaidBy.other,
      _ => TripExpensePaidBy.company,
    };
  }
}
