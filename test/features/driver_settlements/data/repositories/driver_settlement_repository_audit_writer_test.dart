import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/driver_settlements/data/models/driver_settlement_model.dart';
import 'package:horus_system/features/driver_settlements/data/repositories/driver_settlement_repository_audit_writer.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:test/test.dart';

void main() {
  group('DriverSettlementRepositoryAuditWriter', () {
    test('preserves created audit contract', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = DriverSettlementRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeCreated(
        model: _settlementModel(),
        actorRole: 'accountant',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.companyId, _companyId);
      expect(data.actorRole, 'accountant');
      expect(data.module, AuditModule.drivers);
      expect(data.entityType, AuditEntityType.driver);
      expect(data.entityId, _driverId);
      expect(data.entityDisplayName, 'driver_settlement');
      expect(data.action, AuditAction.created);
      expect(data.description, 'driver_settlement_created');
      expect(data.oldValues, isNull);
      expect(data.newValues?['status'], 'draft');
      expect(data.metadata?['audit_event'], 'driver_settlement_created');
      expect(data.metadata?['settlement_id'], _settlementId);
      expect(data.metadata?['driver_id'], _driverId);
      expect(data.metadata?['status'], 'draft');
      expect(data.metadata?['period_start'], '2026-07-01T00:00:00.000');
      expect(data.metadata?['period_end'], '2026-07-31T00:00:00.000');
      expect(data.metadata?['closing_driver_balance'], 125);
      expect(data.metadata?['net_salary_payable'], 850);
    });

    test('preserves finalized old/new audit snapshots', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = DriverSettlementRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeFinalized(
        oldModel: _settlementModel(),
        model: _settlementModel(status: DriverSettlementStatus.finalized),
        actorRole: 'accountant',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.action, AuditAction.statusChanged);
      expect(data.description, 'driver_settlement_finalized');
      expect(data.oldValues?['status'], 'draft');
      expect(data.newValues?['status'], 'finalized');
      expect(data.metadata?['audit_event'], 'driver_settlement_finalized');
      expect(data.metadata?['status'], 'finalized');
    });

    test('preserves voided old/new audit snapshots', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = DriverSettlementRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeVoided(
        oldModel: _settlementModel(),
        model: _settlementModel(status: DriverSettlementStatus.voided),
        actorRole: 'accountant',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.action, AuditAction.statusChanged);
      expect(data.description, 'driver_settlement_voided');
      expect(data.oldValues?['status'], 'draft');
      expect(data.newValues?['status'], 'voided');
      expect(data.metadata?['audit_event'], 'driver_settlement_voided');
      expect(data.metadata?['status'], 'voided');
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';
const _settlementId = 'settlement-1';

DriverSettlementModel _settlementModel({
  DriverSettlementStatus status = DriverSettlementStatus.draft,
}) {
  return DriverSettlementModel(
    id: _settlementId,
    companyId: _companyId,
    driverId: _driverId,
    periodStart: DateTime(2026, 7),
    periodEnd: DateTime(2026, 7, 31),
    openingDriverBalance: 0,
    advancesTotal: 200,
    driverPaidTripExpensesTotal: 50,
    returnedCashTotal: 0,
    deductionsTotal: 25,
    settlementDeductionsTotal: 0,
    grossSalary: 1000,
    salaryDeductionsTotal: 100,
    balanceDeductionApplied: 50,
    netSalaryPayable: 850,
    closingDriverBalance: 125,
    status: status,
  );
}

class _CapturingAuditLogRepository implements AuditLogRepository {
  final List<AuditLogWriteData> logs = [];

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    logs.add(data);
    return const Success<void>(null);
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
