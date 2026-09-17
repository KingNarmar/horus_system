import '../value_objects/money.dart';

class DriverBalanceCalculator {
  const DriverBalanceCalculator();

  double calculate({
    double openingBalance = 0,
    double advancesReceived = 0,
    double driverCharges = 0,
    double creditedTripExpenses = 0,
    double cashReturned = 0,
    double salaryRecovery = 0,
  }) {
    return roundMoney(
      openingBalance -
          advancesReceived -
          driverCharges +
          creditedTripExpenses +
          cashReturned +
          salaryRecovery,
    );
  }

  Money calculateMoney({
    required Money openingBalance,
    required Money advancesReceived,
    required Money driverCharges,
    required Money creditedTripExpenses,
    required Money cashReturned,
    required Money salaryRecovery,
  }) {
    return openingBalance
        .subtract(advancesReceived)
        .subtract(driverCharges)
        .add(creditedTripExpenses)
        .add(cashReturned)
        .add(salaryRecovery);
  }

  double roundMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
