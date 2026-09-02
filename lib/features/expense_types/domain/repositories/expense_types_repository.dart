import '../../../../core/utils/result.dart';
import '../entities/expense_type.dart';
import '../entities/expense_type_write_data.dart';

abstract interface class ExpenseTypesRepository {
  Future<Result<List<ExpenseType>>> getExpenseTypes({
    required String companyId,
  });

  Future<Result<List<ExpenseType>>> getActiveExpenseTypes({
    required String companyId,
  });

  Future<Result<ExpenseType>> addExpenseType({
    required ExpenseTypeWriteData data,
    required String actorRole,
  });

  Future<Result<ExpenseType>> updateExpenseType({
    required String expenseTypeId,
    required ExpenseTypeWriteData data,
    required String actorRole,
  });

  Future<Result<ExpenseType>> deactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
    required String actorRole,
  });

  Future<Result<ExpenseType>> reactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
    required String actorRole,
  });
}
