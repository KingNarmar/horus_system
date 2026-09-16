import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
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
  final configuration = CurrencyConfiguration.tryCreate(
    currencyCode: 'AED',
    fractionDigits: 2,
  )!;

  group('RoutesRepositoryImpl', () {
    test('forwards company scope and decodes exact rate', () async {
      final remote = _FakeRoutesRemoteDataSource();
      final repository = _repository(remote);

      final result = await repository.getRoutes(
        companyId: _companyId,
        financialConfiguration: configuration,
      );

      expect(result, isA<Success<List<RouteEntity>>>());
      expect(remote.lastListCompanyId, _companyId);
      expect(
        result.dataOrNull?.single.defaultFreightRatePerTon,
        Money(minorUnits: 125000, currency: configuration.currency),
      );
    });

    test(
      'adds route then writes audit and forwards financial config',
      () async {
        final operations = <String>[];
        final remote = _FakeRoutesRemoteDataSource(operations: operations);
        final audit = _FakeAuditLogRepository(operations: operations);
        final repository = _repository(remote, auditRepository: audit);

        final result = await repository.addRoute(
          data: _writeData(configuration.currency),
          actorRole: 'operations',
          financialConfiguration: configuration,
        );

        expect(result, isA<Success<RouteEntity>>());
        expect(operations, ['add_route', 'audit']);
        expect(remote.lastMutationConfiguration, configuration);
        expect(audit.logs.single.description, 'route_created');
        expect(
          audit.logs.single.newValues?['default_freight_rate_per_ton'],
          '1250.00',
        );
      },
    );

    test('save reads old snapshot then mutates then audits', () async {
      final operations = <String>[];
      final remote = _FakeRoutesRemoteDataSource(operations: operations);
      final audit = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(remote, auditRepository: audit);

      final result = await repository.saveRoute(
        id: _routeId,
        data: _writeData(configuration.currency, loadingLocation: 'New'),
        actorRole: 'admin',
        financialConfiguration: configuration,
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(operations, ['get_route', 'save_route', 'audit']);
      expect(remote.lastLookupCompanyId, _companyId);
      expect(audit.logs.single.description, 'route_updated');
    });

    test('lifecycle mutations keep company scope and audit ordering', () async {
      final operations = <String>[];
      final remote = _FakeRoutesRemoteDataSource(operations: operations);
      final audit = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(remote, auditRepository: audit);

      final deactivated = await repository.deactivateRoute(
        companyId: _companyId,
        id: _routeId,
        actorRole: 'owner',
        financialConfiguration: configuration,
      );
      expect(deactivated.dataOrNull?.isActive, isFalse);
      expect(operations, ['get_route', 'deactivate_route', 'audit']);

      operations.clear();
      audit.logs.clear();
      final reactivated = await repository.reactivateRoute(
        companyId: _companyId,
        id: _routeId,
        actorRole: 'owner',
        financialConfiguration: configuration,
      );
      expect(reactivated.dataOrNull?.isActive, isTrue);
      expect(operations, ['get_route', 'reactivate_route', 'audit']);
    });

    test(
      'sanitizes Postgrest failures and does not audit failed write',
      () async {
        final operations = <String>[];
        final remote = _FakeRoutesRemoteDataSource(
          operations: operations,
          addError: const PostgrestException(
            message: 'permission denied',
            code: '42501',
            details: 'sensitive details',
            hint: 'sensitive hint',
          ),
        );
        final audit = _FakeAuditLogRepository(operations: operations);
        final repository = _repository(remote, auditRepository: audit);

        final result = await repository.addRoute(
          data: _writeData(configuration.currency),
          actorRole: 'operations',
          financialConfiguration: configuration,
        );

        expect(result, isA<FailureResult<RouteEntity>>());
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
        expect(audit.logs, isEmpty);
      },
    );

    test('propagates audit failure after successful write', () async {
      final operations = <String>[];
      final remote = _FakeRoutesRemoteDataSource(operations: operations);
      final audit = _FakeAuditLogRepository(
        operations: operations,
        failure: const ValidationFailure(code: FailureCodes.serverError),
      );
      final repository = _repository(remote, auditRepository: audit);

      final result = await repository.addRoute(
        data: _writeData(configuration.currency),
        actorRole: 'operations',
        financialConfiguration: configuration,
      );

      expect(result, isA<FailureResult<RouteEntity>>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(operations, ['add_route', 'audit']);
    });
  });
}

const _companyId = 'company-1';
const _routeId = 'route-1';

RoutesRepositoryImpl _repository(
  RoutesRemoteDataSource remote, {
  _FakeAuditLogRepository? auditRepository,
}) {
  return RoutesRepositoryImpl(
    remoteDataSource: remote,
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? _FakeAuditLogRepository(),
    ),
  );
}

RouteWriteData _writeData(
  CurrencyCode currency, {
  String loadingLocation = 'Dubai',
}) {
  return RouteWriteData(
    companyId: _companyId,
    loadingLocation: loadingLocation,
    unloadingLocation: 'Abu Dhabi',
    defaultFreightRatePerTon: Money(minorUnits: 125000, currency: currency),
  );
}

RouteModel _model({bool isActive = true, String loadingLocation = 'Dubai'}) {
  return RouteModel(
    id: _routeId,
    companyId: _companyId,
    loadingLocation: loadingLocation,
    unloadingLocation: 'Abu Dhabi',
    defaultFreightRatePerTonDecimal: '1250.00',
    isActive: isActive,
  );
}

class _FakeRoutesRemoteDataSource implements RoutesRemoteDataSource {
  final List<String>? operations;
  final Object? addError;
  String? lastListCompanyId;
  String? lastLookupCompanyId;
  CurrencyConfiguration? lastMutationConfiguration;

  _FakeRoutesRemoteDataSource({this.operations, this.addError});

  @override
  Future<List<RouteModel>> getRoutes({required String companyId}) async {
    lastListCompanyId = companyId;
    return [_model()];
  }

  @override
  Future<RouteModel> getRouteById({
    required String companyId,
    required String id,
  }) async {
    operations?.add('get_route');
    lastLookupCompanyId = companyId;
    return _model();
  }

  @override
  Future<RouteModel> addRoute({
    required RouteWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    operations?.add('add_route');
    lastMutationConfiguration = financialConfiguration;
    if (addError != null) throw addError!;
    return _model(loadingLocation: data.loadingLocation);
  }

  @override
  Future<RouteModel> saveRoute({
    required String id,
    required RouteWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    operations?.add('save_route');
    lastMutationConfiguration = financialConfiguration;
    return _model(loadingLocation: data.loadingLocation);
  }

  @override
  Future<RouteModel> deactivateRoute({
    required String companyId,
    required String id,
  }) async {
    operations?.add('deactivate_route');
    return _model(isActive: false);
  }

  @override
  Future<RouteModel> reactivateRoute({
    required String companyId,
    required String id,
  }) async {
    operations?.add('reactivate_route');
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
    logs.add(data);
    final currentFailure = failure;
    if (currentFailure != null) return FailureResult(currentFailure);
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async => const Success([]);
}
