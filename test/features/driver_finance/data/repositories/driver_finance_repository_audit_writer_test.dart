import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/driver_finance/data/models/driver_financial_movement_model.dart';
import 'package:horus_system/features/driver_finance/data/repositories/driver_finance_repository_audit_writer.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';
import 'package:test/test.dart';

void main() {
  group('DriverFinanceRepositoryAuditWriter', () {
    test('preserves movement-added audit contract', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = DriverFinanceRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeAdded(
        movement: _movementModel(),
        actorRole: 'accountant',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.companyId, _companyId);
      expect(data.actorRole, 'accountant');
      expect(data.module, AuditModule.drivers);
      expect(data.entityType, AuditEntityType.driver);
      expect(data.entityId, _driverId);
      expect(data.entityDisplayName, 'driver_financial_movement');
      expect(data.action, AuditAction.created);
      expect(data.description, 'driver_finance_movement_added');
      expect(data.oldValues, isNull);
      expect(data.newValues?['id'], _movementId);
      expect(data.newValues?['company_id'], _companyId);
      expect(data.newValues?['driver_id'], _driverId);
      expect(data.newValues?['trip_id'], _tripId);
      expect(data.newValues?['movement_type'], 'driver_charge');
      expect(data.newValues?['amount'], 125.5);
      expect(data.metadata?['audit_event'], 'driver_finance_movement_added');
      expect(data.metadata?['movement_id'], _movementId);
      expect(data.metadata?['movement_type'], 'driver_charge');
      expect(data.metadata?['amount'], 125.5);
      expect(data.metadata?['trip_id'], _tripId);
    });

    test('propagates audit use-case failure', () async {
      final repository = _CapturingAuditLogRepository(
        result: const FailureResult<void>(
          ServerFailure(
            code: FailureCodes.serverError,
            message: 'audit failed',
          ),
        ),
      );
      final writer = DriverFinanceRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeAdded(
        movement: _movementModel(),
        actorRole: 'accountant',
      );

      expect(failure, isA<ServerFailure>());
      expect(failure?.code, FailureCodes.serverError);
      expect(repository.logs, hasLength(1));
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';
const _tripId = 'trip-1';
const _movementId = 'movement-1';

DriverFinancialMovementModel _movementModel() {
  return DriverFinancialMovementModel(
    id: _movementId,
    companyId: _companyId,
    driverId: _driverId,
    tripId: _tripId,
    type: DriverFinancialMovementType.driverCharge,
    amount: 125.5,
    movementDate: DateTime.utc(2026, 8, 23),
    notes: 'note',
    createdAt: DateTime.utc(2026, 8, 23, 9),
    updatedAt: DateTime.utc(2026, 8, 23, 10),
  );
}

class _CapturingAuditLogRepository implements AuditLogRepository {
  final List<AuditLogWriteData> logs = [];
  final Result<void> result;

  _CapturingAuditLogRepository({this.result = const Success<void>(null)});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    logs.add(data);
    return result;
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return const Success<List<AuditLog>>([]);
  }
}
