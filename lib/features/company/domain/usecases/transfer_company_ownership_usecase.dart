import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/company_role.dart';
import '../entities/current_company_context.dart';
import '../failures/company_failure_codes.dart';
import '../policies/company_membership_management_policy.dart';
import '../repositories/company_membership_repository.dart';

class TransferCompanyOwnershipParams {
  final CurrentCompanyContext currentCompanyContext;
  final String targetMembershipId;
  final CompanyRole sourceNewRole;

  const TransferCompanyOwnershipParams({
    required this.currentCompanyContext,
    required this.targetMembershipId,
    required this.sourceNewRole,
  });
}

class TransferCompanyOwnershipUseCase
    implements UseCase<void, TransferCompanyOwnershipParams> {
  final CompanyMembershipRepository _repository;

  const TransferCompanyOwnershipUseCase(this._repository);

  @override
  Future<Result<void>> call(TransferCompanyOwnershipParams params) {
    final context = params.currentCompanyContext;
    if (!CompanyMembershipManagementPolicy.canManageOwnership(context.role) ||
        params.sourceNewRole == CompanyRole.owner) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: CompanyFailureCodes.ownershipTransferNotAllowed,
          ),
        ),
      );
    }

    return _repository.transferOwnership(
      companyId: context.companyId,
      targetMembershipId: params.targetMembershipId.trim(),
      sourceNewRole: params.sourceNewRole,
    );
  }
}
