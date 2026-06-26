import '../../../../core/utils/result.dart';
import '../entities/expense_type_option.dart';
import '../entities/trip_expense.dart';
import '../entities/trip_expense_write_data.dart';

abstract class TripExpensesRepository {
  Future<Result<List<TripExpense>>> getTripExpenses({
    required String companyId,
    required String tripId,
  });

  Future<Result<List<ExpenseTypeOption>>> getExpenseTypes({
    required String companyId,
  });

  Future<Result<TripExpense>> addTripExpense({
    required TripExpenseWriteData data,
    required String actorRole,
  });

  Future<Result<TripExpense>> updateTripExpense({
    required String id,
    required TripExpenseWriteData data,
    required String actorRole,
  });
}
