import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/trip_expense.dart';
import '../../domain/entities/trip_expense_write_data.dart';
import '../../domain/repositories/trip_expenses_repository.dart';
import '../datasources/trip_expenses_remote_data_source.dart';
import '../mappers/trip_expense_mapper.dart';
import 'trip_expense_repository_failure_mapper.dart';

class TripExpensesRepositoryImpl implements TripExpensesRepository {
  final TripExpensesRemoteDataSource remoteDataSource;
  final TripExpenseRepositoryFailureMapper _failureMapper;

  const TripExpensesRepositoryImpl({
    required this.remoteDataSource,
  }) : _failureMapper = const TripExpenseRepositoryFailureMapper();


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
  Future<Result<TripExpense>> addTripExpense({
    required TripExpenseWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addTripExpense(data: data);
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
      final model = await remoteDataSource.updateTripExpense(
        id: id,
        data: data,
      );
      return Success(model.toEntity());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
