import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../mappers/expense_type_mapper.dart';
import '../models/expense_type_model.dart';

const _expenseTypeCreatedEvent = 'expense_type_created';
const _expenseTypeUpdatedEvent = 'expense_type_updated';
const _expenseTypeDeactivatedEvent = 'expense_type_deactivated';
const _expenseTypeReactivatedEvent = 'expense_type_reactivated';

final class ExpenseTypeRepositoryAuditWriter {
  final CreateAuditLogUseCase _createAuditLogUseCase;

  const ExpenseTypeRepositoryAuditWriter(this._createAuditLogUseCase);

  Future<Failure?> writeCreated({
    required ExpenseTypeModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.created,
      event: _expenseTypeCreatedEvent,
    );
  }

  Future<Failure?> writeUpdated({
    required ExpenseTypeModel oldModel,
    required ExpenseTypeModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.updated,
      event: _expenseTypeUpdatedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> writeDeactivated({
    required ExpenseTypeModel oldModel,
    required ExpenseTypeModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.deactivated,
      event: _expenseTypeDeactivatedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> writeReactivated({
    required ExpenseTypeModel oldModel,
    required ExpenseTypeModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.reactivated,
      event: _expenseTypeReactivatedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> _write({
    required ExpenseTypeModel model,
    required String actorRole,
    required AuditAction action,
    required String event,
    Map<String, Object?>? oldValues,
  }) async {
    final result = await _createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: model.companyId,
          actorRole: actorRole,
          module: AuditModule.companySettings,
          entityType: AuditEntityType.expenseType,
          entityId: model.id,
          entityDisplayName: model.name,
          action: action,
          description: event,
          oldValues: oldValues,
          newValues: model.toAuditValues(),
        ),
      ),
    );
    return result.failureOrNull;
  }
}
