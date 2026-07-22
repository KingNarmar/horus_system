class DriverBalanceModel {
  final String companyId;
  final String driverId;
  final String? checkpointSettlementId;
  final DateTime? checkpointPeriodEnd;
  final DateTime? checkpointSnapshotCreatedAt;
  final double checkpointClosingBalance;
  final double totalAdvances;
  final double totalDriverCharges;
  final double totalTripExpenseCredits;
  final double totalCashReturns;

  const DriverBalanceModel({
    required this.companyId,
    required this.driverId,
    required this.checkpointClosingBalance,
    required this.totalAdvances,
    required this.totalDriverCharges,
    required this.totalTripExpenseCredits,
    required this.totalCashReturns,
    this.checkpointSettlementId,
    this.checkpointPeriodEnd,
    this.checkpointSnapshotCreatedAt,
  });

  bool get hasCheckpoint => checkpointSettlementId != null;
}
