import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../policies/company_membership_management_policy.dart';
import '../repositories/company_membership_repository.dart';

class GrantCompanyOwnershipParams {
  final CurrentCompanyContext currentCompanyContext;
  final String membershipId;

  const GrantCompanyOwnershipParams({
    required this.currentCompanyContext,
    required this.membershipId,
  });
}

class GrantCompanyOwnershipUseCase
    implements UseCase<void, GrantCompanyOwnershipParams> {
  final CompanyMembershipRepository _repository;

  const GrantCompanyOwnershipUseCase(this._repository);

  @override
  Future<Result<void>> call(GrantCompanyOwnershipParams params) {
    final context = params.currentCompanyContext;
    if (!CompanyMembershipManagementPolicy.canManageOwnership(context.role)) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: CompanyFailureCodes.ownershipTransferNotAllowed,
          ),
        ),
      );
    }

    return _repository.grantOwnership(
      companyId: context.companyId,
      membershipId: params.membershipId.trim(),
    );
  }
}
