import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../policies/expense_ledger_permission_policy.dart';

class CanManageTripAttributedExpenseParams {
  final CurrentCompanyContext currentCompanyContext;

  const CanManageTripAttributedExpenseParams({
    required this.currentCompanyContext,
  });
}

class CanManageTripAttributedExpenseUseCase
    implements UseCase<bool, CanManageTripAttributedExpenseParams> {
  const CanManageTripAttributedExpenseUseCase();

  @override
  Future<Result<bool>> call(CanManageTripAttributedExpenseParams params) {
    return Future.value(
      Success<bool>(
        ExpenseLedgerPermissionPolicy.canManageTripAttributed(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}
