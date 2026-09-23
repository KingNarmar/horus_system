import '../../domain/entities/company_role.dart';
import '../constants/company_users_rpc.dart';
import '../mappers/company_role_model_mapper.dart';

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

  factory CompanyUserModel.fromRpcMap(Map<String, dynamic> map) {
    return CompanyUserModel(
      id: map[CompanyUsersRpc.membershipId] as String,
      companyId: map[CompanyUsersRpc.companyId] as String,
      userId: map[CompanyUsersRpc.userId] as String,
      displayName: map[CompanyUsersRpc.fullName] as String?,
      phone: map[CompanyUsersRpc.phone] as String?,
      role: CompanyRoleModelMapper.fromRequiredDatabaseValue(
        map[CompanyUsersRpc.memberRole] as String?,
      ),
      isActive: map[CompanyUsersRpc.isActive] as bool,
    );
  }
}
