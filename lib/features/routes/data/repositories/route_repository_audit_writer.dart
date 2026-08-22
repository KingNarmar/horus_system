import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../mappers/route_mapper.dart';
import '../models/route_model.dart';

const _createdEvent = 'route_created';
const _updatedEvent = 'route_updated';
const _deactivatedEvent = 'route_deactivated';
const _reactivatedEvent = 'route_reactivated';

final class RouteRepositoryAuditWriter {
  final CreateAuditLogUseCase _createAuditLogUseCase;

  const RouteRepositoryAuditWriter(this._createAuditLogUseCase);

  Future<Failure?> writeCreated({
    required RouteModel model,
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
    required RouteModel oldModel,
    required RouteModel model,
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
    required RouteModel oldModel,
    required RouteModel model,
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
    required RouteModel oldModel,
    required RouteModel model,
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
    required RouteModel model,
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
          module: AuditModule.routes,
          entityType: AuditEntityType.route,
          entityId: model.id,
          entityDisplayName: _displayName(model),
          action: action,
          description: event,
          oldValues: oldValues,
          newValues: model.toAuditValues(),
        ),
      ),
    );

    return result.failureOrNull;
  }

  String _displayName(RouteModel model) {
    return '${model.loadingLocation} → ${model.unloadingLocation}';
  }
}
