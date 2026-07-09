class CompanyExpenseCategoryModel {
  final String id;
  final String companyId;
  final String name;
  final String? code;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyExpenseCategoryModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.isActive,
    this.code,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyExpenseCategoryModel.fromMap(Map<String, dynamic> map) {
    return CompanyExpenseCategoryModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
    );
  }
}
