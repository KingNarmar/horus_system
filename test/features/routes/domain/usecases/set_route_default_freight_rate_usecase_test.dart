import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/routes/domain/entities/route_entity.dart';
import 'package:horus_system/features/routes/domain/failures/route_failure_codes.dart';
import 'package:horus_system/features/routes/domain/repositories/route_financial_terms_repository.dart';
import 'package:horus_system/features/routes/domain/usecases/set_route_default_freight_rate_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('SetRouteDefaultFreightRateUseCase', () {
    for (final role in [
      CompanyRole.owner,
      CompanyRole.admin,
      CompanyRole.accountant,
    ]) {
      test('permits finance-only update for ${role.name}', () async {
        final repository = _FakeRouteFinancialTermsRepository();
        final result = await SetRouteDefaultFreightRateUseCase(repository)(
          SetRouteDefaultFreightRateParams(
            currentCompanyContext: _context(role),
            route: _route(),
            rateInput: '87.25',
          ),
        );
        expect(result, isA<Success<RouteEntity>>());
        expect(repository.calls, 1);
        expect(repository.companyId, 'company-1');
        expect(repository.routeId, 'route-1');
        expect(repository.rate?.minorUnits, 8725);
        expect(repository.expectedUpdatedAt, _route().updatedAt);
      });
    }

    for (final role in [
      CompanyRole.operations,
      CompanyRole.viewer,
      CompanyRole.driver,
    ]) {
      test('denies ${role.name} without repository access', () async {
        final repository = _FakeRouteFinancialTermsRepository();
        final result = await SetRouteDefaultFreightRateUseCase(repository)(
          SetRouteDefaultFreightRateParams(
            currentCompanyContext: _context(role),
            route: _route(),
            rateInput: '87.25',
          ),
        );
        expect(
          result.failureOrNull?.code,
          RouteFailureCodes.financialTermsPermissionDenied,
        );
        expect(repository.calls, 0);
      });
    }

    test('denies cross-company Route', () async {
      final repository = _FakeRouteFinancialTermsRepository();
      final result = await SetRouteDefaultFreightRateUseCase(repository)(
        SetRouteDefaultFreightRateParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          route: _route(companyId: 'other-company'),
          rateInput: '87.25',
        ),
      );
      expect(
        result.failureOrNull?.code,
        RouteFailureCodes.financialTermsPermissionDenied,
      );
      expect(repository.calls, 0);
    });

    test('rejects missing optimistic concurrency snapshot', () async {
      final repository = _FakeRouteFinancialTermsRepository();
      final result = await SetRouteDefaultFreightRateUseCase(repository)(
        SetRouteDefaultFreightRateParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          route: _route(withUpdatedAt: false),
          rateInput: '87.25',
        ),
      );
      expect(
        result.failureOrNull?.code,
        RouteFailureCodes.staleFinancialSnapshot,
      );
      expect(repository.calls, 0);
    });

    test('requires financial settings and valid precision', () async {
      final repository = _FakeRouteFinancialTermsRepository();
      final useCase = SetRouteDefaultFreightRateUseCase(repository);
      final noConfig = await useCase(
        SetRouteDefaultFreightRateParams(
          currentCompanyContext: _context(
            CompanyRole.accountant,
            withSettings: false,
          ),
          route: _route(),
          rateInput: '87.25',
        ),
      );
      final invalidRate = await useCase(
        SetRouteDefaultFreightRateParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          route: _route(),
          rateInput: '87.257',
        ),
      );
      expect(
        noConfig.failureOrNull?.code,
        CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
      );
      expect(
        invalidRate.failureOrNull?.code,
        FailureCodes.validationRouteFreightRateInvalid,
      );
      expect(repository.calls, 0);
    });
  });
}

CurrentCompanyContext _context(CompanyRole role, {bool withSettings = true}) =>
    CurrentCompanyContext(
      company: Company(
        id: 'company-1',
        name: 'Company',
        baseCurrencyCode: withSettings ? 'AED' : null,
        baseCurrencyFractionDigits: withSettings ? 2 : null,
      ),
      role: role,
    );

RouteEntity _route({
  String companyId = 'company-1',
  bool withUpdatedAt = true,
}) => RouteEntity(
  id: 'route-1',
  companyId: companyId,
  loadingLocation: 'Dubai',
  unloadingLocation: 'Sharjah',
  isActive: true,
  updatedAt: withUpdatedAt ? DateTime.utc(2026, 10, 19) : null,
);

final class _FakeRouteFinancialTermsRepository
    implements RouteFinancialTermsRepository {
  int calls = 0;
  String? companyId;
  String? routeId;
  Money? rate;
  CurrencyConfiguration? configuration;
  DateTime? expectedUpdatedAt;

  @override
  Future<Result<RouteEntity>> setDefaultFreightRate({
    required String companyId,
    required String routeId,
    required Money rate,
    required CurrencyConfiguration financialConfiguration,
    required DateTime expectedUpdatedAt,
  }) async {
    calls += 1;
    this.companyId = companyId;
    this.routeId = routeId;
    this.rate = rate;
    configuration = financialConfiguration;
    this.expectedUpdatedAt = expectedUpdatedAt;
    return Success(_route());
  }
}
