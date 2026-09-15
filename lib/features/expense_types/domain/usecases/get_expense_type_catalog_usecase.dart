import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/expense_type.dart';
import '../policies/expense_types_permission_policy.dart';
import '../repositories/expense_types_repository.dart';

final class GetExpenseTypeCatalogParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetExpenseTypeCatalogParams({required this.currentCompanyContext});
}

final class GetExpenseTypeCatalogUseCase
    implements UseCase<List<ExpenseType>, GetExpenseTypeCatalogParams> {
  final ExpenseTypesRepository _repository;

  const GetExpenseTypeCatalogUseCase(this._repository);

  @override
  Future<Result<List<ExpenseType>>> call(GetExpenseTypeCatalogParams params) {
    final context = params.currentCompanyContext;
    if (!ExpenseTypesPermissionPolicy.canViewExpenseTypes(context.role)) {
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

    return _repository.getExpenseTypes(companyId: companyId);
  }
}
