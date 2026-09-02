import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/expense_type.dart';
import '../entities/expense_type_write_data.dart';
import '../policies/expense_types_permission_policy.dart';
import '../repositories/expense_types_repository.dart';

class UpdateExpenseTypeParams {
  final CurrentCompanyContext currentCompanyContext;
  final String expenseTypeId;
  final String name;

  const UpdateExpenseTypeParams({
    required this.currentCompanyContext,
    required this.expenseTypeId,
    required this.name,
  });
}

class UpdateExpenseTypeUseCase
    implements UseCase<ExpenseType, UpdateExpenseTypeParams> {
  final ExpenseTypesRepository _repository;

  const UpdateExpenseTypeUseCase(this._repository);

  @override
  Future<Result<ExpenseType>> call(UpdateExpenseTypeParams params) {
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

    final name = params.name.trim();
    if (name.isEmpty) {
      return Future.value(
        const FailureResult<ExpenseType>(
          ValidationFailure(code: FailureCodes.validationExpenseTypeNameRequired),
        ),
      );
    }

    return _repository.updateExpenseType(
      expenseTypeId: expenseTypeId,
      data: ExpenseTypeWriteData(companyId: context.companyId, name: name),
      actorRole: context.role.value,
    );
  }
}
