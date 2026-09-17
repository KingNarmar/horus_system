import 'driver_settlement_money_calculation_result.dart';
import 'driver_settlement_money_item.dart';
import 'driver_settlement_period.dart';

final class DriverSettlementPreview {
  final String companyId;
  final String driverId;
  final DriverSettlementPeriod period;
  final String compensationRevisionId;
  final int currencyFractionDigits;
  final DriverSettlementMoneyCalculationResult calculation;
  final List<DriverSettlementMoneyItem> items;

  const DriverSettlementPreview({
    required this.companyId,
    required this.driverId,
    required this.period,
    required this.compensationRevisionId,
    required this.currencyFractionDigits,
    required this.calculation,
    this.items = const [],
  });
}
