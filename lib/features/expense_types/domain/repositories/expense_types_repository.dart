import '../../../../core/utils/result.dart';
import '../entities/expense_type.dart';

abstract interface class ExpenseTypesRepository {
  Future<Result<List<ExpenseType>>> getExpenseTypes({
    required String companyId,
  });

  Future<Result<List<ExpenseType>>> getActiveExpenseTypes({
    required String companyId,
  });

  Future<Result<List<ExpenseType>>> getLedgerEligibleExpenseTypes({
    required String companyId,
  });
}
