import '../../../../core/utils/result.dart';
import '../entities/trip_expense.dart';
import '../entities/trip_expense_write_data.dart';

abstract class TripExpensesRepository {
  Future<Result<List<TripExpense>>> getTripExpenses({
    required String companyId,
    required String tripId,
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
