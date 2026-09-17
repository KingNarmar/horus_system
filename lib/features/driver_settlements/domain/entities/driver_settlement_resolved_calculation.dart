import 'driver_settlement_money_calculation_result.dart';
import 'driver_settlement_money_item.dart';
import 'driver_settlement_period.dart';

final class DriverSettlementResolvedCalculation {
  final String companyId;
  final String driverId;
  final DriverSettlementPeriod period;
  final String compensationRevisionId;
  final int currencyFractionDigits;
  final DriverSettlementMoneyCalculationResult calculation;
  final List<DriverSettlementMoneyItem> items;
  final String? notes;

  const DriverSettlementResolvedCalculation({
    required this.companyId,
    required this.driverId,
    required this.period,
    required this.compensationRevisionId,
    required this.currencyFractionDigits,
    required this.calculation,
    this.items = const [],
    this.notes,
  });
}
