import '../../../../core/utils/result.dart';
import '../entities/company_invitation.dart';
import '../entities/company_invitation_preview.dart';
import '../entities/company_role.dart';

abstract class CompanyInvitationsRepository {
  Future<Result<List<CompanyInvitation>>> getInvitations(String companyId);

  Future<Result<void>> sendInvitation({
    required String companyId,
    required String email,
    required CompanyRole role,
  });

  Future<Result<void>> resendInvitation({
    required String companyId,
    required String invitationId,
  });

  Future<Result<void>> revokeInvitation({
    required String companyId,
    required String invitationId,
  });

  Future<Result<CompanyInvitationPreview>> getInvitationPreview(String token);

  Future<Result<String>> acceptInvitation(String token);
}
