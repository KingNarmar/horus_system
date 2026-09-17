import '../../../../core/domain/value_objects/business_date.dart';

final class DriverMoneyBalanceModel {
  final String companyId;
  final String driverId;
  final String currencyCode;
  final int currencyFractionDigits;
  final String? checkpointSettlementId;
  final BusinessDate? checkpointPeriodEnd;
  final DateTime? checkpointSnapshotCreatedAt;
  final int checkpointClosingBalanceMinorUnits;
  final int totalAdvancesMinorUnits;
  final int totalDriverChargesMinorUnits;
  final int totalTripExpenseCreditsMinorUnits;
  final int totalCashReturnsMinorUnits;

  const DriverMoneyBalanceModel({
    required this.companyId,
    required this.driverId,
    required this.currencyCode,
    required this.currencyFractionDigits,
    required this.checkpointClosingBalanceMinorUnits,
    required this.totalAdvancesMinorUnits,
    required this.totalDriverChargesMinorUnits,
    required this.totalTripExpenseCreditsMinorUnits,
    required this.totalCashReturnsMinorUnits,
    this.checkpointSettlementId,
    this.checkpointPeriodEnd,
    this.checkpointSnapshotCreatedAt,
  });

  bool get hasCheckpoint => checkpointSettlementId != null;
}
