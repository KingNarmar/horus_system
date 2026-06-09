import '../../domain/entities/company_role.dart';

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
      id: companyUserMap['id'] as String,
      companyId: companyUserMap['company_id'] as String,
      userId: companyUserMap['user_id'] as String,
      displayName: userProfileMap?['full_name'] as String?,
      phone: userProfileMap?['phone'] as String?,
      role: CompanyRoleMapper.fromValue(companyUserMap['role'] as String?),
      isActive: companyUserMap['is_active'] as bool? ?? true,
    );
  }
}
