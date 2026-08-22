import 'package:horus_system/core/data/constants/db_common_fields.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/fleet/data/constants/tractor_head_db_fields.dart';
import 'package:horus_system/features/fleet/data/constants/trailer_db_fields.dart';
import 'package:horus_system/features/fleet/data/models/tractor_head_model.dart';
import 'package:horus_system/features/fleet/data/models/trailer_model.dart';
import 'package:horus_system/features/fleet/data/repositories/fleet_repository_audit_writer.dart';
import 'package:test/test.dart';

void main() {
  group('FleetRepositoryAuditWriter', () {
    test('writes exact tractor-head create audit payload', () async {
      final auditRepository = _FakeAuditLogRepository();
      final writer = _writer(auditRepository);
      final model = _tractorModel();

      final failure = await writer.writeTractorHeadCreated(
        model: model,
        actorRole: 'operations',
      );

      expect(failure, isNull);
      final log = auditRepository.logs.single;
      expect(log.companyId, _companyId);
      expect(log.actorRole, 'operations');
      expect(log.module, AuditModule.fleet);
      expect(log.entityType, AuditEntityType.tractorHead);
      expect(log.entityId, _tractorId);
      expect(log.entityDisplayName, 'T-100');
      expect(log.action, AuditAction.created);
      expect(log.description, 'tractor_head_created');
      expect(log.oldValues, isNull);
      expect(log.newValues?[TractorHeadDbFields.plateNumber], 'T-100');
      expect(log.newValues?[DbCommonFields.isActive], isTrue);
    });

    test('writes exact tractor-head update and lifecycle events', () async {
      final auditRepository = _FakeAuditLogRepository();
      final writer = _writer(auditRepository);
      final oldModel = _tractorModel(plateNumber: 'T-OLD', isActive: true);
      final updated = _tractorModel(plateNumber: 'T-NEW', isActive: true);
      final deactivated = _tractorModel(plateNumber: 'T-NEW', isActive: false);
      final reactivated = _tractorModel(plateNumber: 'T-NEW', isActive: true);

      await writer.writeTractorHeadUpdated(
        oldModel: oldModel,
        model: updated,
        actorRole: 'admin',
      );
      await writer.writeTractorHeadDeactivated(
        oldModel: updated,
        model: deactivated,
        actorRole: 'owner',
      );
      await writer.writeTractorHeadReactivated(
        oldModel: deactivated,
        model: reactivated,
        actorRole: 'owner',
      );

      expect(auditRepository.logs.map((log) => log.description), [
        'tractor_head_updated',
        'tractor_head_deactivated',
        'tractor_head_reactivated',
      ]);
      expect(auditRepository.logs.map((log) => log.action), [
        AuditAction.updated,
        AuditAction.deactivated,
        AuditAction.reactivated,
      ]);
      expect(
        auditRepository.logs[0].oldValues?[TractorHeadDbFields.plateNumber],
        'T-OLD',
      );
      expect(
        auditRepository.logs[0].newValues?[TractorHeadDbFields.plateNumber],
        'T-NEW',
      );
      expect(
        auditRepository.logs[1].oldValues?[DbCommonFields.isActive],
        isTrue,
      );
      expect(
        auditRepository.logs[1].newValues?[DbCommonFields.isActive],
        isFalse,
      );
      expect(
        auditRepository.logs[2].oldValues?[DbCommonFields.isActive],
        isFalse,
      );
      expect(
        auditRepository.logs[2].newValues?[DbCommonFields.isActive],
        isTrue,
      );
    });

    test('writes exact trailer create audit payload', () async {
      final auditRepository = _FakeAuditLogRepository();
      final writer = _writer(auditRepository);
      final model = _trailerModel();

      final failure = await writer.writeTrailerCreated(
        model: model,
        actorRole: 'operations',
      );

      expect(failure, isNull);
      final log = auditRepository.logs.single;
      expect(log.companyId, _companyId);
      expect(log.actorRole, 'operations');
      expect(log.module, AuditModule.fleet);
      expect(log.entityType, AuditEntityType.trailer);
      expect(log.entityId, _trailerId);
      expect(log.entityDisplayName, 'TR-100');
      expect(log.action, AuditAction.created);
      expect(log.description, 'trailer_created');
      expect(log.oldValues, isNull);
      expect(log.newValues?[TrailerDbFields.plateNumber], 'TR-100');
      expect(log.newValues?[DbCommonFields.isActive], isTrue);
    });

    test('writes exact trailer update and lifecycle events', () async {
      final auditRepository = _FakeAuditLogRepository();
      final writer = _writer(auditRepository);
      final oldModel = _trailerModel(plateNumber: 'TR-OLD', isActive: true);
      final updated = _trailerModel(plateNumber: 'TR-NEW', isActive: true);
      final deactivated = _trailerModel(plateNumber: 'TR-NEW', isActive: false);
      final reactivated = _trailerModel(plateNumber: 'TR-NEW', isActive: true);

      await writer.writeTrailerUpdated(
        oldModel: oldModel,
        model: updated,
        actorRole: 'admin',
      );
      await writer.writeTrailerDeactivated(
        oldModel: updated,
        model: deactivated,
        actorRole: 'owner',
      );
      await writer.writeTrailerReactivated(
        oldModel: deactivated,
        model: reactivated,
        actorRole: 'owner',
      );

      expect(auditRepository.logs.map((log) => log.description), [
        'trailer_updated',
        'trailer_deactivated',
        'trailer_reactivated',
      ]);
      expect(auditRepository.logs.map((log) => log.action), [
        AuditAction.updated,
        AuditAction.deactivated,
        AuditAction.reactivated,
      ]);
      expect(
        auditRepository.logs[0].oldValues?[TrailerDbFields.plateNumber],
        'TR-OLD',
      );
      expect(
        auditRepository.logs[0].newValues?[TrailerDbFields.plateNumber],
        'TR-NEW',
      );
      expect(
        auditRepository.logs[1].oldValues?[DbCommonFields.isActive],
        isTrue,
      );
      expect(
        auditRepository.logs[1].newValues?[DbCommonFields.isActive],
        isFalse,
      );
      expect(
        auditRepository.logs[2].oldValues?[DbCommonFields.isActive],
        isFalse,
      );
      expect(
        auditRepository.logs[2].newValues?[DbCommonFields.isActive],
        isTrue,
      );
    });

    test('returns audit failure unchanged', () async {
      const failure = ValidationFailure(code: FailureCodes.serverError);
      final writer = _writer(_FakeAuditLogRepository(failure: failure));

      final result = await writer.writeTractorHeadCreated(
        model: _tractorModel(),
        actorRole: 'owner',
      );

      expect(result, same(failure));
    });
  });
}

