import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/routes/data/datasources/routes_remote_data_source.dart';
import 'package:horus_system/features/routes/data/models/route_model.dart';
import 'package:horus_system/features/routes/data/repositories/routes_repository_impl.dart';
import 'package:horus_system/features/routes/domain/entities/route_entity.dart';
import 'package:horus_system/features/routes/domain/entities/route_write_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('RoutesRepositoryImpl', () {
    test('forwards company scope when loading routes', () async {
      final remoteDataSource = _FakeRoutesRemoteDataSource();
      final repository = _repository(remoteDataSource);

      final result = await repository.getRoutes(companyId: _companyId);

      expect(result, isA<Success<List<RouteEntity>>>());
      expect(remoteDataSource.lastListCompanyId, _companyId);
    });

    test('adds route then writes audit', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeRoutesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addRoute(
        data: _writeData(loadingLocation: 'Sharjah'),
        actorRole: 'operations',
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(result.dataOrNull?.loadingLocation, 'Sharjah');
      expect(operations, ['add_route', 'audit']);
      expect(auditRepository.logs.single.description, 'route_created');
    });

    test(
      'updates after company-scoped old snapshot lookup and audits last',
      () async {
        final operations = <String>[];
        final remoteDataSource = _FakeRoutesRemoteDataSource(
          operations: operations,
          oldModel: _model(loadingLocation: 'Old Loading'),
        );
        final auditRepository = _FakeAuditLogRepository(operations: operations);
        final repository = _repository(
          remoteDataSource,
          auditRepository: auditRepository,
        );

        final result = await repository.saveRoute(
          id: _routeId,
          data: _writeData(loadingLocation: 'New Loading'),
          actorRole: 'admin',
        );

        expect(result, isA<Success<RouteEntity>>());
        expect(operations, ['get_route', 'save_route', 'audit']);
        expect(remoteDataSource.lastLookupCompanyId, _companyId);
        expect(remoteDataSource.lastLookupId, _routeId);
        expect(auditRepository.logs.single.description, 'route_updated');
        expect(
          auditRepository.logs.single.oldValues?['loading_location'],
          'Old Loading',
        );
        expect(
          auditRepository.logs.single.newValues?['loading_location'],
          'New Loading',
        );
      },
    );

    test('deactivates after old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeRoutesRemoteDataSource(
        operations: operations,
        oldModel: _model(isActive: true),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.deactivateRoute(
        companyId: _companyId,
        id: _routeId,
        actorRole: 'owner',
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(result.dataOrNull?.isActive, isFalse);
      expect(operations, ['get_route', 'deactivate_route', 'audit']);
      expect(remoteDataSource.lastLifecycleCompanyId, _companyId);
      expect(remoteDataSource.lastLifecycleId, _routeId);
      expect(auditRepository.logs.single.description, 'route_deactivated');
      expect(auditRepository.logs.single.oldValues?['is_active'], isTrue);
      expect(auditRepository.logs.single.newValues?['is_active'], isFalse);
    });

    test('reactivates after old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeRoutesRemoteDataSource(
        operations: operations,
        oldModel: _model(isActive: false),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.reactivateRoute(
        companyId: _companyId,
        id: _routeId,
        actorRole: 'owner',
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(result.dataOrNull?.isActive, isTrue);
      expect(operations, ['get_route', 'reactivate_route', 'audit']);
      expect(remoteDataSource.lastLifecycleCompanyId, _companyId);
      expect(remoteDataSource.lastLifecycleId, _routeId);
      expect(auditRepository.logs.single.description, 'route_reactivated');
      expect(auditRepository.logs.single.oldValues?['is_active'], isFalse);
      expect(auditRepository.logs.single.newValues?['is_active'], isTrue);
    });

    test('sanitizes unexpected mutation failure and does not audit', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeRoutesRemoteDataSource(
        operations: operations,
        addError: Exception('mutation failed internal detail'),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addRoute(
        data: _writeData(),
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<RouteEntity>>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['add_route']);
      expect(auditRepository.logs, isEmpty);
    });

    test('sanitizes Postgrest mutation failure and does not audit', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeRoutesRemoteDataSource(
        operations: operations,
        addError: const PostgrestException(
          message: 'permission denied',
          code: '42501',
          details: 'sensitive details',
          hint: 'sensitive hint',
        ),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addRoute(
        data: _writeData(),
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<RouteEntity>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['add_route']);
      expect(auditRepository.logs, isEmpty);
    });

    test('propagates audit failure after successful mutation', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeRoutesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(
        operations: operations,
        failure: const ValidationFailure(code: FailureCodes.serverError),
      );
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addRoute(
        data: _writeData(),
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<RouteEntity>>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(operations, ['add_route', 'audit']);
    });

    test('sanitizes Postgrest read failures through repository guard', () async {
      final remoteDataSource = _FakeRoutesRemoteDataSource(
        listError: const PostgrestException(
          message: 'permission denied',
          code: '42501',
          details: 'sensitive details',
          hint: 'sensitive hint',
        ),
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.getRoutes(companyId: _companyId);

      expect(result, isA<FailureResult<List<RouteEntity>>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(remoteDataSource.lastListCompanyId, _companyId);
    });

    test(
      'sanitizes model-to-entity mapping failures inside repository guard',
      () async {
        final remoteDataSource = _FakeRoutesRemoteDataSource(
          listModels: const [_ThrowingRouteModel()],
        );
        final repository = _repository(remoteDataSource);

        final result = await repository.getRoutes(companyId: _companyId);

        expect(result, isA<FailureResult<List<RouteEntity>>>());
        expect(result.failureOrNull, isA<UnexpectedFailure>());
        expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.lastListCompanyId, _companyId);
      },
    );
  });
}

