import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/expense_type.dart';
import '../policies/expense_types_permission_policy.dart';
import '../repositories/expense_types_repository.dart';

class GetActiveExpenseTypesParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetActiveExpenseTypesParams({required this.currentCompanyContext});
}

class GetActiveExpenseTypesUseCase
    implements UseCase<List<ExpenseType>, GetActiveExpenseTypesParams> {
  final ExpenseTypesRepository _repository;

  const GetActiveExpenseTypesUseCase(this._repository);

  @override
  Future<Result<List<ExpenseType>>> call(GetActiveExpenseTypesParams params) {
    final context = params.currentCompanyContext;
    if (!ExpenseTypesPermissionPolicy.canViewActiveExpenseTypes(context.role)) {
      return Future.value(
        const FailureResult<List<ExpenseType>>(
          PermissionFailure(code: FailureCodes.permissionExpenseTypesView),
        ),
      );
    }

    final companyId = context.companyId.trim();
    if (companyId.isEmpty) {
      return Future.value(
        const FailureResult<List<ExpenseType>>(
          ValidationFailure(code: FailureCodes.validationCompanyIdRequired),
        ),
      );
    }

    return _repository.getActiveExpenseTypes(companyId: companyId);
  }
}
