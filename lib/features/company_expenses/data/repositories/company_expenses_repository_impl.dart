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
import '../../domain/entities/company_expense.dart';
import '../../domain/entities/company_expense_category.dart';
import '../../domain/entities/company_expense_void_data.dart';
import '../../domain/entities/company_expense_write_data.dart';
import '../../domain/repositories/company_expenses_repository.dart';
import '../datasources/company_expenses_remote_data_source.dart';
import '../mappers/company_expense_category_mapper.dart';
import '../mappers/company_expense_mapper.dart';
import '../models/company_expense_model.dart';

const _companyExpenseEntityKey = 'company_expense';
const _companyExpenseCreatedEvent = 'company_expense_created';
const _companyExpenseUpdatedEvent = 'company_expense_updated';
const _companyExpenseVoidedEvent = 'company_expense_voided';

class CompanyExpensesRepositoryImpl implements CompanyExpensesRepository {
  final CompanyExpensesRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const CompanyExpensesRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  });

  @override
  Future<Result<List<CompanyExpenseCategory>>> getCategories({
    required String companyId,
    bool includeInactive = false,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getCategories(
        companyId: companyId,
        includeInactive: includeInactive,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<CompanyExpense>>> getCompanyExpenses({
    required String companyId,
    bool includeVoided = false,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getCompanyExpenses(
        companyId: companyId,
        includeVoided: includeVoided,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<CompanyExpense>> addCompanyExpense({
    required CompanyExpenseWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addCompanyExpense(data: data);
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.created,
        event: _companyExpenseCreatedEvent,
      );
    });
  }

  @override
  Future<Result<CompanyExpense>> updateCompanyExpense({
    required String id,
    required CompanyExpenseWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getCompanyExpenseById(
        companyId: data.companyId,
        id: id,
      );
      final model = await remoteDataSource.updateCompanyExpense(
        id: id,
        data: data,
      );
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.updated,
        event: _companyExpenseUpdatedEvent,
        oldValues: oldModel.toAuditValues(),
      );
    });
  }

  @override
  Future<Result<CompanyExpense>> voidCompanyExpense({
    required CompanyExpenseVoidData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getCompanyExpenseById(
        companyId: data.companyId,
        id: data.expenseId,
      );
      final model = await remoteDataSource.voidCompanyExpense(data: data);
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.statusChanged,
        event: _companyExpenseVoidedEvent,
        oldValues: oldModel.toAuditValues(),
      );
    });
  }

  Future<Result<CompanyExpense>> _withAudit({
    required CompanyExpenseModel model,
    required String actorRole,
    required AuditAction action,
    required String event,
    Map<String, Object?>? oldValues,
  }) async {
    final auditFailure = await _writeAudit(
      companyId: model.companyId,
      actorRole: actorRole,
      entityId: model.id,
      action: action,
      event: event,
      oldValues: oldValues,
      newValues: model.toAuditValues(),
      metadata: {
        'audit_event': event,
        'amount': model.amount,
        'category_id': model.categoryId,
        'driver_id': model.driverId,
        'tractor_head_id': model.tractorHeadId,
        'trailer_id': model.trailerId,
        'trip_id': model.tripId,
      },
    );

    if (auditFailure != null) {
      return FailureResult(auditFailure);
    }

    return Success(model.toEntity());
  }

  Future<Failure?> _writeAudit({
    required String companyId,
    required String actorRole,
    required String entityId,
    required AuditAction action,
    required String event,
    Map<String, Object?>? oldValues,
    Map<String, Object?>? newValues,
    Map<String, Object?>? metadata,
  }) async {
    final result = await createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: companyId,
          actorRole: actorRole,
          module: AuditModule.expenses,
          entityType: AuditEntityType.expense,
          entityId: entityId,
          entityDisplayName: _companyExpenseEntityKey,
          action: action,
          description: event,
          oldValues: oldValues,
          newValues: newValues,
          metadata: metadata,
        ),
      ),
    );

    return result.failureOrNull;
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
