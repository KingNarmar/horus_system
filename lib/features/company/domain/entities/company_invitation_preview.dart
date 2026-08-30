import 'company_invitation_status.dart';
import 'company_role.dart';

class CompanyInvitationPreview {
  final String invitationId;
  final String companyId;
  final String companyName;
  final String email;
  final CompanyRole role;
  final CompanyInvitationStatus status;
  final DateTime expiresAt;

  const CompanyInvitationPreview({
    required this.invitationId,
    required this.companyId,
    required this.companyName,
    required this.email,
    required this.role,
    required this.status,
    required this.expiresAt,
  });
}
