import 'driver_settlement_item.dart';

class DriverSettlementSourceSnapshot {
  final double openingDriverBalance;
  final double advancesTotal;
  final double driverPaidTripExpensesTotal;
  final double returnedCashTotal;
  final double deductionsTotal;
  final List<DriverSettlementItem> sourceItems;

  const DriverSettlementSourceSnapshot({
    this.openingDriverBalance = 0,
    this.advancesTotal = 0,
    this.driverPaidTripExpensesTotal = 0,
    this.returnedCashTotal = 0,
    this.deductionsTotal = 0,
    this.sourceItems = const [],
  });

  DriverSettlementSourceSnapshot withOpeningDriverBalance(double value) {
    return DriverSettlementSourceSnapshot(
      openingDriverBalance: value,
      advancesTotal: advancesTotal,
      driverPaidTripExpensesTotal: driverPaidTripExpensesTotal,
      returnedCashTotal: returnedCashTotal,
      deductionsTotal: deductionsTotal,
      sourceItems: sourceItems,
    );
  }
}
