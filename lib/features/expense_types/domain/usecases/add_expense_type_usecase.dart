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

class AddExpenseTypeParams {
  final CurrentCompanyContext currentCompanyContext;
  final String name;

  const AddExpenseTypeParams({
    required this.currentCompanyContext,
    required this.name,
  });
}

class AddExpenseTypeUseCase
    implements UseCase<ExpenseType, AddExpenseTypeParams> {
  final ExpenseTypesRepository _repository;

  const AddExpenseTypeUseCase(this._repository);

  @override
  Future<Result<ExpenseType>> call(AddExpenseTypeParams params) {
    final context = params.currentCompanyContext;
    if (!ExpenseTypesPermissionPolicy.canManageExpenseTypes(context.role)) {
      return Future.value(
        const FailureResult<ExpenseType>(
          PermissionFailure(code: FailureCodes.permissionExpenseTypesManagement),
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

    return _repository.addExpenseType(
      data: ExpenseTypeWriteData(companyId: context.companyId, name: name),
      actorRole: context.role.value,
    );
  }
}
