import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_compensation_revision.dart';
import '../failures/driver_compensation_failure_codes.dart';
import '../policies/driver_compensation_period_policy.dart';
import '../repositories/driver_compensation_repository.dart';
import 'driver_compensation_usecase_validation.dart';

final class ResolveDriverCompensationForPeriodParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final BusinessDate periodStart;
  final BusinessDate periodEnd;

  const ResolveDriverCompensationForPeriodParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.periodStart,
    required this.periodEnd,
  });
}

final class ResolveDriverCompensationForPeriodUseCase
    implements
        UseCase<
          DriverCompensationRevision,
          ResolveDriverCompensationForPeriodParams
        > {
  final DriverCompensationRepository _repository;
  final DriverCompensationPeriodPolicy _periodPolicy;

  const ResolveDriverCompensationForPeriodUseCase(
    this._repository, {
    DriverCompensationPeriodPolicy periodPolicy =
        const DriverCompensationPeriodPolicy(),
  }) : _periodPolicy = periodPolicy;

  @override
  Future<Result<DriverCompensationRevision>> call(
    ResolveDriverCompensationForPeriodParams params,
  ) async {
    final accessFailure = DriverCompensationUseCaseValidation.validateView(
      params.currentCompanyContext,
    );
    if (accessFailure != null) return FailureResult(accessFailure);

    final driverFailure = DriverCompensationUseCaseValidation.validateDriverId(
      params.driverId,
    );
    if (driverFailure != null) return FailureResult(driverFailure);

    if (params.periodEnd.isBefore(params.periodStart)) {
      return const FailureResult<DriverCompensationRevision>(
        ValidationFailure(
          code: DriverCompensationFailureCodes.validationEffectivePeriodInvalid,
        ),
      );
    }

    final historyResult = await _repository.getHistory(
      companyId: params.currentCompanyContext.companyId,
      driverId: params.driverId.trim(),
    );
    if (historyResult is FailureResult<List<DriverCompensationRevision>>) {
      return FailureResult(historyResult.failure);
    }

    return _periodPolicy.resolveForPeriod(
      revisions: historyResult.dataOrNull ?? const [],
      periodStart: params.periodStart,
      periodEnd: params.periodEnd,
    );
  }
}
