import '../../../../core/domain/value_objects/money.dart';
import 'driver_settlement_money_item.dart';

final class DriverSettlementMoneySourceSnapshot {
  final Money openingDriverBalance;
  final Money advancesTotal;
  final Money driverPaidTripExpensesTotal;
  final Money returnedCashTotal;
  final Money deductionsTotal;
  final List<DriverSettlementMoneyItem> sourceItems;

  const DriverSettlementMoneySourceSnapshot({
    required this.openingDriverBalance,
    required this.advancesTotal,
    required this.driverPaidTripExpensesTotal,
    required this.returnedCashTotal,
    required this.deductionsTotal,
    this.sourceItems = const [],
  });

  DriverSettlementMoneySourceSnapshot withOpeningDriverBalance(Money value) {
    return DriverSettlementMoneySourceSnapshot(
      openingDriverBalance: value,
      advancesTotal: advancesTotal,
      driverPaidTripExpensesTotal: driverPaidTripExpensesTotal,
      returnedCashTotal: returnedCashTotal,
      deductionsTotal: deductionsTotal,
      sourceItems: sourceItems,
    );
  }
}
