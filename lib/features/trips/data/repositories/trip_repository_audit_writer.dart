import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/trip_status.dart';
import '../mappers/trip_mapper.dart';
import '../models/trip_model.dart';

const _tripCreatedEvent = 'trip_created';
const _tripUpdatedEvent = 'trip_updated';
const _tripStatusChangedEvent = 'trip_status_changed';

final class TripRepositoryAuditWriter {
  final CreateAuditLogUseCase _createAuditLogUseCase;

  const TripRepositoryAuditWriter(this._createAuditLogUseCase);

  Future<Failure?> writeCreated({
    required TripModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.created,
      description: _tripCreatedEvent,
    );
  }

  Future<Failure?> writeUpdated({
    required TripModel oldModel,
    required TripModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.updated,
      description: _tripUpdatedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> writeStatusChanged({
    required TripModel oldModel,
    required TripModel model,
    required TripStatus oldStatus,
    required TripStatus newStatus,
    required String actorRole,
    String? notes,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.statusChanged,
      description: _tripStatusChangedEvent,
      oldValues: oldModel.toAuditValues(),
      metadata: {
        'old_status': oldStatus.value,
        'new_status': newStatus.value,
        'notes': notes,
      },
    );
  }

  Future<Failure?> _write({
    required TripModel model,
    required String actorRole,
    required AuditAction action,
    required String description,
    Map<String, Object?>? oldValues,
    Map<String, Object?>? metadata,
  }) async {
    final result = await _createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: model.companyId,
          actorRole: actorRole,
          module: AuditModule.trips,
          entityType: AuditEntityType.trip,
          entityId: model.id,
          entityDisplayName: _displayName(model),
          action: action,
          description: description,
          oldValues: oldValues,
          newValues: model.toAuditValues(),
          metadata: metadata,
        ),
      ),
    );

    return result.failureOrNull;
  }

  String _displayName(TripModel model) {
    final loadingOrder = model.loadingOrderNumber?.trim();
    if (loadingOrder != null && loadingOrder.isNotEmpty) {
      return loadingOrder;
    }

    final waybill = model.waybillNumber?.trim();
    if (waybill != null && waybill.isNotEmpty) {
      return waybill;
    }

    final customer = model.customerName?.trim();
    final route = model.routeName?.trim();

    if (customer != null &&
        customer.isNotEmpty &&
        route != null &&
        route.isNotEmpty) {
      return '$customer - $route';
    }

    return model.id;
  }
}
