import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver.dart';
import '../policies/drivers_permission_policy.dart';
import '../repositories/drivers_repository.dart';

class ReactivateDriverParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;

  const ReactivateDriverParams({
    required this.currentCompanyContext,
    required this.driverId,
  });
}

class ReactivateDriverUseCase implements UseCase<Driver, ReactivateDriverParams> {
  final DriversRepository _repository;

  const ReactivateDriverUseCase(this._repository);

  @override
  Future<Result<Driver>> call(ReactivateDriverParams params) {
    final context = params.currentCompanyContext;
    if (!DriversPermissionPolicy.canManageDrivers(context.role)) {
      return Future.value(
        const FailureResult<Driver>(
          PermissionFailure(message: 'Drivers management is not allowed.'),
        ),
      );
    }

    return _repository.reactivateDriver(
      companyId: context.companyId,
      driverId: params.driverId,
      actorRole: context.role.value,
    );
  }
}
