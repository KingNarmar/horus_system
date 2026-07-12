import '../../domain/entities/driver_settlement_item_direction.dart';
import '../../domain/entities/driver_settlement_item_source_type.dart';
import '../constants/driver_settlements_db_fields.dart';

class DriverSettlementItemModel {
  final String id;
  final String companyId;
  final String settlementId;
  final DriverSettlementItemSourceType sourceType;
  final String? sourceId;
  final DateTime? sourceDate;
  final DriverSettlementItemDirection direction;
  final double amount;
  final String labelKey;
  final String? descriptionKey;
  final Map<String, Object?> metadata;
  final DateTime? createdAt;

  const DriverSettlementItemModel({
    required this.id,
    required this.companyId,
    required this.settlementId,
    required this.sourceType,
    required this.direction,
    required this.amount,
    required this.labelKey,
    this.sourceId,
    this.sourceDate,
    this.descriptionKey,
    this.metadata = const {},
    this.createdAt,
  });

  factory DriverSettlementItemModel.fromMap(Map<String, dynamic> map) {
    return DriverSettlementItemModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      settlementId: map[DriverSettlementsDbFields.settlementId] as String,
      sourceType: DriverSettlementItemSourceType.fromValue(
        map[DriverSettlementsDbFields.sourceType].toString(),
      ),
      sourceId: map[DriverSettlementsDbFields.sourceId] as String?,
      sourceDate: _dateFrom(map[DriverSettlementsDbFields.sourceDate]),
      direction: DriverSettlementItemDirection.fromValue(
        map[DriverSettlementsDbFields.direction].toString(),
      ),
      amount: _amountFrom(map[DriverSettlementsDbFields.amount]),
      labelKey: map[DriverSettlementsDbFields.labelKey] as String,
      descriptionKey: map[DriverSettlementsDbFields.descriptionKey] as String?,
      metadata: _metadataFrom(map[DriverSettlementsDbFields.metadata]),
      createdAt: _dateTimeFrom(map['created_at']),
    );
  }
}

Map<String, Object?> _metadataFrom(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  return const {};
}

double _amountFrom(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateFrom(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime? _dateTimeFrom(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
