import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/expense_type_option.dart';
import '../../domain/entities/trip_expense.dart';
import '../../domain/entities/trip_expense_write_data.dart';
import '../../domain/repositories/trip_expenses_repository.dart';
import '../datasources/trip_expenses_remote_data_source.dart';
import '../mappers/trip_expense_mapper.dart';
import '../models/trip_expense_model.dart';
import 'trip_expense_repository_audit_writer.dart';
import 'trip_expense_repository_failure_mapper.dart';

class TripExpensesRepositoryImpl implements TripExpensesRepository {
  final TripExpensesRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final TripExpenseRepositoryFailureMapper _failureMapper;

  const TripExpensesRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  }) : _failureMapper = const TripExpenseRepositoryFailureMapper();

  TripExpenseRepositoryAuditWriter get _auditWriter {
    return TripExpenseRepositoryAuditWriter(createAuditLogUseCase);
  }

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
      final types = await remoteDataSource.getExpenseTypes(
        companyId: companyId,
      );
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
      final total = await remoteDataSource.getTripTotalExpenses(
        companyId: data.companyId,
        tripId: data.tripId,
      );
      final auditFailure = await _auditWriter.writeCreated(
        companyId: data.companyId,
        tripId: data.tripId,
        model: model,
        tripTotalExpenses: total,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<TripExpense>(auditFailure);
      }
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
      final oldModel = await _findExpense(
        companyId: data.companyId,
        tripId: data.tripId,
        id: id,
      );
      final model = await remoteDataSource.updateTripExpense(
        id: id,
        data: data,
      );
      final total = await remoteDataSource.getTripTotalExpenses(
        companyId: data.companyId,
        tripId: data.tripId,
      );
      final auditFailure = await _auditWriter.writeUpdated(
        companyId: data.companyId,
        tripId: data.tripId,
        oldModel: oldModel,
        model: model,
        tripTotalExpenses: total,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<TripExpense>(auditFailure);
      }
      return Success(model.toEntity());
    });
  }

  Future<TripExpenseModel?> _findExpense({
    required String companyId,
    required String tripId,
    required String id,
  }) async {
    final models = await remoteDataSource.getTripExpenses(
      companyId: companyId,
      tripId: tripId,
    );
    for (final model in models) {
      if (model.id == id) return model;
    }
    return null;
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
