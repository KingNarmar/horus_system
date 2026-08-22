import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/customers/data/models/customer_model.dart';
import 'package:horus_system/features/customers/data/repositories/customer_repository_audit_writer.dart';
import 'package:test/test.dart';

void main() {
  group('CustomerRepositoryAuditWriter', () {
    test('preserves created audit contract', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = CustomerRepositoryAuditWriter(
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
      expect(data.module, AuditModule.customers);
      expect(data.entityType, AuditEntityType.customer);
      expect(data.entityId, _customerId);
      expect(data.entityDisplayName, 'Customer One');
      expect(data.action, AuditAction.created);
      expect(data.description, 'customer_created');
      expect(data.oldValues, isNull);
      expect(data.newValues?['id'], _customerId);
      expect(data.newValues?['company_id'], _companyId);
      expect(data.newValues?['name'], 'Customer One');
      expect(data.newValues?['is_active'], isTrue);
    });

    test('preserves updated old and new snapshots', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = CustomerRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeUpdated(
        oldModel: _model(name: 'Old Name'),
        model: _model(name: 'New Name'),
        actorRole: 'admin',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.action, AuditAction.updated);
      expect(data.description, 'customer_updated');
      expect(data.oldValues?['name'], 'Old Name');
      expect(data.newValues?['name'], 'New Name');
    });

    test('preserves lifecycle audit events and actions', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = CustomerRepositoryAuditWriter(
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
      expect(repository.logs[0].description, 'customer_deactivated');
      expect(repository.logs[0].oldValues?['is_active'], isTrue);
      expect(repository.logs[0].newValues?['is_active'], isFalse);
      expect(repository.logs[1].action, AuditAction.reactivated);
      expect(repository.logs[1].description, 'customer_reactivated');
      expect(repository.logs[1].oldValues?['is_active'], isFalse);
      expect(repository.logs[1].newValues?['is_active'], isTrue);
    });
  });
}

const _companyId = 'company-1';
const _customerId = 'customer-1';

CustomerModel _model({String name = 'Customer One', bool isActive = true}) {
  return CustomerModel(
    id: _customerId,
    companyId: _companyId,
    name: name,
    contactPerson: 'Contact',
    phone: '123',
    email: 'customer@example.com',
    taxRegistrationNumber: 'TRN',
    address: 'Address',
    city: 'Dubai',
    country: 'AE',
    creditLimit: 1000,
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
