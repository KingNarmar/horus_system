import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/routes/domain/entities/route_entity.dart';
import 'package:horus_system/features/routes/domain/entities/route_write_data.dart';
import 'package:horus_system/features/routes/domain/repositories/routes_repository.dart';
import 'package:horus_system/features/routes/domain/usecases/routes_usecases.dart';
import 'package:test/test.dart';

void main() {
  group('GetRoutesUseCase', () {
    test(
      'denies roles without view permission before repository call',
      () async {
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
      },
    );

    test('forwards company id and company financial configuration', () async {
      final repository = _FakeRoutesRepository();
      final useCase = GetRoutesUseCase(repository);

      final result = await useCase(
        GetRoutesParams(
          currentCompanyContext: _context(
            companyId: 'company-1',
            role: CompanyRole.viewer,
          ),
        ),
      );

      expect(result, isA<Success<List<RouteEntity>>>());
      expect(repository.lastCompanyId, 'company-1');
      expect(repository.lastFinancialConfiguration?.currency.value, 'AED');
      expect(repository.lastFinancialConfiguration?.fractionDigits, 2);
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

    test('requires loading and unloading locations after trimming', () async {
      final repository = _FakeRoutesRepository();
      final useCase = SaveRouteUseCase(repository);

      final loadingResult = await useCase(
        SaveRouteParams(
          currentCompanyContext: _context(),
          loadingLocation: '   ',
          unloadingLocation: 'Abu Dhabi',
        ),
      );
      expect(
        loadingResult.failureOrNull?.code,
        FailureCodes.validationRouteLoadingLocationRequired,
      );

      final unloadingResult = await useCase(
        SaveRouteParams(
          currentCompanyContext: _context(),
          loadingLocation: 'Dubai',
          unloadingLocation: '   ',
        ),
      );
      expect(
        unloadingResult.failureOrNull?.code,
        FailureCodes.validationRouteUnloadingLocationRequired,
      );
      expect(repository.totalMutationCalls, 0);
    });

    test('rejects invalid or over-precision rate input', () async {
      final repository = _FakeRoutesRepository();
      final useCase = SaveRouteUseCase(repository);

      for (final input in ['-1', '1.001', 'abc']) {
        final result = await useCase(
          SaveRouteParams(
            currentCompanyContext: _context(),
            loadingLocation: 'Dubai',
            unloadingLocation: 'Abu Dhabi',
            defaultFreightRatePerTonInput: input,
          ),
        );

        expect(result, isA<FailureResult<RouteEntity>>());
        expect(
          result.failureOrNull?.code,
          FailureCodes.validationRouteFreightRateInvalid,
        );
      }
      expect(repository.totalMutationCalls, 0);
    });

    test(
      'requires company financial settings when a rate is supplied',
      () async {
        final repository = _FakeRoutesRepository();
        final useCase = SaveRouteUseCase(repository);

        final result = await useCase(
          SaveRouteParams(
            currentCompanyContext: _context(withFinancialSettings: false),
            loadingLocation: 'Dubai',
            unloadingLocation: 'Abu Dhabi',
            defaultFreightRatePerTonInput: '1250',
          ),
        );

        expect(result, isA<FailureResult<RouteEntity>>());
        expect(
          result.failureOrNull?.code,
          CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
        );
        expect(repository.totalMutationCalls, 0);
      },
    );

    test('creates normalized route with exact Money rate', () async {
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
          defaultFreightRatePerTonInput: '1250.50',
          notes: '  Priority route  ',
        ),
      );

      expect(result, isA<Success<RouteEntity>>());
      expect(repository.addRouteCalls, 1);
      expect(repository.saveRouteCalls, 0);
      final data = repository.lastWriteData!;
      expect(data.loadingLocation, 'Dubai');
      expect(data.unloadingLocation, 'Abu Dhabi');
      expect(data.governorateFrom, 'Dubai');
      expect(data.governorateTo, isNull);
      expect(
        data.defaultFreightRatePerTon,
        Money(
          minorUnits: 125050,
          currency: repository.lastFinancialConfiguration!.currency,
        ),
      );
      expect(data.notes, 'Priority route');
    });

    test('updates using trimmed id and nullable rate', () async {
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
      expect(repository.saveRouteCalls, 1);
      expect(repository.lastRouteId, 'route-1');
      expect(repository.lastWriteData?.defaultFreightRatePerTon, isNull);
    });
  });

  group('route lifecycle use cases', () {
    test('forwards scope, role, and financial config', () async {
      final repository = _FakeRoutesRepository();

      final deactivate = await DeactivateRouteUseCase(repository)(
        RouteActiveStateParams(
          currentCompanyContext: _context(role: CompanyRole.operations),
          id: 'route-1',
        ),
      );
      expect(deactivate, isA<Success<RouteEntity>>());
      expect(repository.lastCompanyId, _companyId);
      expect(repository.lastRouteId, 'route-1');
      expect(repository.lastActorRole, CompanyRole.operations.value);
      expect(repository.lastFinancialConfiguration?.currency.value, 'AED');

      final reactivate = await ReactivateRouteUseCase(repository)(
        RouteActiveStateParams(
          currentCompanyContext: _context(role: CompanyRole.owner),
          id: 'route-1',
        ),
      );
      expect(reactivate, isA<Success<RouteEntity>>());
    });
  });
}

const _companyId = 'company-1';

CurrentCompanyContext _context({
  String companyId = _companyId,
  CompanyRole role = CompanyRole.owner,
  bool withFinancialSettings = true,
}) {
  return CurrentCompanyContext(
    company: Company(
      id: companyId,
      name: 'Company',
      baseCurrencyCode: withFinancialSettings ? 'AED' : null,
      baseCurrencyFractionDigits: withFinancialSettings ? 2 : null,
    ),
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
  CurrencyConfiguration? lastFinancialConfiguration;

  int get totalMutationCalls =>
      addRouteCalls + saveRouteCalls + deactivateCalls + reactivateCalls;

  void _captureConfiguration(CurrencyConfiguration? value) {
    lastFinancialConfiguration = value;
  }

  @override
  Future<Result<List<RouteEntity>>> getRoutes({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    getRoutesCalls += 1;
    lastCompanyId = companyId;
    _captureConfiguration(financialConfiguration);
    return const Success<List<RouteEntity>>([]);
  }

  @override
  Future<Result<RouteEntity>> addRoute({
    required RouteWriteData data,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    addRouteCalls += 1;
    lastCompanyId = data.companyId;
    lastActorRole = actorRole;
    lastWriteData = data;
    _captureConfiguration(financialConfiguration);
    return Success(_route());
  }

  @override
  Future<Result<RouteEntity>> saveRoute({
    required String id,
    required RouteWriteData data,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    saveRouteCalls += 1;
    lastCompanyId = data.companyId;
    lastRouteId = id;
    lastActorRole = actorRole;
    lastWriteData = data;
    _captureConfiguration(financialConfiguration);
    return Success(_route());
  }

  @override
  Future<Result<RouteEntity>> deactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    deactivateCalls += 1;
    lastCompanyId = companyId;
    lastRouteId = id;
    lastActorRole = actorRole;
    _captureConfiguration(financialConfiguration);
    return Success(_route());
  }

  @override
  Future<Result<RouteEntity>> reactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    reactivateCalls += 1;
    lastCompanyId = companyId;
    lastRouteId = id;
    lastActorRole = actorRole;
    _captureConfiguration(financialConfiguration);
    return Success(_route());
  }
}
