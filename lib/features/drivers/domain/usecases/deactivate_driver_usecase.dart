import 'package:horus_system/core/errors/failure_codes.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver.dart';
import '../policies/drivers_permission_policy.dart';
import '../repositories/drivers_repository.dart';

class DeactivateDriverParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;

  const DeactivateDriverParams({
    required this.currentCompanyContext,
    required this.driverId,
  });
}

class DeactivateDriverUseCase
    implements UseCase<Driver, DeactivateDriverParams> {
  final DriversRepository _repository;

  const DeactivateDriverUseCase(this._repository);

  @override
  Future<Result<Driver>> call(DeactivateDriverParams params) {
    final context = params.currentCompanyContext;
    if (!DriversPermissionPolicy.canManageDrivers(context.role)) {
      return Future.value(
        const FailureResult<Driver>(
          PermissionFailure(
            code: FailureCodes.permissionDriversManagement,
            message: 'Drivers management is not allowed.',
          ),
        ),
      );
    }

    return _repository.deactivateDriver(
      companyId: context.companyId,
      driverId: params.driverId,
      actorRole: context.role.value,
    );
  }
}
