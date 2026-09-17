import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';

final class DriverMoneyBalanceCheckpoint {
  final String settlementId;
  final BusinessDate periodEnd;
  final DateTime snapshotCreatedAt;
  final Money closingBalance;
  final int currencyFractionDigits;

  const DriverMoneyBalanceCheckpoint({
    required this.settlementId,
    required this.periodEnd,
    required this.snapshotCreatedAt,
    required this.closingBalance,
    required this.currencyFractionDigits,
  });
}
