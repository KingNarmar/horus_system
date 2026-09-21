import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../policies/driver_finance_permission_policy.dart';

class CanManageDriverFinanceParams {
  final CurrentCompanyContext currentCompanyContext;

  const CanManageDriverFinanceParams({
    required this.currentCompanyContext,
  });
}

class CanManageDriverFinanceUseCase
    implements UseCase<bool, CanManageDriverFinanceParams> {
  const CanManageDriverFinanceUseCase();

  @override
  Future<Result<bool>> call(CanManageDriverFinanceParams params) {
    return Future.value(
      Success<bool>(
        DriverFinancePermissionPolicy.canManageDriverFinance(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}
