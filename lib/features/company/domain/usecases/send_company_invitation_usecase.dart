import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_role.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../policies/company_invitation_policy.dart';
import '../repositories/company_invitations_repository.dart';

class SendCompanyInvitationParams {
  final CurrentCompanyContext currentCompanyContext;
  final String email;
  final CompanyRole role;

  const SendCompanyInvitationParams({
    required this.currentCompanyContext,
    required this.email,
    required this.role,
  });
}

class SendCompanyInvitationUseCase
    implements UseCase<void, SendCompanyInvitationParams> {
  final CompanyInvitationsRepository _repository;

  const SendCompanyInvitationUseCase(this._repository);

  @override
  Future<Result<void>> call(SendCompanyInvitationParams params) {
    final context = params.currentCompanyContext;
    final email = params.email.trim().toLowerCase();

    if (email.isEmpty || !email.contains('@')) {
      return Future.value(
        const FailureResult(
          ValidationFailure(code: CompanyFailureCodes.invitationEmailInvalid),
        ),
      );
    }

    if (!CompanyInvitationPolicy.canInviteRole(
      actorRole: context.role,
      targetRole: params.role,
    )) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: CompanyFailureCodes.invitationRoleNotAllowed,
          ),
        ),
      );
    }

    return _repository.sendInvitation(
      companyId: context.companyId,
      email: email,
      role: params.role,
    );
  }
}
