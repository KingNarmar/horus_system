import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../mappers/customer_mapper.dart';
import '../models/customer_model.dart';

const _createdEvent = 'customer_created';
const _updatedEvent = 'customer_updated';
const _deactivatedEvent = 'customer_deactivated';
const _reactivatedEvent = 'customer_reactivated';

final class CustomerRepositoryAuditWriter {
  final CreateAuditLogUseCase _createAuditLogUseCase;

  const CustomerRepositoryAuditWriter(this._createAuditLogUseCase);

  Future<Failure?> writeCreated({
    required CustomerModel model,
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
    required CustomerModel oldModel,
    required CustomerModel model,
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

  Future<Failure?> writeDeactivated({
    required CustomerModel oldModel,
    required CustomerModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.deactivated,
      event: _deactivatedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> writeReactivated({
    required CustomerModel oldModel,
    required CustomerModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.reactivated,
      event: _reactivatedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> _write({
    required CustomerModel model,
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
          module: AuditModule.customers,
          entityType: AuditEntityType.customer,
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
