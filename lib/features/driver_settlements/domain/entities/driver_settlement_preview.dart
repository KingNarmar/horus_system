import 'driver_settlement_calculation_result.dart';
import 'driver_settlement_item.dart';
import 'driver_settlement_period.dart';

class DriverSettlementPreview {
  final String companyId;
  final String driverId;
  final DriverSettlementPeriod period;
  final DriverSettlementCalculationResult calculation;
  final List<DriverSettlementItem> items;

  const DriverSettlementPreview({
    required this.companyId,
    required this.driverId,
    required this.period,
    required this.calculation,
    this.items = const [],
  });
}
