import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_role.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../policies/company_membership_management_policy.dart';
import '../repositories/company_membership_repository.dart';

class DeactivateCompanyMemberParams {
  final CurrentCompanyContext currentCompanyContext;
  final String membershipId;
  final CompanyRole targetRole;

  const DeactivateCompanyMemberParams({
    required this.currentCompanyContext,
    required this.membershipId,
    required this.targetRole,
  });
}

class DeactivateCompanyMemberUseCase
    implements UseCase<void, DeactivateCompanyMemberParams> {
  final CompanyMembershipRepository _repository;

  const DeactivateCompanyMemberUseCase(this._repository);

  @override
  Future<Result<void>> call(DeactivateCompanyMemberParams params) {
    final context = params.currentCompanyContext;
    if (!CompanyMembershipManagementPolicy.canChangeActiveStatus(
      actorRole: context.role,
      targetRole: params.targetRole,
    )) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: CompanyFailureCodes.memberStatusChangeNotAllowed,
          ),
        ),
      );
    }

    return _repository.deactivate(
      companyId: context.companyId,
      membershipId: params.membershipId.trim(),
    );
  }
}
