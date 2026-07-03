import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/expense_type_option.dart';
import '../../domain/entities/trip_expense.dart';
import '../../domain/entities/trip_expense_write_data.dart';
import '../../domain/repositories/trip_expenses_repository.dart';
import '../datasources/trip_expenses_remote_data_source.dart';
import '../mappers/trip_expense_mapper.dart';
import '../models/trip_expense_model.dart';

const _tripExpenseCreatedEvent = 'trip_expense_created';
const _tripExpenseUpdatedEvent = 'trip_expense_updated';

class TripExpensesRepositoryImpl implements TripExpensesRepository {
  final TripExpensesRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const TripExpensesRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  });

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
      final total = await remoteDataSource.recalculateTripTotalExpenses(
        companyId: data.companyId,
        tripId: data.tripId,
      );
      final auditFailure = await _writeAudit(
        companyId: data.companyId,
        tripId: data.tripId,
        actorRole: actorRole,
        action: AuditAction.created,
        description: _tripExpenseCreatedEvent,
        newValues: model.toAuditValues(),
        metadata: _metadata(model, total),
      );
      if (auditFailure != null) return FailureResult<TripExpense>(auditFailure);
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
      final model = await remoteDataSource.updateTripExpense(id: id, data: data);
      final total = await remoteDataSource.recalculateTripTotalExpenses(
        companyId: data.companyId,
        tripId: data.tripId,
      );
      final auditFailure = await _writeAudit(
        companyId: data.companyId,
        tripId: data.tripId,
        actorRole: actorRole,
        action: AuditAction.updated,
        description: _tripExpenseUpdatedEvent,
        oldValues: oldModel?.toAuditValues(),
        newValues: model.toAuditValues(),
        metadata: _metadata(model, total),
      );
      if (auditFailure != null) return FailureResult<TripExpense>(auditFailure);
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

  Future<Failure?> _writeAudit({
    required String companyId,
    required String tripId,
    required String actorRole,
    required AuditAction action,
    required String description,
    Map<String, Object?>? oldValues,
    Map<String, Object?>? newValues,
    Map<String, Object?>? metadata,
  }) async {
    final result = await createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: companyId,
          actorRole: actorRole,
          module: AuditModule.trips,
          entityType: AuditEntityType.trip,
          entityId: tripId,
          entityDisplayName: 'Trip expense',
          action: action,
          description: description,
          oldValues: oldValues,
          newValues: newValues,
          metadata: metadata,
        ),
      ),
    );
    return result.failureOrNull;
  }

  Map<String, Object?> _metadata(TripExpenseModel model, double total) {
    return {
      'expense_id': model.id,
      'expense_name': model.expenseName,
      'amount': model.amount,
      'paid_by': model.paidBy,
      'trip_total_expenses': total,
    };
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
