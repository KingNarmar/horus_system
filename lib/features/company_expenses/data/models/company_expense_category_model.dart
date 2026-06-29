class CompanyExpenseCategoryModel {
  final String id;
  final String companyId;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyExpenseCategoryModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyExpenseCategoryModel.fromMap(Map<String, dynamic> map) {
    return CompanyExpenseCategoryModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      name: map['name'] as String,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
