import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
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

    test('adds route and forwards financial configuration', () async {
      final operations = <String>[];
      final remote = _FakeRoutesRemoteDataSource(operations: operations);
      final repository = _repository(remote);

      final result = await repository.addRoute(
        data: _writeData(configuration.currency),
        actorRole: 'operations',
        financialConfiguration: configuration,
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(operations, ['add_route']);
      expect(remote.lastMutationConfiguration, configuration);
    });

    test('saves route without redundant audit snapshot lookup', () async {
      final operations = <String>[];
      final remote = _FakeRoutesRemoteDataSource(operations: operations);
      final repository = _repository(remote);

      final result = await repository.saveRoute(
        id: _routeId,
        data: _writeData(configuration.currency, loadingLocation: 'New'),
        actorRole: 'admin',
        financialConfiguration: configuration,
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(operations, ['save_route']);
      expect(remote.lastLookupCompanyId, isNull);
    });

    test('lifecycle mutations remain company scoped', () async {
      final operations = <String>[];
      final remote = _FakeRoutesRemoteDataSource(operations: operations);
      final repository = _repository(remote);

      final deactivated = await repository.deactivateRoute(
        companyId: _companyId,
        id: _routeId,
        actorRole: 'owner',
        financialConfiguration: configuration,
      );
      expect(deactivated.dataOrNull?.isActive, isFalse);
      expect(operations, ['deactivate_route']);

      operations.clear();
      final reactivated = await repository.reactivateRoute(
        companyId: _companyId,
        id: _routeId,
        actorRole: 'owner',
        financialConfiguration: configuration,
      );
      expect(reactivated.dataOrNull?.isActive, isTrue);
      expect(operations, ['reactivate_route']);
    });

    test('sanitizes Postgrest write failures', () async {
      final remote = _FakeRoutesRemoteDataSource(
        addError: const PostgrestException(
          message: 'permission denied',
          code: '42501',
          details: 'sensitive details',
          hint: 'sensitive hint',
        ),
      );
      final repository = _repository(remote);

      final result = await repository.addRoute(
        data: _writeData(configuration.currency),
        actorRole: 'operations',
        financialConfiguration: configuration,
      );

      expect(result, isA<FailureResult<RouteEntity>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

const _companyId = 'company-1';
const _routeId = 'route-1';

RoutesRepositoryImpl _repository(RoutesRemoteDataSource remote) {
  return RoutesRepositoryImpl(remoteDataSource: remote);
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