const _companyId = 'company-1';
const _routeId = 'route-1';

RoutesRepositoryImpl _repository(
  RoutesRemoteDataSource remoteDataSource, {
  _FakeAuditLogRepository? auditRepository,
}) {
  return RoutesRepositoryImpl(
    remoteDataSource: remoteDataSource,
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? _FakeAuditLogRepository(),
    ),
  );
}

RouteWriteData _writeData({
  String loadingLocation = 'Dubai',
  String unloadingLocation = 'Abu Dhabi',
}) {
  return RouteWriteData(
    companyId: _companyId,
    loadingLocation: loadingLocation,
    unloadingLocation: unloadingLocation,
    governorateFrom: 'Dubai',
    governorateTo: 'Abu Dhabi',
    defaultFreightPrice: 1250,
    notes: 'Notes',
  );
}

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

class _ThrowingRouteModel extends RouteModel {
  const _ThrowingRouteModel()
    : super(
        id: 'route-broken',
        companyId: _companyId,
        loadingLocation: 'ignored',
        unloadingLocation: 'Abu Dhabi',
        isActive: true,
      );

  @override
  String get loadingLocation => throw StateError('mapping internal detail');
}

class _FakeRoutesRemoteDataSource implements RoutesRemoteDataSource {
  final List<String>? operations;
  final Object? listError;
  final Object? addError;
  final List<RouteModel>? listModels;
  final RouteModel oldModel;
  String? lastListCompanyId;
  String? lastLookupCompanyId;
  String? lastLookupId;
  String? lastLifecycleCompanyId;
  String? lastLifecycleId;

  _FakeRoutesRemoteDataSource({
    this.operations,
    this.listError,
    this.addError,
    this.listModels,
    RouteModel? oldModel,
  }) : oldModel = oldModel ?? _model(loadingLocation: 'Old Loading');

  @override
  Future<List<RouteModel>> getRoutes({required String companyId}) async {
    operations?.add('get_routes');
    lastListCompanyId = companyId;
    if (listError != null) throw listError!;
    return listModels ?? [_model()];
  }

  @override
  Future<RouteModel> getRouteById({
    required String companyId,
    required String id,
  }) async {
    operations?.add('get_route');
    lastLookupCompanyId = companyId;
    lastLookupId = id;
    return oldModel;
  }

  @override
  Future<RouteModel> addRoute({required RouteWriteData data}) async {
    operations?.add('add_route');
    if (addError != null) throw addError!;
    return _model(
      loadingLocation: data.loadingLocation,
      unloadingLocation: data.unloadingLocation,
    );
  }

  @override
  Future<RouteModel> saveRoute({
    required String id,
    required RouteWriteData data,
  }) async {
    operations?.add('save_route');
    return _model(
      loadingLocation: data.loadingLocation,
      unloadingLocation: data.unloadingLocation,
    );
  }

  @override
  Future<RouteModel> deactivateRoute({
    required String companyId,
    required String id,
  }) async {
    operations?.add('deactivate_route');
    lastLifecycleCompanyId = companyId;
    lastLifecycleId = id;
    return _model(isActive: false);
  }

  @override
  Future<RouteModel> reactivateRoute({
    required String companyId,
    required String id,
  }) async {
    operations?.add('reactivate_route');
    lastLifecycleCompanyId = companyId;
    lastLifecycleId = id;
    return _model(isActive: true);
  }
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final Failure? failure;
  final List<String>? operations;
  final List<AuditLogWriteData> logs = [];

  _FakeAuditLogRepository({this.failure, this.operations});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    operations?.add('audit');
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
