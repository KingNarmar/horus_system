import '../../domain/entities/company_role.dart';

class CompanyUserModel {
  final String id;
  final String companyId;
  final String userId;
  final String? displayName;
  final String? email;
  final CompanyRole role;
  final bool isActive;

  const CompanyUserModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.role,
    required this.isActive,
    this.displayName,
    this.email,
  });

  factory CompanyUserModel.fromMap(Map<String, dynamic> map) {
    return CompanyUserModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      userId: map['user_id'] as String,
      displayName: map['display_name'] as String?,
      email: map['email'] as String?,
      role: CompanyRoleMapper.fromValue(map['role'] as String?),
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
