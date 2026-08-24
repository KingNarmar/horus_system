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
import 'package:horus_system/features/payment_methods/data/models/payment_method_model.dart';
import 'package:horus_system/features/payment_methods/data/repositories/payment_method_repository_audit_writer.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentMethodRepositoryAuditWriter', () {
    test('preserves created audit contract', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = PaymentMethodRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeCreated(
        model: _model(name: 'Cash', isActive: true),
        actorRole: 'accountant',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      _expectCommonAudit(data, actorRole: 'accountant', name: 'Cash');
      expect(data.action, AuditAction.created);
      expect(data.description, 'payment_method_created');
      expect(data.oldValues, isNull);
      expect(data.newValues?['name'], 'Cash');
      expect(data.newValues?['is_active'], isTrue);
    });

    test('preserves updated old/new audit contract', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = PaymentMethodRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeUpdated(
        oldModel: _model(name: 'Cash', isActive: true),
        model: _model(name: 'Card', isActive: true),
        actorRole: 'admin',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      _expectCommonAudit(data, actorRole: 'admin', name: 'Card');
      expect(data.action, AuditAction.updated);
      expect(data.description, 'payment_method_updated');
      expect(data.oldValues?['name'], 'Cash');
      expect(data.newValues?['name'], 'Card');
    });

    test('preserves deactivate and reactivate semantic audit contracts', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = PaymentMethodRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      await writer.writeDeactivated(
        oldModel: _model(name: 'Cash', isActive: true),
        model: _model(name: 'Cash', isActive: false),
        actorRole: 'owner',
      );
      await writer.writeReactivated(
        oldModel: _model(name: 'Cash', isActive: false),
        model: _model(name: 'Cash', isActive: true),
        actorRole: 'owner',
      );

      expect(repository.logs, hasLength(2));
      final deactivated = repository.logs[0];
      expect(deactivated.action, AuditAction.deactivated);
      expect(deactivated.description, 'payment_method_deactivated');
      expect(deactivated.oldValues?['is_active'], isTrue);
      expect(deactivated.newValues?['is_active'], isFalse);

      final reactivated = repository.logs[1];
      expect(reactivated.action, AuditAction.reactivated);
      expect(reactivated.description, 'payment_method_reactivated');
      expect(reactivated.oldValues?['is_active'], isFalse);
      expect(reactivated.newValues?['is_active'], isTrue);
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
      final writer = PaymentMethodRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeCreated(
        model: _model(name: 'Cash', isActive: true),
        actorRole: 'accountant',
      );

      expect(failure, isA<ServerFailure>());
      expect(failure?.code, FailureCodes.serverError);
      expect(repository.logs, hasLength(1));
    });
  });
}

void _expectCommonAudit(
  AuditLogWriteData data, {
  required String actorRole,
  required String name,
}) {
  expect(data.companyId, _companyId);
  expect(data.actorRole, actorRole);
  expect(data.module, AuditModule.companySettings);
  expect(data.entityType, AuditEntityType.paymentMethod);
  expect(data.entityId, _paymentMethodId);
  expect(data.entityDisplayName, name);
}

const _companyId = 'company-1';
const _paymentMethodId = 'method-1';

PaymentMethodModel _model({required String name, required bool isActive}) {
  return PaymentMethodModel(
    id: _paymentMethodId,
    companyId: _companyId,
    name: name,
    code: 'other',
    isActive: isActive,
    createdBy: 'user-1',
    updatedBy: 'user-2',
    createdAt: DateTime.utc(2026, 8, 10, 9),
    updatedAt: DateTime.utc(2026, 8, 10, 10),
  );
}

final class _CapturingAuditLogRepository implements AuditLogRepository {
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
