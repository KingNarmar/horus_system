import '../constants/company_invitation_rpc.dart';

class CompanyInvitationDeliveryPreparationModel {
  final String invitationId;
  final String companyId;
  final String email;
  final String role;
  final DateTime expiresAt;
  final String deliveryAttemptId;

  const CompanyInvitationDeliveryPreparationModel({
    required this.invitationId,
    required this.companyId,
    required this.email,
    required this.role,
    required this.expiresAt,
    required this.deliveryAttemptId,
  });

  factory CompanyInvitationDeliveryPreparationModel.fromRpcMap(
    Map<String, dynamic> map,
  ) {
    return CompanyInvitationDeliveryPreparationModel(
      invitationId: map[CompanyInvitationRpc.invitationId] as String,
      companyId: map[CompanyInvitationRpc.companyId] as String,
      email: map[CompanyInvitationRpc.emailNormalized] as String,
      role: map[CompanyInvitationRpc.invitationRole] as String,
      expiresAt: DateTime.parse(map[CompanyInvitationRpc.expiresAt] as String),
      deliveryAttemptId: map[CompanyInvitationRpc.deliveryAttemptId] as String,
    );
  }
}
