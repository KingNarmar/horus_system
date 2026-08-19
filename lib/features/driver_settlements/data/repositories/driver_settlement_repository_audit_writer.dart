import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../mappers/driver_settlement_mapper.dart';
import '../models/driver_settlement_model.dart';

const _entityDisplayName = 'driver_settlement';
const _createdEvent = 'driver_settlement_created';
const _finalizedEvent = 'driver_settlement_finalized';
const _voidedEvent = 'driver_settlement_voided';

final class DriverSettlementRepositoryAuditWriter {
  final CreateAuditLogUseCase _createAuditLogUseCase;

  const DriverSettlementRepositoryAuditWriter(this._createAuditLogUseCase);

  Future<Failure?> writeCreated({
    required DriverSettlementModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.created,
      event: _createdEvent,
    );
  }

  Future<Failure?> writeFinalized({
    required DriverSettlementModel oldModel,
    required DriverSettlementModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.statusChanged,
      event: _finalizedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> writeVoided({
    required DriverSettlementModel oldModel,
    required DriverSettlementModel model,
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
    required DriverSettlementModel model,
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
          module: AuditModule.drivers,
          entityType: AuditEntityType.driver,
          entityId: model.driverId,
          entityDisplayName: _entityDisplayName,
          action: action,
          description: event,
          oldValues: oldValues,
          newValues: model.toAuditValues(),
          metadata: {
            'audit_event': event,
            'settlement_id': model.id,
            'driver_id': model.driverId,
            'status': model.status.value,
            'period_start': model.periodStart.toIso8601String(),
            'period_end': model.periodEnd.toIso8601String(),
            'closing_driver_balance': model.closingDriverBalance,
            'net_salary_payable': model.netSalaryPayable,
          },
        ),
      ),
    );

    return result.failureOrNull;
  }
}
