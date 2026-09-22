import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../policies/drivers_permission_policy.dart';

class CanManageDriversParams {
  final CurrentCompanyContext currentCompanyContext;

  const CanManageDriversParams({required this.currentCompanyContext});
}

class CanManageDriversUseCase implements UseCase<bool, CanManageDriversParams> {
  const CanManageDriversUseCase();

  @override
  Future<Result<bool>> call(CanManageDriversParams params) {
    return Future.value(
      Success<bool>(
        DriversPermissionPolicy.canManageDrivers(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}
