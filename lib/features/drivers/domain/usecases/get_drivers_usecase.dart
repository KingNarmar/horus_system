import 'package:horus_system/core/errors/failure_codes.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver.dart';
import '../policies/drivers_permission_policy.dart';
import '../repositories/drivers_repository.dart';

class GetDriversParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetDriversParams({required this.currentCompanyContext});
}

class GetDriversUseCase implements UseCase<List<Driver>, GetDriversParams> {
  final DriversRepository _repository;

  const GetDriversUseCase(this._repository);

  @override
  Future<Result<List<Driver>>> call(GetDriversParams params) {
    final context = params.currentCompanyContext;
    if (!DriversPermissionPolicy.canViewDrivers(context.role)) {
      return Future.value(
        const FailureResult<List<Driver>>(
          PermissionFailure(
            code: FailureCodes.permissionDriversView,
            message: 'You are not allowed to view drivers.',
          ),
        ),
      );
    }

    return _repository.getDrivers(companyId: context.companyId);
  }
}
