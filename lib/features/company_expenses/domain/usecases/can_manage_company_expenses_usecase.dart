import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../policies/company_expenses_permission_policy.dart';

class CanManageCompanyExpensesParams {
  final CurrentCompanyContext currentCompanyContext;

  const CanManageCompanyExpensesParams({
    required this.currentCompanyContext,
  });
}

class CanManageCompanyExpensesUseCase
    implements UseCase<bool, CanManageCompanyExpensesParams> {
  const CanManageCompanyExpensesUseCase();

  @override
  Future<Result<bool>> call(CanManageCompanyExpensesParams params) {
    return Future.value(
      Success<bool>(
        CompanyExpensesPermissionPolicy.canManageCompanyExpenses(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}
