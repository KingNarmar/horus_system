import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/expense_type_option.dart';
import '../../domain/entities/trip_expense.dart';
import '../../domain/entities/trip_expense_write_data.dart';
import '../../domain/repositories/trip_expenses_repository.dart';
import '../datasources/trip_expenses_remote_data_source.dart';
import '../mappers/trip_expense_mapper.dart';

class TripExpensesRepositoryImpl implements TripExpensesRepository {
  final TripExpensesRemoteDataSource remoteDataSource;

  const TripExpensesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<TripExpense>>> getTripExpenses({
    required String companyId,
    required String tripId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getTripExpenses(
        companyId: companyId,
        tripId: tripId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<ExpenseTypeOption>>> getExpenseTypes({
    required String companyId,
  }) {
    return _guard(() async {
      final types = await remoteDataSource.getExpenseTypes(companyId: companyId);
      return Success(types);
    });
  }

  @override
  Future<Result<TripExpense>> addTripExpense({
    required TripExpenseWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addTripExpense(data: data);
      await remoteDataSource.recalculateTripTotalExpenses(
        companyId: data.companyId,
        tripId: data.tripId,
      );
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TripExpense>> updateTripExpense({
    required String id,
    required TripExpenseWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.updateTripExpense(id: id, data: data);
      await remoteDataSource.recalculateTripTotalExpenses(
        companyId: data.companyId,
        tripId: data.tripId,
      );
      return Success(model.toEntity());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(
          code: error.code ?? FailureCodes.serverError,
          message: error.message,
        ),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
