import 'company_invitation_status.dart';
import 'company_role.dart';

class CompanyInvitation {
  final String id;
  final String companyId;
  final String email;
  final CompanyRole role;
  final CompanyInvitationStatus status;
  final DateTime expiresAt;
  final DateTime? lastSentAt;
  final int sendCount;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;

  const CompanyInvitation({
    required this.id,
    required this.companyId,
    required this.email,
    required this.role,
    required this.status,
    required this.expiresAt,
    required this.lastSentAt,
    required this.sendCount,
    required this.createdAt,
    required this.acceptedAt,
    required this.revokedAt,
  });
}
