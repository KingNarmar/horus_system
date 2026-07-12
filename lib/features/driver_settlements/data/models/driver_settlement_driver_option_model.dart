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
      id: map['id'] as String,
      displayName: map['full_name'] as String,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
