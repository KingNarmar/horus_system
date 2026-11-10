import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/company_quota_snapshot.dart';
import '../failures/quota_failure_codes.dart';
import '../policies/entitlement_visibility_policy.dart';
import '../repositories/company_quota_repository.dart';

final class GetCompanyQuotaUsageParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetCompanyQuotaUsageParams({required this.currentCompanyContext});
}

/// Only selected, authenticated company context can initiate a usage read.
final class GetCompanyQuotaUsageUseCase
    implements UseCase<CompanyQuotaSnapshot, GetCompanyQuotaUsageParams> {
  final CompanyQuotaRepository _repository;

  const GetCompanyQuotaUsageUseCase(this._repository);

  @override
  Future<Result<CompanyQuotaSnapshot>> call(GetCompanyQuotaUsageParams params) {
    if (!EntitlementVisibilityPolicy.canView(params.currentCompanyContext.role)) {
      return Future.value(
        const FailureResult<CompanyQuotaSnapshot>(
          PermissionFailure(code: QuotaFailureCodes.permissionDenied),
        ),
      );
    }

    final companyId = params.currentCompanyContext.companyId.trim();
    if (companyId.isEmpty) {
      return Future.value(
        const FailureResult<CompanyQuotaSnapshot>(
          ValidationFailure(code: FailureCodes.validationCompanyIdRequired),
        ),
      );
    }

    return _repository.getUsage(companyId: companyId);
  }
}
