import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/expense_ledger_entry.dart';
import '../failures/expense_ledger_failure_codes.dart';
import '../policies/expense_ledger_permission_policy.dart';
import '../repositories/expense_ledger_repository.dart';

final class GetTripExpenseLedgerEntriesParams {
  final CurrentCompanyContext currentCompanyContext;
  final String tripId;
  final bool includeVoided;

  const GetTripExpenseLedgerEntriesParams({
    required this.currentCompanyContext,
    required this.tripId,
    this.includeVoided = false,
  });
}

final class GetTripExpenseLedgerEntriesUseCase
    implements
        UseCase<List<ExpenseLedgerEntry>, GetTripExpenseLedgerEntriesParams> {
  final ExpenseLedgerRepository _repository;

  const GetTripExpenseLedgerEntriesUseCase(this._repository);

  @override
  Future<Result<List<ExpenseLedgerEntry>>> call(
    GetTripExpenseLedgerEntriesParams params,
  ) {
    final context = params.currentCompanyContext;
    if (!ExpenseLedgerPermissionPolicy.canView(context.role)) {
      return Future.value(
        const FailureResult<List<ExpenseLedgerEntry>>(
          PermissionFailure(code: ExpenseLedgerFailureCodes.permissionView),
        ),
      );
    }

    final tripId = params.tripId.trim();
    if (tripId.isEmpty) {
      return Future.value(
        const FailureResult<List<ExpenseLedgerEntry>>(
          ValidationFailure(
            code: ExpenseLedgerFailureCodes.validationAttributionInvalid,
          ),
        ),
      );
    }

    return _repository.getEntriesForTrip(
      companyId: context.companyId,
      tripId: tripId,
      includeVoided: params.includeVoided,
    );
  }
}
