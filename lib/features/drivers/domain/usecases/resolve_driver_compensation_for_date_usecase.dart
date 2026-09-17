import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_compensation_revision.dart';
import '../policies/driver_compensation_period_policy.dart';
import '../repositories/driver_compensation_repository.dart';
import 'driver_compensation_usecase_validation.dart';

final class ResolveDriverCompensationForDateParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final BusinessDate targetDate;

  const ResolveDriverCompensationForDateParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.targetDate,
  });
}

final class ResolveDriverCompensationForDateUseCase
    implements
        UseCase<
          DriverCompensationRevision,
          ResolveDriverCompensationForDateParams
        > {
  final DriverCompensationRepository _repository;
  final DriverCompensationPeriodPolicy _periodPolicy;

  const ResolveDriverCompensationForDateUseCase(
    this._repository, {
    DriverCompensationPeriodPolicy periodPolicy =
        const DriverCompensationPeriodPolicy(),
  }) : _periodPolicy = periodPolicy;

  @override
  Future<Result<DriverCompensationRevision>> call(
    ResolveDriverCompensationForDateParams params,
  ) async {
    final accessFailure = DriverCompensationUseCaseValidation.validateView(
      params.currentCompanyContext,
    );
    if (accessFailure != null) return FailureResult(accessFailure);

    final driverFailure = DriverCompensationUseCaseValidation.validateDriverId(
      params.driverId,
    );
    if (driverFailure != null) return FailureResult(driverFailure);

    final historyResult = await _repository.getHistory(
      companyId: params.currentCompanyContext.companyId,
      driverId: params.driverId.trim(),
    );
    final historyFailure = historyResult.failureOrNull;
    if (historyFailure != null) return FailureResult(historyFailure);

    return _periodPolicy.resolveForDate(
      revisions: historyResult.dataOrNull ?? const [],
      targetDate: params.targetDate,
    );
  }
}
