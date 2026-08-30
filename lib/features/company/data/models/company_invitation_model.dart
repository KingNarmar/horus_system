import '../../domain/entities/company_invitation.dart';
import '../../domain/entities/company_role.dart';
import '../constants/company_invitation_rpc.dart';
import '../mappers/company_invitation_status_model_mapper.dart';
import '../mappers/company_role_model_mapper.dart';

class CompanyInvitationModel {
  final String id;
  final String companyId;
  final String email;
  final CompanyRole role;
  final String statusValue;
  final DateTime expiresAt;
  final DateTime? lastSentAt;
  final int sendCount;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;

  const CompanyInvitationModel({
    required this.id,
    required this.companyId,
    required this.email,
    required this.role,
    required this.statusValue,
    required this.expiresAt,
    required this.lastSentAt,
    required this.sendCount,
    required this.createdAt,
    required this.acceptedAt,
    required this.revokedAt,
  });

  factory CompanyInvitationModel.fromRpcMap(Map<String, dynamic> map) {
    return CompanyInvitationModel(
      id: map[CompanyInvitationRpc.invitationId] as String,
      companyId: map[CompanyInvitationRpc.companyId] as String,
      email: map[CompanyInvitationRpc.emailNormalized] as String,
      role: CompanyRoleModelMapper.fromDatabaseValue(
        map[CompanyInvitationRpc.invitationRole] as String?,
      ),
      statusValue: map[CompanyInvitationRpc.effectiveStatus] as String,
      expiresAt: DateTime.parse(map[CompanyInvitationRpc.expiresAt] as String),
      lastSentAt: _dateTimeOrNull(map[CompanyInvitationRpc.lastSentAt]),
      sendCount: map[CompanyInvitationRpc.sendCount] as int? ?? 0,
      createdAt: DateTime.parse(map[CompanyInvitationRpc.createdAt] as String),
      acceptedAt: _dateTimeOrNull(map[CompanyInvitationRpc.acceptedAt]),
      revokedAt: _dateTimeOrNull(map[CompanyInvitationRpc.revokedAt]),
    );
  }

  CompanyInvitation toEntity() {
    return CompanyInvitation(
      id: id,
      companyId: companyId,
      email: email,
      role: role,
      status: CompanyInvitationStatusModelMapper.fromDatabaseValue(statusValue),
      expiresAt: expiresAt,
      lastSentAt: lastSentAt,
      sendCount: sendCount,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      revokedAt: revokedAt,
    );
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    final text = value as String?;
    return text == null ? null : DateTime.parse(text);
  }
}