const _companyId = 'company-1';
const _tractorId = 'tractor-1';
const _trailerId = 'trailer-1';

FleetRepositoryAuditWriter _writer(_FakeAuditLogRepository repository) {
  return FleetRepositoryAuditWriter(CreateAuditLogUseCase(repository));
}

TractorHeadModel _tractorModel({
  String plateNumber = 'T-100',
  bool isActive = true,
}) {
  return TractorHeadModel(
    id: _tractorId,
    companyId: _companyId,
    plateNumber: plateNumber,
    status: 'available',
    isActive: isActive,
    licenseExpiryDate: DateTime.utc(2027, 1, 1),
    expectedFuelConsumption: 30.5,
    notes: 'Tractor notes',
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 2),
  );
}

TrailerModel _trailerModel({
  String plateNumber = 'TR-100',
  bool isActive = true,
}) {
  return TrailerModel(
    id: _trailerId,
    companyId: _companyId,
    plateNumber: plateNumber,
    status: 'available',
    isActive: isActive,
    licenseExpiryDate: DateTime.utc(2027, 1, 1),
    technicalNotes: 'Trailer notes',
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 2),
  );
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final Failure? failure;
  final List<AuditLogWriteData> logs = [];

  _FakeAuditLogRepository({this.failure});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    if (failure != null) return FailureResult<void>(failure!);
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
