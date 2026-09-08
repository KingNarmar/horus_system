import '../../../../core/domain/value_objects/business_date.dart';

class DriverBalanceCheckpoint {
  final String settlementId;
  final BusinessDate periodEnd;
  final DateTime snapshotCreatedAt;
  final double closingBalance;

  const DriverBalanceCheckpoint({
    required this.settlementId,
    required this.periodEnd,
    required this.snapshotCreatedAt,
    required this.closingBalance,
  });
}
