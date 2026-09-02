import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/expense_type.dart';
import '../policies/expense_types_permission_policy.dart';
import '../repositories/expense_types_repository.dart';

class ReactivateExpenseTypeParams {
  final CurrentCompanyContext currentCompanyContext;
  final String expenseTypeId;

  const ReactivateExpenseTypeParams({
    required this.currentCompanyContext,
    required this.expenseTypeId,
  });
}

class ReactivateExpenseTypeUseCase
    implements UseCase<ExpenseType, ReactivateExpenseTypeParams> {
  final ExpenseTypesRepository _repository;

  const ReactivateExpenseTypeUseCase(this._repository);

  @override
  Future<Result<ExpenseType>> call(ReactivateExpenseTypeParams params) {
    final context = params.currentCompanyContext;
    if (!ExpenseTypesPermissionPolicy.canManageExpenseTypes(context.role)) {
      return Future.value(
        const FailureResult<ExpenseType>(
          PermissionFailure(code: FailureCodes.permissionExpenseTypesManagement),
        ),
      );
    }

    final expenseTypeId = params.expenseTypeId.trim();
    if (expenseTypeId.isEmpty) {
      return Future.value(
        const FailureResult<ExpenseType>(
          ValidationFailure(code: FailureCodes.validationExpenseTypeIdRequired),
        ),
      );
    }

    return _repository.reactivateExpenseType(
      companyId: context.companyId,
      expenseTypeId: expenseTypeId,
      actorRole: context.role.value,
    );
  }
}
