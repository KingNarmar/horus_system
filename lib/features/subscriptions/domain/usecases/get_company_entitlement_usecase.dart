import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/company_entitlement.dart';
import '../repositories/company_entitlements_repository.dart';

final class GetCompanyEntitlementParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetCompanyEntitlementParams({required this.currentCompanyContext});
}

/// Caller company identity comes from the selected, server-verified context.
final class GetCompanyEntitlementUseCase
    implements UseCase<CompanyEntitlement, GetCompanyEntitlementParams> {
  final CompanyEntitlementsRepository _repository;

  const GetCompanyEntitlementUseCase(this._repository);

  @override
  Future<Result<CompanyEntitlement>> call(GetCompanyEntitlementParams params) {
    final companyId = params.currentCompanyContext.companyId.trim();
    if (companyId.isEmpty) {
      return Future.value(
        const FailureResult<CompanyEntitlement>(
          ValidationFailure(code: FailureCodes.validationCompanyIdRequired),
        ),
      );
    }
    return _repository.getCurrent(companyId: companyId);
  }
}
