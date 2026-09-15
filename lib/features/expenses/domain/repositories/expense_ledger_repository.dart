import '../../../../core/utils/result.dart';
import '../entities/expense_ledger_entry.dart';
import '../entities/expense_ledger_write_data.dart';

abstract class ExpenseLedgerRepository {
  Future<Result<List<ExpenseLedgerEntry>>> getEntries({
    required String companyId,
    bool includeVoided = false,
  });

  Future<Result<ExpenseLedgerEntry>> createEntry(
    ExpenseLedgerWriteData data,
  );

  Future<Result<ExpenseLedgerEntry>> voidEntry({
    required String companyId,
    required String expenseId,
    String? reason,
  });
}
