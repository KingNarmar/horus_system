import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/company_expense_db_fields.dart';

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
      id: map[DbCommonFields.id] as String,
      companyId: map[DbCommonFields.companyId] as String,
      name: map[CompanyExpenseCategoryDbFields.name] as String,
      code: map[CompanyExpenseCategoryDbFields.code] as String?,
      isActive: map[DbCommonFields.isActive] as bool? ?? true,
      createdAt: map[DbCommonFields.createdAt] == null
          ? null
          : DateTime.tryParse(map[DbCommonFields.createdAt].toString()),
      updatedAt: map[DbCommonFields.updatedAt] == null
          ? null
          : DateTime.tryParse(map[DbCommonFields.updatedAt].toString()),
    );
  }
}
