import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_invitation.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../policies/company_invitation_policy.dart';
import '../repositories/company_invitations_repository.dart';

class GetCompanyInvitationsParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetCompanyInvitationsParams({required this.currentCompanyContext});
}

class GetCompanyInvitationsUseCase
    implements UseCase<List<CompanyInvitation>, GetCompanyInvitationsParams> {
  final CompanyInvitationsRepository _repository;

  const GetCompanyInvitationsUseCase(this._repository);

  @override
  Future<Result<List<CompanyInvitation>>> call(
    GetCompanyInvitationsParams params,
  ) {
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

    return _repository.getInvitations(context.companyId);
  }
}
