import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/audit/data/datasources/audit_logs_remote_data_source.dart';
import 'package:horus_system/features/audit/data/models/audit_log_model.dart';
import 'package:horus_system/features/audit/data/repositories/audit_log_repository_impl.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('AuditLogRepositoryImpl', () {
    test('creates an audit log and forwards the same write data', () async {
      final dataSource = _FakeAuditLogsRemoteDataSource();
      final repository = AuditLogRepositoryImpl(remoteDataSource: dataSource);
      const data = _writeData;

      final result = await repository.createAuditLog(data: data);

      expect(result.failureOrNull, isNull);
      expect(dataSource.createCalls, 1);
      expect(dataSource.createdData, same(data));
    });

    test('maps read models preserving order and content', () async {
      final dataSource = _FakeAuditLogsRemoteDataSource(
        models: [
          _model(id: 'audit-2', entityId: 'entity-2'),
          _model(id: 'audit-1', entityId: 'entity-1'),
        ],
      );
      final repository = AuditLogRepositoryImpl(remoteDataSource: dataSource);

      final result = await repository.getEntityAuditLogs(
        companyId: ' company-1 ',
        module: AuditModule.drivers,
        entityType: AuditEntityType.driver,
        entityId: ' entity-1 ',
      );

      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull?.map((log) => log.id).toList(), [
        'audit-2',
        'audit-1',
      ]);
      expect(result.dataOrNull?.map((log) => log.entityId).toList(), [
        'entity-2',
        'entity-1',
      ]);
      expect(result.dataOrNull?.first.companyId, 'company-1');
      expect(result.dataOrNull?.first.module, AuditModule.drivers);
      expect(result.dataOrNull?.first.entityType, AuditEntityType.driver);
      expect(result.dataOrNull?.first.action, AuditAction.updated);
      expect(result.dataOrNull?.first.description, 'driver_updated');
      expect(result.dataOrNull?.first.oldValues, {'name': 'Old'});
      expect(result.dataOrNull?.first.newValues, {'name': 'New'});
      expect(result.dataOrNull?.first.metadata, {'audit_event': 'updated'});
      expect(dataSource.readCalls, 1);
      expect(dataSource.companyId, ' company-1 ');
      expect(dataSource.module, AuditModule.drivers);
      expect(dataSource.entityType, AuditEntityType.driver);
      expect(dataSource.entityId, ' entity-1 ');
    });

    test('sanitizes create PostgREST failures', () async {
      final repository = AuditLogRepositoryImpl(
        remoteDataSource: _FakeAuditLogsRemoteDataSource(
          createError: _postgrestException,
        ),
      );

      final result = await repository.createAuditLog(data: _writeData);

      _expectSanitizedServerFailure(result.failureOrNull);
    });

    test('sanitizes read PostgREST failures', () async {
      final repository = AuditLogRepositoryImpl(
        remoteDataSource: _FakeAuditLogsRemoteDataSource(
          readError: _postgrestException,
        ),
      );

      final result = await repository.getEntityAuditLogs(
        companyId: 'company-1',
        module: AuditModule.drivers,
        entityType: AuditEntityType.driver,
        entityId: 'driver-1',
      );

      _expectSanitizedServerFailure(result.failureOrNull);
    });

    test('sanitizes unexpected create failures', () async {
      final repository = AuditLogRepositoryImpl(
        remoteDataSource: _FakeAuditLogsRemoteDataSource(
          createError: StateError('secret create implementation detail'),
        ),
      );

      final result = await repository.createAuditLog(data: _writeData);

      _expectSanitizedUnexpectedFailure(result.failureOrNull);
    });

    test('sanitizes unexpected read failures', () async {
      final repository = AuditLogRepositoryImpl(
        remoteDataSource: _FakeAuditLogsRemoteDataSource(
          readError: StateError('secret read implementation detail'),
        ),
      );

      final result = await repository.getEntityAuditLogs(
        companyId: 'company-1',
        module: AuditModule.drivers,
        entityType: AuditEntityType.driver,
        entityId: 'driver-1',
      );

      _expectSanitizedUnexpectedFailure(result.failureOrNull);
    });

    test('keeps model mapping inside the sanitized boundary', () async {
      final repository = AuditLogRepositoryImpl(
        remoteDataSource: _FakeAuditLogsRemoteDataSource(
          models: [_ThrowingAuditLogModel()],
        ),
      );

      final result = await repository.getEntityAuditLogs(
        companyId: 'company-1',
        module: AuditModule.drivers,
        entityType: AuditEntityType.driver,
        entityId: 'driver-1',
      );

      _expectSanitizedUnexpectedFailure(result.failureOrNull);
    });
  });
}

const _writeData = AuditLogWriteData(
  companyId: 'company-1',
  actorRole: 'admin',
  module: AuditModule.drivers,
  entityType: AuditEntityType.driver,
  entityId: 'driver-1',
  action: AuditAction.updated,
  description: 'driver_updated',
);

const _postgrestException = PostgrestException(
  message: 'secret backend message',
  code: 'XX999',
  details: 'private database details',
  hint: 'internal database hint',
);

AuditLogModel _model({required String id, required String entityId}) {
  return AuditLogModel(
    id: id,
    companyId: 'company-1',
    actorUserId: 'user-1',
    actorRole: 'admin',
    actorDisplayName: 'Admin User',
    actorEmail: 'admin@example.com',
    module: 'drivers',
    entityType: 'driver',
    entityId: entityId,
    entityDisplayName: 'Driver',
    action: 'updated',
    description: 'driver_updated',
    oldValues: const {'name': 'Old'},
    newValues: const {'name': 'New'},
    metadata: const {'audit_event': 'updated'},
    createdAt: DateTime.utc(2026, 8, 26),
  );
}

void _expectSanitizedServerFailure(Object? failure) {
  expect(failure, isA<ServerFailure>());
  expect((failure as ServerFailure).code, FailureCodes.serverError);
  expect(failure.message, isNull);
}

void _expectSanitizedUnexpectedFailure(Object? failure) {
  expect(failure, isA<UnexpectedFailure>());
  expect((failure as UnexpectedFailure).code, FailureCodes.unexpectedError);
  expect(failure.message, isNull);
}

final class _FakeAuditLogsRemoteDataSource
    implements AuditLogsRemoteDataSource {
  final List<AuditLogModel> models;
  final Object? createError;
  final Object? readError;

  int createCalls = 0;
  int readCalls = 0;
  AuditLogWriteData? createdData;
  String? companyId;
  AuditModule? module;
  AuditEntityType? entityType;
  String? entityId;

  _FakeAuditLogsRemoteDataSource({
    this.models = const [],
    this.createError,
    this.readError,
  });

  @override
  Future<void> createAuditLog({required AuditLogWriteData data}) async {
    createCalls += 1;
    createdData = data;
    final error = createError;
    if (error != null) throw error;
  }

  @override
  Future<List<AuditLogModel>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    readCalls += 1;
    this.companyId = companyId;
    this.module = module;
    this.entityType = entityType;
    this.entityId = entityId;
    final error = readError;
    if (error != null) throw error;
    return models;
  }
}

final class _ThrowingAuditLogModel extends AuditLogModel {
  _ThrowingAuditLogModel()
    : super(
        id: 'audit-1',
        companyId: 'company-1',
        module: 'drivers',
        entityType: 'driver',
        entityId: 'driver-1',
        action: 'updated',
        description: 'driver_updated',
        createdAt: DateTime.utc(2026, 8, 26),
      );

  @override
  Never toEntity() => throw StateError('secret model mapping detail');
}
