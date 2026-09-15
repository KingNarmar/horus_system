import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/expense_ledger_entry.dart';
import '../failures/expense_ledger_failure_codes.dart';
import '../policies/expense_ledger_permission_policy.dart';
import '../repositories/expense_ledger_repository.dart';

final class GetExpenseLedgerEntriesParams {
  final CurrentCompanyContext currentCompanyContext;
  final bool includeVoided;

  const GetExpenseLedgerEntriesParams({
    required this.currentCompanyContext,
    this.includeVoided = false,
  });
}

final class GetExpenseLedgerEntriesUseCase
    implements
        UseCase<List<ExpenseLedgerEntry>, GetExpenseLedgerEntriesParams> {
  final ExpenseLedgerRepository _repository;

  const GetExpenseLedgerEntriesUseCase(this._repository);

  @override
  Future<Result<List<ExpenseLedgerEntry>>> call(
    GetExpenseLedgerEntriesParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!ExpenseLedgerPermissionPolicy.canView(context.role)) {
      return Future.value(
        const FailureResult<List<ExpenseLedgerEntry>>(
          PermissionFailure(code: ExpenseLedgerFailureCodes.permissionView),
        ),
      );
    }

    return _repository.getEntries(
      companyId: context.companyId,
      includeVoided: params.includeVoided,
    );
  }
}
