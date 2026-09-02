class ExpenseTypeModel {
  final String id;
  final String companyId;
  final String name;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseTypeModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseTypeModel.fromMap(Map<String, dynamic> map) {
    return ExpenseTypeModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      name: map['name'] as String,
      isActive: map['is_active'] as bool? ?? true,
      createdBy: map['created_by'] as String?,
      updatedBy: map['updated_by'] as String?,
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
