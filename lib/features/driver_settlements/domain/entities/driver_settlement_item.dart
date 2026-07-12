import 'driver_settlement_item_direction.dart';
import 'driver_settlement_item_source_type.dart';

class DriverSettlementItem {
  final String? id;
  final String companyId;
  final String? settlementId;
  final DriverSettlementItemSourceType sourceType;
  final String? sourceId;
  final DateTime? sourceDate;
  final DriverSettlementItemDirection direction;
  final double amount;
  final String labelKey;
  final String? descriptionKey;
  final Map<String, Object?> metadata;

  const DriverSettlementItem({
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
