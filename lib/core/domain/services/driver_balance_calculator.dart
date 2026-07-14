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

  double roundMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
