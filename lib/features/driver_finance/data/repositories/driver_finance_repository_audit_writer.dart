import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../mappers/driver_financial_movement_mapper.dart';
import '../models/driver_financial_movement_model.dart';

const _driverFinancialMovementEntityKey = 'driver_financial_movement';
const _driverFinanceMovementAddedEvent = 'driver_finance_movement_added';

final class DriverFinanceRepositoryAuditWriter {
  final CreateAuditLogUseCase _createAuditLogUseCase;

  const DriverFinanceRepositoryAuditWriter(this._createAuditLogUseCase);

  Future<Failure?> writeAdded({
    required DriverFinancialMovementModel movement,
    required String actorRole,
  }) async {
    final result = await _createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: movement.companyId,
          actorRole: actorRole,
          module: AuditModule.drivers,
          entityType: AuditEntityType.driver,
          entityId: movement.driverId,
          entityDisplayName: _driverFinancialMovementEntityKey,
          action: AuditAction.created,
          description: _driverFinanceMovementAddedEvent,
          newValues: movement.toAuditValues(),
          metadata: {
            'audit_event': _driverFinanceMovementAddedEvent,
            'movement_id': movement.id,
            'movement_type': movement.type.value,
            'amount': movement.amount,
            'trip_id': movement.tripId,
          },
        ),
      ),
    );

    return result.failureOrNull;
  }
}
