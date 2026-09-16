import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../mappers/driver_compensation_mapper.dart';
import '../models/driver_compensation_model.dart';

final class DriverCompensationAuditWriter {
  static const String revisionCreatedEvent =
      'driver_compensation_revision_created';
  static const String revisionEndedEvent =
      'driver_compensation_revision_ended';
  static const String contractAttachedEvent =
      'driver_compensation_contract_attached';

  final CreateAuditLogUseCase createAuditLogUseCase;

  const DriverCompensationAuditWriter(this.createAuditLogUseCase);

  Future<Failure?> write({
    required DriverCompensationModel model,
    required String actorRole,
    required AuditAction action,
    required String event,
    Map<String, Object?>? oldValues,
  }) async {
    final result = await createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: model.companyId,
          actorRole: actorRole,
          module: AuditModule.drivers,
          entityType: AuditEntityType.driverCompensationRevision,
          entityId: model.id,
          action: action,
          description: event,
          oldValues: oldValues,
          newValues: model.toAuditValues(),
          metadata: {
            'audit_event': event,
            'driver_id': model.driverId,
            'compensation_revision_id': model.id,
          },
        ),
      ),
    );
    return result.failureOrNull;
  }
}
