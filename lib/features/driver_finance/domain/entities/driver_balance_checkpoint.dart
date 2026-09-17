import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';

class DriverBalanceCheckpoint {
  final String settlementId;
  final BusinessDate periodEnd;
  final DateTime snapshotCreatedAt;
  final Money closingBalance;

  const DriverBalanceCheckpoint({
    required this.settlementId,
    required this.periodEnd,
    required this.snapshotCreatedAt,
    required this.closingBalance,
  });
}
