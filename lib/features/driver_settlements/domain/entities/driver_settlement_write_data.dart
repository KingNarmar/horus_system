import 'driver_settlement_calculation_result.dart';
import 'driver_settlement_item.dart';
import 'driver_settlement_money_calculation_result.dart';
import 'driver_settlement_money_item.dart';
import 'driver_settlement_period.dart';

class DriverSettlementDraftWriteData {
  final String companyId;
  final String driverId;
  final DriverSettlementPeriod period;
  final DriverSettlementCalculationResult calculation;
  final List<DriverSettlementItem> items;
  final String? notes;

  const DriverSettlementDraftWriteData({
    required this.companyId,
    required this.driverId,
    required this.period,
    required this.calculation,
    this.items = const [],
    this.notes,
  });
}

final class DriverSettlementMoneyDraftWriteData {
  final String companyId;
  final String driverId;
  final DriverSettlementPeriod period;
  final String compensationRevisionId;
  final int currencyFractionDigits;
  final DriverSettlementMoneyCalculationResult calculation;
  final List<DriverSettlementMoneyItem> items;
  final String? notes;

  const DriverSettlementMoneyDraftWriteData({
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

class DriverSettlementFinalizeData {
  final String companyId;
  final String settlementId;

  const DriverSettlementFinalizeData({
    required this.companyId,
    required this.settlementId,
  });
}

class DriverSettlementVoidData {
  final String companyId;
  final String settlementId;
  final String reason;

  const DriverSettlementVoidData({
    required this.companyId,
    required this.settlementId,
    required this.reason,
  });
}
