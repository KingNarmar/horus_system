import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../policies/driver_settlements_permission_policy.dart';

class CanManageDriverSettlementsParams {
  final CurrentCompanyContext currentCompanyContext;

  const CanManageDriverSettlementsParams({required this.currentCompanyContext});
}

class CanManageDriverSettlementsUseCase
    implements UseCase<bool, CanManageDriverSettlementsParams> {
  const CanManageDriverSettlementsUseCase();

  @override
  Future<Result<bool>> call(CanManageDriverSettlementsParams params) {
    return Future.value(
      Success<bool>(
        DriverSettlementsPermissionPolicy.canManageDriverSettlements(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}
