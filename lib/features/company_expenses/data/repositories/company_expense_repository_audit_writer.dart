import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../mappers/company_expense_mapper.dart';
import '../models/company_expense_model.dart';

const _entityDisplayName = 'company_expense';
const _createdEvent = 'company_expense_created';
const _updatedEvent = 'company_expense_updated';
const _voidedEvent = 'company_expense_voided';

final class CompanyExpenseRepositoryAuditWriter {
  final CreateAuditLogUseCase _createAuditLogUseCase;

  const CompanyExpenseRepositoryAuditWriter(this._createAuditLogUseCase);

  Future<Failure?> writeCreated({
    required CompanyExpenseModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.created,
      event: _createdEvent,
    );
  }

  Future<Failure?> writeUpdated({
    required CompanyExpenseModel oldModel,
    required CompanyExpenseModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.updated,
      event: _updatedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> writeVoided({
    required CompanyExpenseModel oldModel,
    required CompanyExpenseModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.statusChanged,
      event: _voidedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> _write({
    required CompanyExpenseModel model,
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
          module: AuditModule.expenses,
          entityType: AuditEntityType.expense,
          entityId: model.id,
          entityDisplayName: _entityDisplayName,
          action: action,
          description: event,
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
        ),
      ),
    );

    return result.failureOrNull;
  }
}
