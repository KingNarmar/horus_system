import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../mappers/fleet_audit_mapper.dart';
import '../models/tractor_head_model.dart';
import '../models/trailer_model.dart';

const _tractorHeadCreatedEvent = 'tractor_head_created';
const _tractorHeadUpdatedEvent = 'tractor_head_updated';
const _tractorHeadDeactivatedEvent = 'tractor_head_deactivated';
const _tractorHeadReactivatedEvent = 'tractor_head_reactivated';
const _trailerCreatedEvent = 'trailer_created';
const _trailerUpdatedEvent = 'trailer_updated';
const _trailerDeactivatedEvent = 'trailer_deactivated';
const _trailerReactivatedEvent = 'trailer_reactivated';

final class FleetRepositoryAuditWriter {
  final CreateAuditLogUseCase _createAuditLogUseCase;

  const FleetRepositoryAuditWriter(this._createAuditLogUseCase);

  Future<Failure?> writeTractorHeadCreated({
    required TractorHeadModel model,
    required String actorRole,
  }) {
    return _write(
      companyId: model.companyId,
      actorRole: actorRole,
      entityType: AuditEntityType.tractorHead,
      entityId: model.id,
      entityDisplayName: model.plateNumber,
      action: AuditAction.created,
      event: _tractorHeadCreatedEvent,
      newValues: model.toAuditValues(),
    );
  }

  Future<Failure?> writeTractorHeadUpdated({
    required TractorHeadModel oldModel,
    required TractorHeadModel model,
    required String actorRole,
  }) {
    return _write(
      companyId: model.companyId,
      actorRole: actorRole,
      entityType: AuditEntityType.tractorHead,
      entityId: model.id,
      entityDisplayName: model.plateNumber,
      action: AuditAction.updated,
      event: _tractorHeadUpdatedEvent,
      oldValues: oldModel.toAuditValues(),
      newValues: model.toAuditValues(),
    );
  }

  Future<Failure?> writeTractorHeadDeactivated({
    required TractorHeadModel oldModel,
    required TractorHeadModel model,
    required String actorRole,
  }) {
    return _write(
      companyId: model.companyId,
      actorRole: actorRole,
      entityType: AuditEntityType.tractorHead,
      entityId: model.id,
      entityDisplayName: model.plateNumber,
      action: AuditAction.deactivated,
      event: _tractorHeadDeactivatedEvent,
      oldValues: oldModel.toAuditValues(),
      newValues: model.toAuditValues(),
    );
  }

  Future<Failure?> writeTractorHeadReactivated({
    required TractorHeadModel oldModel,
    required TractorHeadModel model,
    required String actorRole,
  }) {
    return _write(
      companyId: model.companyId,
      actorRole: actorRole,
      entityType: AuditEntityType.tractorHead,
      entityId: model.id,
      entityDisplayName: model.plateNumber,
      action: AuditAction.reactivated,
      event: _tractorHeadReactivatedEvent,
      oldValues: oldModel.toAuditValues(),
      newValues: model.toAuditValues(),
    );
  }

  Future<Failure?> writeTrailerCreated({
    required TrailerModel model,
    required String actorRole,
  }) {
    return _write(
      companyId: model.companyId,
      actorRole: actorRole,
      entityType: AuditEntityType.trailer,
      entityId: model.id,
      entityDisplayName: model.plateNumber,
      action: AuditAction.created,
      event: _trailerCreatedEvent,
      newValues: model.toAuditValues(),
    );
  }

  Future<Failure?> writeTrailerUpdated({
    required TrailerModel oldModel,
    required TrailerModel model,
    required String actorRole,
  }) {
    return _write(
      companyId: model.companyId,
      actorRole: actorRole,
      entityType: AuditEntityType.trailer,
      entityId: model.id,
      entityDisplayName: model.plateNumber,
      action: AuditAction.updated,
      event: _trailerUpdatedEvent,
      oldValues: oldModel.toAuditValues(),
      newValues: model.toAuditValues(),
    );
  }

  Future<Failure?> writeTrailerDeactivated({
    required TrailerModel oldModel,
    required TrailerModel model,
    required String actorRole,
  }) {
    return _write(
      companyId: model.companyId,
      actorRole: actorRole,
      entityType: AuditEntityType.trailer,
      entityId: model.id,
      entityDisplayName: model.plateNumber,
      action: AuditAction.deactivated,
      event: _trailerDeactivatedEvent,
      oldValues: oldModel.toAuditValues(),
      newValues: model.toAuditValues(),
    );
  }

  Future<Failure?> writeTrailerReactivated({
    required TrailerModel oldModel,
    required TrailerModel model,
    required String actorRole,
  }) {
    return _write(
      companyId: model.companyId,
      actorRole: actorRole,
      entityType: AuditEntityType.trailer,
      entityId: model.id,
      entityDisplayName: model.plateNumber,
      action: AuditAction.reactivated,
      event: _trailerReactivatedEvent,
      oldValues: oldModel.toAuditValues(),
      newValues: model.toAuditValues(),
    );
  }

  Future<Failure?> _write({
    required String companyId,
    required String actorRole,
    required AuditEntityType entityType,
    required String entityId,
    required String entityDisplayName,
    required AuditAction action,
    required String event,
    Map<String, Object?>? oldValues,
    required Map<String, Object?> newValues,
  }) async {
    final result = await _createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: companyId,
          actorRole: actorRole,
          module: AuditModule.fleet,
          entityType: entityType,
          entityId: entityId,
          entityDisplayName: entityDisplayName,
          action: action,
          description: event,
          oldValues: oldValues,
          newValues: newValues,
        ),
      ),
    );

    return result.failureOrNull;
  }
}
