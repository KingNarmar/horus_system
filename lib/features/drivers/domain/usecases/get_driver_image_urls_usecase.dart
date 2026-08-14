import 'package:horus_system/core/errors/failure_codes.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver.dart';
import '../entities/driver_image_urls.dart';
import '../policies/drivers_permission_policy.dart';
import '../repositories/drivers_repository.dart';

class GetDriverImageUrlsParams {
  final CurrentCompanyContext currentCompanyContext;
  final Driver driver;

  const GetDriverImageUrlsParams({
    required this.currentCompanyContext,
    required this.driver,
  });
}

class GetDriverImageUrlsUseCase
    implements UseCase<DriverImageUrls, GetDriverImageUrlsParams> {
  final DriversRepository _repository;

  const GetDriverImageUrlsUseCase(this._repository);

  @override
  Future<Result<DriverImageUrls>> call(GetDriverImageUrlsParams params) {
    final context = params.currentCompanyContext;
    if (!DriversPermissionPolicy.canViewDrivers(context.role)) {
      return Future.value(
        const FailureResult<DriverImageUrls>(
          PermissionFailure(
            code: FailureCodes.permissionDriversView,
            message: 'Drivers access is not allowed.',
          ),
        ),
      );
    }
    if (params.driver.companyId != context.companyId) {
      return Future.value(
        const FailureResult<DriverImageUrls>(
          PermissionFailure(
            code: FailureCodes.permissionDriversView,
            message: 'Driver does not belong to the selected company.',
          ),
        ),
      );
    }

    return _repository.getDriverImageUrls(driver: params.driver);
  }
}
