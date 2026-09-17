import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_compensation_revision.dart';
import '../failures/driver_compensation_failure_codes.dart';
import '../policies/driver_compensation_permission_policy.dart';
import '../repositories/driver_compensation_repository.dart';
import 'driver_compensation_usecase_validation.dart';

final class AttachDriverCompensationContractParams {
  final CurrentCompanyContext currentCompanyContext;
  final DriverCompensationRevision revision;
  final BusinessDocumentFile document;

  const AttachDriverCompensationContractParams({
    required this.currentCompanyContext,
    required this.revision,
    required this.document,
  });
}

final class AttachDriverCompensationContractUseCase
    implements
        UseCase<
          DriverCompensationRevision,
          AttachDriverCompensationContractParams
        > {
  final DriverCompensationRepository _repository;

  const AttachDriverCompensationContractUseCase(this._repository);

  @override
  Future<Result<DriverCompensationRevision>> call(
    AttachDriverCompensationContractParams params,
  ) {
    final accessFailure = DriverCompensationUseCaseValidation.validateManage(
      params.currentCompanyContext,
    );
    if (accessFailure != null) {
      return Future.value(FailureResult(accessFailure));
    }
    if (!DriverCompensationPermissionPolicy.canAccessContractDocument(
      params.currentCompanyContext.role,
    )) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: DriverCompensationFailureCodes.permissionManage,
          ),
        ),
      );
    }
    if (params.revision.companyId != params.currentCompanyContext.companyId) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: DriverCompensationFailureCodes.permissionManage,
          ),
        ),
      );
    }
    if (params.revision.contractDocumentReference != null) {
      return Future.value(
        const FailureResult(
          ConflictFailure(
            code:
                DriverCompensationFailureCodes.conflictDocumentAlreadyAttached,
          ),
        ),
      );
    }

    return _repository.attachContractDocument(
      revision: params.revision,
      actorRole: params.currentCompanyContext.role.value,
      document: params.document,
    );
  }
}
