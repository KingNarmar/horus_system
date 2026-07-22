import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/driver_settlements_db_fields.dart';

class DriverSettlementDriverOptionModel {
  final String id;
  final String displayName;
  final bool isActive;

  const DriverSettlementDriverOptionModel({
    required this.id,
    required this.displayName,
    required this.isActive,
  });

  factory DriverSettlementDriverOptionModel.fromMap(Map<String, dynamic> map) {
    return DriverSettlementDriverOptionModel(
      id: map[DbCommonFields.id] as String,
      displayName: map[DriverSettlementsDbFields.fullName] as String,
      isActive: map[DriverSettlementsDbFields.isActive] as bool,
    );
  }
}
