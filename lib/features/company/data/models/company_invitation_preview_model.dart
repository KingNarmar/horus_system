import '../../domain/entities/company_invitation_preview.dart';
import '../../domain/entities/company_role.dart';
import '../constants/company_invitation_rpc.dart';
import '../mappers/company_invitation_status_model_mapper.dart';
import '../mappers/company_role_model_mapper.dart';

class CompanyInvitationPreviewModel {
  final String invitationId;
  final String companyId;
  final String companyName;
  final String email;
  final CompanyRole role;
  final String statusValue;
  final DateTime expiresAt;

  const CompanyInvitationPreviewModel({
    required this.invitationId,
    required this.companyId,
    required this.companyName,
    required this.email,
    required this.role,
    required this.statusValue,
    required this.expiresAt,
  });

  factory CompanyInvitationPreviewModel.fromRpcMap(Map<String, dynamic> map) {
    return CompanyInvitationPreviewModel(
      invitationId: map[CompanyInvitationRpc.invitationId] as String,
      companyId: map[CompanyInvitationRpc.companyId] as String,
      companyName: map[CompanyInvitationRpc.companyName] as String,
      email: map[CompanyInvitationRpc.emailNormalized] as String,
      role: CompanyRoleModelMapper.fromRequiredDatabaseValue(
        map[CompanyInvitationRpc.invitationRole] as String?,
      ),
      statusValue: map[CompanyInvitationRpc.effectiveStatus] as String,
      expiresAt: DateTime.parse(map[CompanyInvitationRpc.expiresAt] as String),
    );
  }

  CompanyInvitationPreview toEntity() {
    return CompanyInvitationPreview(
      invitationId: invitationId,
      companyId: companyId,
      companyName: companyName,
      email: email,
      role: role,
      status: CompanyInvitationStatusModelMapper.fromDatabaseValue(statusValue),
      expiresAt: expiresAt,
    );
  }
}
