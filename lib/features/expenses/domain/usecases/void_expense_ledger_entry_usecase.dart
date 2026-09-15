import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/expense_ledger_entry.dart';
import '../failures/expense_ledger_failure_codes.dart';
import '../policies/expense_ledger_permission_policy.dart';
import '../repositories/expense_ledger_repository.dart';

final class VoidExpenseLedgerEntryParams {
  final CurrentCompanyContext currentCompanyContext;
  final ExpenseLedgerEntry entry;
  final String? reason;

  const VoidExpenseLedgerEntryParams({
    required this.currentCompanyContext,
    required this.entry,
    this.reason,
  });
}

final class VoidExpenseLedgerEntryUseCase
    implements UseCase<ExpenseLedgerEntry, VoidExpenseLedgerEntryParams> {
  final ExpenseLedgerRepository _repository;

  const VoidExpenseLedgerEntryUseCase(this._repository);

  @override
  Future<Result<ExpenseLedgerEntry>> call(VoidExpenseLedgerEntryParams params) {
    final context = params.currentCompanyContext;
    final entry = params.entry;

    if (entry.companyId != context.companyId ||
        !ExpenseLedgerPermissionPolicy.canManage(
          context.role,
          attribution: entry.attribution,
        )) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          PermissionFailure(code: ExpenseLedgerFailureCodes.permissionManage),
        ),
      );
    }

    if (entry.isVoided) {
      return Future.value(
        const FailureResult<ExpenseLedgerEntry>(
          ConflictFailure(
            code: ExpenseLedgerFailureCodes.conflictAlreadyVoided,
          ),
        ),
      );
    }

    return _repository.voidEntry(
      companyId: context.companyId,
      expenseId: entry.id,
      reason: params.reason?.trim(),
    );
  }
}
