import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../policies/routes_permission_policy.dart';

class CanManageRoutesParams {
  final CurrentCompanyContext currentCompanyContext;

  const CanManageRoutesParams({required this.currentCompanyContext});
}

class CanManageRoutesUseCase implements UseCase<bool, CanManageRoutesParams> {
  const CanManageRoutesUseCase();

  @override
  Future<Result<bool>> call(CanManageRoutesParams params) {
    return Future.value(
      Success<bool>(
        RoutesPermissionPolicy.canManageRoutes(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}
