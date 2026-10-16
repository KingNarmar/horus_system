import 'dart:async';

import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/routes/domain/entities/route_entity.dart';
import 'package:horus_system/features/routes/domain/entities/route_status_filter.dart';
import 'package:horus_system/features/routes/domain/entities/route_write_data.dart';
import 'package:horus_system/features/routes/domain/repositories/routes_repository.dart';
import 'package:horus_system/features/routes/domain/usecases/can_manage_routes_usecase.dart';
import 'package:horus_system/features/routes/domain/usecases/routes_usecases.dart';
import 'package:horus_system/features/routes/presentation/cubit/routes_cubit.dart';
import 'package:horus_system/features/routes/presentation/cubit/routes_state.dart';
import 'package:test/test.dart';

import '../../../../helpers/activity_projection_fakes.dart';

void main() {
  late _DeferredRoutesRepository routes;
  late RoutesCubit cubit;

  setUp(() {
    routes = _DeferredRoutesRepository();
    cubit = RoutesCubit(
      getRoutesUseCase: GetRoutesUseCase(routes),
      canManageRoutesUseCase: const CanManageRoutesUseCase(),
      saveRouteUseCase: SaveRouteUseCase(routes),
      deactivateRouteUseCase: DeactivateRouteUseCase(routes),
      reactivateRouteUseCase: ReactivateRouteUseCase(routes),
      getRouteAuditLogsUseCase: GetEntityAuditLogsUseCase(
        DeferredActivityRepository(),
      ),
      convertInstantsToBusinessLocalDateTimesUseCase:
          ConvertInstantsToBusinessLocalDateTimesUseCase(
            RecordingActivityConverter(),
          ),
    );
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test('coalesces consecutive live hints while retaining filters', () async {
    final initial = cubit.loadRoutes(_company('company-a'));
    routes.complete(0, const Success([_original]));
    await initial;

    cubit.setSearchQuery('Dubai');
    cubit.setStatusFilter(RouteStatusFilter.all);

    final refresh = cubit.refreshRoutes(_company('company-a'));
    final pending = cubit.refreshRoutes(_company('company-a'));
    expect(routes.requests, hasLength(2));
    expect(cubit.state, isA<RoutesLoaded>());

    routes.complete(1, const Success([_updated]));
    await Future<void>.delayed(Duration.zero);
    expect(routes.requests, hasLength(3));

    routes.complete(2, const Success([_updated]));
    await Future.wait([refresh, pending]);

    final state = cubit.state as RoutesLoaded;
    expect(state.allRoutes.single.loadingLocation, 'Dubai Updated');
    expect(state.searchQuery, 'Dubai');
    expect(state.statusFilter, RouteStatusFilter.all);
    expect(state.refreshFailure, isNull);
  });

  test('transient failure preserves authoritative last-good page', () async {
    final initial = cubit.loadRoutes(_company('company-a'));
    routes.complete(0, const Success([_original]));
    await initial;

    final refresh = cubit.refreshRoutes(_company('company-a'));
    routes.complete(
      1,
      const FailureResult(
        NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
      ),
    );
    await refresh;

    final state = cubit.state as RoutesLoaded;
    expect(state.allRoutes.single.loadingLocation, 'Dubai');
    expect(
      state.refreshFailure?.code,
      FailureCodes.realtimeSubscriptionUnavailable,
    );
  });

  test(
    'late request from another company never replaces tenant state',
    () async {
      final first = cubit.loadRoutes(_company('company-a'));
      final second = cubit.loadRoutes(_company('company-b'));

      routes.complete(1, const Success([_foreign]));
      await second;
      routes.complete(0, const Success([_original]));
      await first;

      final state = cubit.state as RoutesLoaded;
      expect(state.currentCompanyContext.companyId, 'company-b');
      expect(state.allRoutes.single.companyId, 'company-b');
    },
  );
}

const _original = RouteEntity(
  id: 'route-1',
  companyId: 'company-a',
  loadingLocation: 'Dubai',
  unloadingLocation: 'Sharjah',
  isActive: true,
);

const _updated = RouteEntity(
  id: 'route-1',
  companyId: 'company-a',
  loadingLocation: 'Dubai Updated',
  unloadingLocation: 'Sharjah',
  isActive: true,
);

const _foreign = RouteEntity(
  id: 'route-2',
  companyId: 'company-b',
  loadingLocation: 'Fujairah',
  unloadingLocation: 'Abu Dhabi',
  isActive: true,
);

CurrentCompanyContext _company(String id) => CurrentCompanyContext(
  company: Company(id: id, name: 'Company'),
  role: CompanyRole.owner,
);

final class _DeferredRoutesRepository implements RoutesRepository {
  final requests = <Completer<Result<List<RouteEntity>>>>[];

  @override
  Future<Result<List<RouteEntity>>> getRoutes({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    final pending = Completer<Result<List<RouteEntity>>>();
    requests.add(pending);
    return pending.future;
  }

  void complete(int index, Result<List<RouteEntity>> result) {
    requests[index].complete(result);
  }

  @override
  Future<Result<RouteEntity>> addRoute({
    required RouteWriteData data,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) => throw UnimplementedError();

  @override
  Future<Result<RouteEntity>> saveRoute({
    required String id,
    required RouteWriteData data,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) => throw UnimplementedError();

  @override
  Future<Result<RouteEntity>> deactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) => throw UnimplementedError();

  @override
  Future<Result<RouteEntity>> reactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) => throw UnimplementedError();
}
