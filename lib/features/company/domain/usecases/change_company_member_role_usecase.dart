import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_role.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../policies/company_membership_management_policy.dart';
import '../repositories/company_membership_repository.dart';

class ChangeCompanyMemberRoleParams {
  final CurrentCompanyContext currentCompanyContext;
  final String membershipId;
  final CompanyRole currentRole;
  final CompanyRole newRole;

  const ChangeCompanyMemberRoleParams({
    required this.currentCompanyContext,
    required this.membershipId,
    required this.currentRole,
    required this.newRole,
  });
}

class ChangeCompanyMemberRoleUseCase
    implements UseCase<void, ChangeCompanyMemberRoleParams> {
  final CompanyMembershipRepository _repository;

  const ChangeCompanyMemberRoleUseCase(this._repository);

  @override
  Future<Result<void>> call(ChangeCompanyMemberRoleParams params) {
    final context = params.currentCompanyContext;
    if (!CompanyMembershipManagementPolicy.canChangeRole(
      actorRole: context.role,
      targetRole: params.currentRole,
      newRole: params.newRole,
    )) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: CompanyFailureCodes.memberRoleChangeNotAllowed,
          ),
        ),
      );
    }

    final membershipId = params.membershipId.trim();
    if (membershipId.isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure(code: CompanyFailureCodes.memberNotFound),
        ),
      );
    }

    return _repository.changeRole(
      companyId: context.companyId,
      membershipId: membershipId,
      newRole: params.newRole,
    );
  }
}
