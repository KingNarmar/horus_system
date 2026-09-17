import '../value_objects/money.dart';

class DriverBalanceCalculator {
  const DriverBalanceCalculator();

  Money calculate({
    required Money openingBalance,
    required Money advancesReceived,
    required Money driverCharges,
    required Money creditedTripExpenses,
    required Money cashReturned,
    required Money salaryRecovery,
  }) {
    _ensureSameCurrency([
      openingBalance,
      advancesReceived,
      driverCharges,
      creditedTripExpenses,
      cashReturned,
      salaryRecovery,
    ]);

    return Money(
      minorUnits:
          openingBalance.minorUnits -
          advancesReceived.minorUnits -
          driverCharges.minorUnits +
          creditedTripExpenses.minorUnits +
          cashReturned.minorUnits +
          salaryRecovery.minorUnits,
      currency: openingBalance.currency,
    );
  }

  void _ensureSameCurrency(List<Money> values) {
    if (values.isEmpty) return;
    final currency = values.first.currency;
    if (values.any((value) => value.currency != currency)) {
      throw ArgumentError('Driver balance money currencies must match.');
    }
  }
}
