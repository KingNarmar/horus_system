import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/routes/domain/entities/route_entity.dart';
import 'package:horus_system/features/routes/domain/entities/route_write_data.dart';
import 'package:horus_system/features/routes/domain/repositories/routes_repository.dart';
import 'package:horus_system/features/routes/domain/usecases/routes_usecases.dart';
import 'package:test/test.dart';

void main() {
  group('GetRoutesUseCase', () {
    test('denies roles without view permission before repository call', () async {
      final repository = _FakeRoutesRepository();
      final useCase = GetRoutesUseCase(repository);

      final result = await useCase(
        GetRoutesParams(
          currentCompanyContext: _context(role: CompanyRole.driver),
        ),
      );

      expect(result, isA<FailureResult<List<RouteEntity>>>());
      expect(result.failureOrNull?.code, FailureCodes.permissionRoutesView);
      expect(repository.getRoutesCalls, 0);
    });

    test('forwards exact company id for authorized read', () async {
      final repository = _FakeRoutesRepository();
      final useCase = GetRoutesUseCase(repository);

      final result = await useCase(
        GetRoutesParams(
          currentCompanyContext: _context(
            companyId: '  company-1  ',
            role: CompanyRole.viewer,
          ),
        ),
      );

      expect(result, isA<Success<List<RouteEntity>>>());
      expect(repository.getRoutesCalls, 1);
      expect(repository.lastCompanyId, '  company-1  ');
    });
  });

  group('SaveRouteUseCase', () {
    test('denies roles without management permission', () async {
      final repository = _FakeRoutesRepository();
      final useCase = SaveRouteUseCase(repository);

      final result = await useCase(
        SaveRouteParams(
          currentCompanyContext: _context(role: CompanyRole.viewer),
          loadingLocation: 'Dubai',
          unloadingLocation: 'Abu Dhabi',
        ),
      );

      expect(result, isA<FailureResult<RouteEntity>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionRoutesManagement,
      );
      expect(repository.totalMutationCalls, 0);
    });

    test('requires loading location after trimming', () async {
      final repository = _FakeRoutesRepository();
      final useCase = SaveRouteUseCase(repository);

      final result = await useCase(
        SaveRouteParams(
          currentCompanyContext: _context(),
          loadingLocation: '   ',
          unloadingLocation: 'Abu Dhabi',
        ),
      );

      expect(result, isA<FailureResult<RouteEntity>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationRouteLoadingLocationRequired,
      );
      expect(repository.totalMutationCalls, 0);
    });

    test('requires unloading location after trimming', () async {
      final repository = _FakeRoutesRepository();
      final useCase = SaveRouteUseCase(repository);

      final result = await useCase(
        SaveRouteParams(
          currentCompanyContext: _context(),
          loadingLocation: 'Dubai',
          unloadingLocation: '   ',
        ),
      );

      expect(result, isA<FailureResult<RouteEntity>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationRouteUnloadingLocationRequired,
      );
      expect(repository.totalMutationCalls, 0);
    });

    test('rejects negative default freight price', () async {
      final repository = _FakeRoutesRepository();
      final useCase = SaveRouteUseCase(repository);

      final result = await useCase(
        SaveRouteParams(
          currentCompanyContext: _context(),
          loadingLocation: 'Dubai',
          unloadingLocation: 'Abu Dhabi',
          defaultFreightPrice: -1,
        ),
      );

      expect(result, isA<FailureResult<RouteEntity>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationRouteFreightPriceNegative,
      );
      expect(repository.totalMutationCalls, 0);
    });

    test('blank id creates and normalizes route write data', () async {
      final repository = _FakeRoutesRepository();
      final useCase = SaveRouteUseCase(repository);

      final result = await useCase(
        SaveRouteParams(
          currentCompanyContext: _context(),
          id: '   ',
          loadingLocation: '  Dubai  ',
          unloadingLocation: '  Abu Dhabi  ',
          governorateFrom: '  Dubai  ',
          governorateTo: '   ',
          defaultFreightPrice: 1250,
          notes: '  Priority route  ',
        ),
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(repository.addRouteCalls, 1);
      expect(repository.saveRouteCalls, 0);
      expect(repository.lastActorRole, CompanyRole.owner.value);
      final data = repository.lastWriteData!;
      expect(data.companyId, _companyId);
      expect(data.loadingLocation, 'Dubai');
      expect(data.unloadingLocation, 'Abu Dhabi');
      expect(data.governorateFrom, 'Dubai');
      expect(data.governorateTo, isNull);
      expect(data.defaultFreightPrice, 1250);
      expect(data.notes, 'Priority route');
    });

    test('nonblank id updates using trimmed id and optional values', () async {
      final repository = _FakeRoutesRepository();
      final useCase = SaveRouteUseCase(repository);

      final result = await useCase(
        SaveRouteParams(
          currentCompanyContext: _context(role: CompanyRole.admin),
          id: '  route-1  ',
          loadingLocation: 'Dubai',
          unloadingLocation: 'Al Ain',
          governorateFrom: '   ',
          governorateTo: '  Abu Dhabi  ',
          notes: '   ',
        ),
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(repository.addRouteCalls, 0);
      expect(repository.saveRouteCalls, 1);
      expect(repository.lastRouteId, 'route-1');
      expect(repository.lastActorRole, CompanyRole.admin.value);
      final data = repository.lastWriteData!;
      expect(data.governorateFrom, isNull);
      expect(data.governorateTo, 'Abu Dhabi');
      expect(data.notes, isNull);
    });
  });

  group('route lifecycle use cases', () {
    test('deactivate forwards company, id, and actor role', () async {
      final repository = _FakeRoutesRepository();
      final useCase = DeactivateRouteUseCase(repository);

      final result = await useCase(
        RouteActiveStateParams(
          currentCompanyContext: _context(role: CompanyRole.operations),
          id: 'route-1',
        ),
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(repository.deactivateCalls, 1);
      expect(repository.lastCompanyId, _companyId);
      expect(repository.lastRouteId, 'route-1');
      expect(repository.lastActorRole, CompanyRole.operations.value);
    });

    test('reactivate forwards company, id, and actor role', () async {
      final repository = _FakeRoutesRepository();
      final useCase = ReactivateRouteUseCase(repository);

      final result = await useCase(
        RouteActiveStateParams(
          currentCompanyContext: _context(role: CompanyRole.owner),
          id: ' route-1 ',
        ),
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(repository.reactivateCalls, 1);
      expect(repository.lastCompanyId, _companyId);
      expect(repository.lastRouteId, ' route-1 ');
      expect(repository.lastActorRole, CompanyRole.owner.value);
    });
  });
}

const _companyId = 'company-1';

CurrentCompanyContext _context({
  String companyId = _companyId,
  CompanyRole role = CompanyRole.owner,
}) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: 'Company'),
    role: role,
  );
}

RouteEntity _route() {
  return const RouteEntity(
    id: 'route-1',
    companyId: _companyId,
    loadingLocation: 'Dubai',
    unloadingLocation: 'Abu Dhabi',
    isActive: true,
  );
}

class _FakeRoutesRepository implements RoutesRepository {
  int getRoutesCalls = 0;
  int addRouteCalls = 0;
  int saveRouteCalls = 0;
  int deactivateCalls = 0;
  int reactivateCalls = 0;
  String? lastCompanyId;
  String? lastRouteId;
  String? lastActorRole;
  RouteWriteData? lastWriteData;

  int get totalMutationCalls =>
      addRouteCalls + saveRouteCalls + deactivateCalls + reactivateCalls;

  @override
  Future<Result<List<RouteEntity>>> getRoutes({
    required String companyId,
  }) async {
    getRoutesCalls += 1;
    lastCompanyId = companyId;
    return const Success<List<RouteEntity>>([]);
  }

  @override
  Future<Result<RouteEntity>> addRoute({
    required RouteWriteData data,
    required String actorRole,
  }) async {
    addRouteCalls += 1;
    lastCompanyId = data.companyId;
    lastActorRole = actorRole;
    lastWriteData = data;
    return Success(_route());
  }

  @override
  Future<Result<RouteEntity>> saveRoute({
    required String id,
    required RouteWriteData data,
    required String actorRole,
  }) async {
    saveRouteCalls += 1;
    lastCompanyId = data.companyId;
    lastRouteId = id;
    lastActorRole = actorRole;
    lastWriteData = data;
    return Success(_route());
  }

  @override
  Future<Result<RouteEntity>> deactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
  }) async {
    deactivateCalls += 1;
    lastCompanyId = companyId;
    lastRouteId = id;
    lastActorRole = actorRole;
    return Success(_route());
  }

  @override
  Future<Result<RouteEntity>> reactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
  }) async {
    reactivateCalls += 1;
    lastCompanyId = companyId;
    lastRouteId = id;
    lastActorRole = actorRole;
    return Success(_route());
  }
}
