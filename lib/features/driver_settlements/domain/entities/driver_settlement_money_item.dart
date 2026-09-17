import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'driver_settlement_item_direction.dart';
import 'driver_settlement_item_source_type.dart';

final class DriverSettlementMoneyItem {
  final String? id;
  final String companyId;
  final String? settlementId;
  final DriverSettlementItemSourceType sourceType;
  final String? sourceId;
  final BusinessDate? sourceDate;
  final DriverSettlementItemDirection direction;
  final Money amount;
  final String labelKey;
  final String? descriptionKey;
  final Map<String, Object?> metadata;

  const DriverSettlementMoneyItem({
    this.id,
    required this.companyId,
    this.settlementId,
    required this.sourceType,
    this.sourceId,
    this.sourceDate,
    required this.direction,
    required this.amount,
    required this.labelKey,
    this.descriptionKey,
    this.metadata = const {},
  });
}
