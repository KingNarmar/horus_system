import '../../domain/entities/company_role.dart';
import '../mappers/company_role_model_mapper.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/company_db_fields.dart';

class CompanyUserModel {
  final String id;
  final String companyId;
  final String userId;
  final String? displayName;
  final String? phone;
  final CompanyRole role;
  final bool isActive;

  const CompanyUserModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    required this.isActive,
    this.displayName,
    this.phone,
  });

  factory CompanyUserModel.fromMaps({
    required Map<String, dynamic> companyUserMap,
    Map<String, dynamic>? userProfileMap,
  }) {
    return CompanyUserModel(
      id: companyUserMap[DbCommonFields.id] as String,
      companyId: companyUserMap[DbCommonFields.companyId] as String,
      userId: companyUserMap[CompanyDbFields.userId] as String,
      displayName: userProfileMap?[CompanyDbFields.fullName] as String?,
      phone: userProfileMap?['phone'] as String?,
      role: CompanyRoleModelMapper.fromDatabaseValue(
        companyUserMap[CompanyDbFields.role] as String?,
      ),
      isActive: companyUserMap[DbCommonFields.isActive] as bool? ?? true,
    );
  }
}
