import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../policies/company_invitation_policy.dart';
import '../repositories/company_invitations_repository.dart';

class RevokeCompanyInvitationParams {
  final CurrentCompanyContext currentCompanyContext;
  final String invitationId;

  const RevokeCompanyInvitationParams({
    required this.currentCompanyContext,
    required this.invitationId,
  });
}

class RevokeCompanyInvitationUseCase
    implements UseCase<void, RevokeCompanyInvitationParams> {
  final CompanyInvitationsRepository _repository;

  const RevokeCompanyInvitationUseCase(this._repository);

  @override
  Future<Result<void>> call(RevokeCompanyInvitationParams params) {
    final context = params.currentCompanyContext;
    if (!CompanyInvitationPolicy.canViewInvitations(context.role)) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: CompanyFailureCodes.invitationPermissionDenied,
          ),
        ),
      );
    }

    final invitationId = params.invitationId.trim();
    if (invitationId.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure(
            code: CompanyFailureCodes.validationInvitationIdRequired,
          ),
        ),
      );
    }

    return _repository.revokeInvitation(
      companyId: context.companyId,
      invitationId: invitationId,
    );
  }
}
