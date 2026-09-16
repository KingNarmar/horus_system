import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_compensation_revision.dart';
import '../repositories/driver_compensation_repository.dart';
import 'driver_compensation_usecase_validation.dart';

final class GetDriverCompensationHistoryParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;

  const GetDriverCompensationHistoryParams({
    required this.currentCompanyContext,
    required this.driverId,
  });
}

final class GetDriverCompensationHistoryUseCase
    implements
        UseCase<
          List<DriverCompensationRevision>,
          GetDriverCompensationHistoryParams
        > {
  final DriverCompensationRepository _repository;

  const GetDriverCompensationHistoryUseCase(this._repository);

  @override
  Future<Result<List<DriverCompensationRevision>>> call(
    GetDriverCompensationHistoryParams params,
  ) {
    final accessFailure = DriverCompensationUseCaseValidation.validateView(
      params.currentCompanyContext,
    );
    if (accessFailure != null) {
      return Future.value(FailureResult(accessFailure));
    }

    final driverFailure = DriverCompensationUseCaseValidation.validateDriverId(
      params.driverId,
    );
    if (driverFailure != null) {
      return Future.value(FailureResult(driverFailure));
    }

    return _repository.getHistory(
      companyId: params.currentCompanyContext.companyId,
      driverId: params.driverId.trim(),
    );
  }
}
