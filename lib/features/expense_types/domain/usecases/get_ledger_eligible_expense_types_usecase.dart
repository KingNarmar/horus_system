import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/expense_type.dart';
import '../policies/expense_types_permission_policy.dart';
import '../repositories/expense_types_repository.dart';

final class GetLedgerEligibleExpenseTypesParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetLedgerEligibleExpenseTypesParams({
    required this.currentCompanyContext,
  });
}

final class GetLedgerEligibleExpenseTypesUseCase
    implements UseCase<List<ExpenseType>, GetLedgerEligibleExpenseTypesParams> {
  final ExpenseTypesRepository _repository;

  const GetLedgerEligibleExpenseTypesUseCase(this._repository);

  @override
  Future<Result<List<ExpenseType>>> call(
    GetLedgerEligibleExpenseTypesParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!ExpenseTypesPermissionPolicy.canViewExpenseTypes(context.role)) {
      return Future.value(
        const FailureResult<List<ExpenseType>>(
          PermissionFailure(code: FailureCodes.permissionExpenseTypesView),
        ),
      );
    }

    return _repository.getLedgerEligibleExpenseTypes(
      companyId: context.companyId,
    );
  }
}
