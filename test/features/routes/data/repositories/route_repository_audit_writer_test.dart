import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/routes/data/models/route_model.dart';
import 'package:horus_system/features/routes/data/repositories/route_repository_audit_writer.dart';
import 'package:test/test.dart';

void main() {
  group('RouteRepositoryAuditWriter', () {
    test('preserves created audit contract', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = RouteRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeCreated(
        model: _model(),
        actorRole: 'operations',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.companyId, _companyId);
      expect(data.actorRole, 'operations');
      expect(data.module, AuditModule.routes);
      expect(data.entityType, AuditEntityType.route);
      expect(data.entityId, _routeId);
      expect(data.entityDisplayName, 'Dubai → Abu Dhabi');
      expect(data.action, AuditAction.created);
      expect(data.description, 'route_created');
      expect(data.oldValues, isNull);
      expect(data.newValues?['id'], _routeId);
      expect(data.newValues?['company_id'], _companyId);
      expect(data.newValues?['loading_location'], 'Dubai');
      expect(data.newValues?['unloading_location'], 'Abu Dhabi');
      expect(data.newValues?['is_active'], isTrue);
    });

    test('preserves updated old and new snapshots', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = RouteRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeUpdated(
        oldModel: _model(loadingLocation: 'Old Loading'),
        model: _model(loadingLocation: 'New Loading'),
        actorRole: 'admin',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.action, AuditAction.updated);
      expect(data.description, 'route_updated');
      expect(data.entityDisplayName, 'New Loading → Abu Dhabi');
      expect(data.oldValues?['loading_location'], 'Old Loading');
      expect(data.newValues?['loading_location'], 'New Loading');
    });

    test('preserves lifecycle audit events and actions', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = RouteRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      await writer.writeDeactivated(
        oldModel: _model(isActive: true),
        model: _model(isActive: false),
        actorRole: 'owner',
      );
      await writer.writeReactivated(
        oldModel: _model(isActive: false),
        model: _model(isActive: true),
        actorRole: 'owner',
      );

      expect(repository.logs, hasLength(2));
      expect(repository.logs[0].action, AuditAction.deactivated);
      expect(repository.logs[0].description, 'route_deactivated');
      expect(repository.logs[0].oldValues?['is_active'], isTrue);
      expect(repository.logs[0].newValues?['is_active'], isFalse);
      expect(repository.logs[1].action, AuditAction.reactivated);
      expect(repository.logs[1].description, 'route_reactivated');
      expect(repository.logs[1].oldValues?['is_active'], isFalse);
      expect(repository.logs[1].newValues?['is_active'], isTrue);
    });
  });
}

const _companyId = 'company-1';
const _routeId = 'route-1';

RouteModel _model({
  String loadingLocation = 'Dubai',
  String unloadingLocation = 'Abu Dhabi',
  bool isActive = true,
}) {
  return RouteModel(
    id: _routeId,
    companyId: _companyId,
    loadingLocation: loadingLocation,
    unloadingLocation: unloadingLocation,
    governorateFrom: 'Dubai',
    governorateTo: 'Abu Dhabi',
    defaultFreightPrice: 1250,
    notes: 'Notes',
    isActive: isActive,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 2),
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
