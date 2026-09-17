import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_compensation_revision.dart';
import '../failures/driver_compensation_failure_codes.dart';
import '../policies/driver_compensation_permission_policy.dart';
import '../repositories/driver_compensation_repository.dart';
import 'driver_compensation_usecase_validation.dart';

final class GetDriverCompensationContractAccessParams {
  final CurrentCompanyContext currentCompanyContext;
  final DriverCompensationRevision revision;

  const GetDriverCompensationContractAccessParams({
    required this.currentCompanyContext,
    required this.revision,
  });
}

final class GetDriverCompensationContractAccessUseCase
    implements
        UseCase<
          BusinessDocumentAccess,
          GetDriverCompensationContractAccessParams
        > {
  final DriverCompensationRepository _repository;

  const GetDriverCompensationContractAccessUseCase(this._repository);

  @override
  Future<Result<BusinessDocumentAccess>> call(
    GetDriverCompensationContractAccessParams params,
  ) {
    final viewFailure = DriverCompensationUseCaseValidation.validateView(
      params.currentCompanyContext,
    );
    if (viewFailure != null) {
      return Future.value(FailureResult(viewFailure));
    }
    if (!DriverCompensationPermissionPolicy.canAccessContractDocument(
          params.currentCompanyContext.role,
        ) ||
        params.revision.companyId != params.currentCompanyContext.companyId) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: DriverCompensationFailureCodes.permissionManage,
          ),
        ),
      );
    }
    if (params.revision.contractDocumentReference == null) {
      return Future.value(
        const FailureResult(
          NotFoundFailure(
            code: DriverCompensationFailureCodes.notFoundDocument,
          ),
        ),
      );
    }

    return _repository.createContractDocumentAccess(
      companyId: params.currentCompanyContext.companyId,
      revision: params.revision,
    );
  }
}
