import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/routes/domain/entities/route_entity.dart';
import 'package:horus_system/features/routes/domain/failures/route_failure_codes.dart';
import 'package:horus_system/features/routes/domain/repositories/route_financial_terms_repository.dart';
import 'package:horus_system/features/routes/domain/usecases/set_route_default_freight_rate_usecase.dart';
import 'package:horus_system/features/routes/presentation/cubit/route_default_freight_rate_cubit.dart';

void main() {
  test('accountant changes only default freight rate via use case', () async {
    final repository = _FakeRepository();
    final cubit = RouteDefaultFreightRateCubit(
      SetRouteDefaultFreightRateUseCase(repository),
    );
    await cubit.save(
      currentCompanyContext: _context(CompanyRole.accountant),
      route: _route,
      rateInput: '21.50',
    );
    expect(repository.calls, 1);
    expect(cubit.state, isA<RouteDefaultFreightRateSaved>());
    cubit.reset();
    expect(cubit.state, isA<RouteDefaultFreightRateInitial>());
    await cubit.close();
  });

  test('operations price changes fail before any repository call', () async {
    final repository = _FakeRepository();
    final cubit = RouteDefaultFreightRateCubit(
      SetRouteDefaultFreightRateUseCase(repository),
    );
    await cubit.save(
      currentCompanyContext: _context(CompanyRole.operations),
      route: _route,
      rateInput: '21.50',
    );
    expect(repository.calls, 0);
    expect(cubit.state, isA<RouteDefaultFreightRateFailure>());
    expect(
      (cubit.state as RouteDefaultFreightRateFailure).failure.code,
      RouteFailureCodes.financialTermsPermissionDenied,
    );
    await cubit.close();
  });

  test('duplicate in-flight rate writes do not race', () async {
    final repository = _FakeRepository(
      pending: Completer<Result<RouteEntity>>(),
    );
    final cubit = RouteDefaultFreightRateCubit(
      SetRouteDefaultFreightRateUseCase(repository),
    );
    final first = cubit.save(
      currentCompanyContext: _context(CompanyRole.accountant),
      route: _route,
      rateInput: '21.50',
    );
    final second = cubit.save(
      currentCompanyContext: _context(CompanyRole.accountant),
      route: _route,
      rateInput: '22.50',
    );
    expect(repository.calls, 1);
    expect(cubit.state, isA<RouteDefaultFreightRateSaving>());
    repository.pending!.complete(Success(_route));
    await Future.wait([first, second]);
    expect(cubit.state, isA<RouteDefaultFreightRateSaved>());
    await cubit.close();
  });
}

CurrentCompanyContext _context(CompanyRole role) => CurrentCompanyContext(
  company: const Company(
    id: 'company-1',
    name: 'Company',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
  ),
  role: role,
);

final _route = RouteEntity(
  id: 'route-1',
  companyId: 'company-1',
  loadingLocation: 'Dubai',
  unloadingLocation: 'Sharjah',
  isActive: true,
  updatedAt: DateTime.utc(2026, 10, 19),
);

final class _FakeRepository implements RouteFinancialTermsRepository {
  final Completer<Result<RouteEntity>>? pending;
  int calls = 0;

  _FakeRepository({this.pending});

  @override
  Future<Result<RouteEntity>> setDefaultFreightRate({
    required String companyId,
    required String routeId,
    required Money rate,
    required CurrencyConfiguration financialConfiguration,
    required DateTime expectedUpdatedAt,
  }) async {
    calls += 1;
    return pending?.future ?? Success(_route);
  }
}
