import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_compensation_revision.dart';
import '../failures/driver_compensation_failure_codes.dart';
import '../policies/driver_compensation_period_policy.dart';
import '../repositories/driver_compensation_repository.dart';
import 'driver_compensation_usecase_validation.dart';

final class EndDriverCompensationRevisionParams {
  final CurrentCompanyContext currentCompanyContext;
  final DriverCompensationRevision revision;
  final BusinessDate effectiveTo;

  const EndDriverCompensationRevisionParams({
    required this.currentCompanyContext,
    required this.revision,
    required this.effectiveTo,
  });
}

final class EndDriverCompensationRevisionUseCase
    implements
        UseCase<
          DriverCompensationRevision,
          EndDriverCompensationRevisionParams
        > {
  final DriverCompensationRepository _repository;
  final DriverCompensationPeriodPolicy _periodPolicy;

  const EndDriverCompensationRevisionUseCase(
    this._repository, {
    DriverCompensationPeriodPolicy periodPolicy =
        const DriverCompensationPeriodPolicy(),
  }) : _periodPolicy = periodPolicy;

  @override
  Future<Result<DriverCompensationRevision>> call(
    EndDriverCompensationRevisionParams params,
  ) {
    final accessFailure = DriverCompensationUseCaseValidation.validateManage(
      params.currentCompanyContext,
    );
    if (accessFailure != null) {
      return Future.value(FailureResult(accessFailure));
    }

    final revision = params.revision;
    if (revision.companyId != params.currentCompanyContext.companyId) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: DriverCompensationFailureCodes.permissionManage,
          ),
        ),
      );
    }
    if (revision.effectiveTo != null) {
      return Future.value(
        const FailureResult(
          ConflictFailure(
            code:
                DriverCompensationFailureCodes.conflictRevisionAlreadyEnded,
          ),
        ),
      );
    }
    if (!_periodPolicy.isValidPeriod(
      effectiveFrom: revision.effectiveFrom,
      effectiveTo: params.effectiveTo,
    )) {
      return Future.value(
        const FailureResult(
          ValidationFailure(
            code:
                DriverCompensationFailureCodes.validationEffectivePeriodInvalid,
          ),
        ),
      );
    }

    return _repository.endRevision(
      companyId: params.currentCompanyContext.companyId,
      revisionId: revision.id,
      driverId: revision.driverId,
      actorRole: params.currentCompanyContext.role.value,
      effectiveTo: params.effectiveTo,
    );
  }
}
