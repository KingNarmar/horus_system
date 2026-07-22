class DriverBalanceCheckpoint {
  final String settlementId;
  final DateTime periodEnd;
  final DateTime snapshotCreatedAt;
  final double closingBalance;

  const DriverBalanceCheckpoint({
    required this.settlementId,
    required this.periodEnd,
    required this.snapshotCreatedAt,
    required this.closingBalance,
  });
}
