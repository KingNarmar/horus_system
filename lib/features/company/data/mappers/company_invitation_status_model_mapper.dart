import '../../domain/entities/company_invitation_status.dart';

abstract final class CompanyInvitationStatusModelMapper {
  static CompanyInvitationStatus fromDatabaseValue(String? value) {
    return switch (value) {
      'pending' => CompanyInvitationStatus.pending,
      'accepted' => CompanyInvitationStatus.accepted,
      'expired' => CompanyInvitationStatus.expired,
      'revoked' => CompanyInvitationStatus.revoked,
      _ => throw FormatException('Unsupported company invitation status.'),
    };
  }
}
