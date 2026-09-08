import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/routes/domain/entities/route_entity.dart';
import 'package:horus_system/features/routes/domain/entities/route_write_data.dart';
import 'package:horus_system/features/routes/domain/repositories/routes_repository.dart';
import 'package:horus_system/features/routes/domain/usecases/routes_usecases.dart';
import 'package:horus_system/features/routes/presentation/cubit/routes_cubit.dart';
import 'package:horus_system/features/routes/presentation/cubit/routes_state.dart';
import 'package:test/test.dart';

import '../../../../helpers/activity_projection_fakes.dart';

void main() {
  late DeferredActivityRepository audit;
  late RecordingActivityConverter converter;
  late RoutesCubit cubit;
  setUp(() {
    audit = DeferredActivityRepository();
    converter = RecordingActivityConverter();
    final repository = _Repository();
    cubit = RoutesCubit(
      getRoutesUseCase: GetRoutesUseCase(repository),
      saveRouteUseCase: SaveRouteUseCase(repository),
      deactivateRouteUseCase: DeactivateRouteUseCase(repository),
      reactivateRouteUseCase: ReactivateRouteUseCase(repository),
      getRouteAuditLogsUseCase: GetEntityAuditLogsUseCase(audit),
      convertInstantsToBusinessLocalDateTimesUseCase:
          ConvertInstantsToBusinessLocalDateTimesUseCase(converter),
    );
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  test(
    'projects scoped audit timestamps across midnight in company timezone',
    () async {
      await cubit.loadRoutes(_context());
      final pending = cubit.loadRouteActivity(_entity());
      audit.requests.single.complete(Success([_log()]));
      await pending;
      final state = cubit.state as RoutesLoaded;
      expect(
        state.activityTimestampFor('log-1'),
        BusinessLocalDateTime(
          year: 2026,
          month: 9,
          day: 7,
          hour: 0,
          minute: 30,
        ),
      );
      expect(
        state.selectedRouteActivity.single.createdAt,
        DateTime.utc(2026, 9, 6, 20, 30),
      );
      expect(converter.timeZoneIds, ['Asia/Dubai']);
      expect(audit.companyIds, ['company-1']);
      expect(audit.modules, [AuditModule.routes]);
      expect(audit.entityTypes, [AuditEntityType.route]);
      expect(audit.entityIds, ['entity-1']);
      expect(state.isActivityLoading, isFalse);
      expect(
        state.copyWith(searchQuery: 'query').activityTimestampFor('log-1'),
        state.activityTimestampFor('log-1'),
      );
      cubit.clearRouteActivity();
      expect(
        (cubit.state as RoutesLoaded).activityTimestampFor('log-1'),
        isNull,
      );
    },
  );

  test(
    'projection failure exposes typed failure without raw activity',
    () async {
      converter.failure = const ServerFailure(code: FailureCodes.serverError);
      await cubit.loadRoutes(_context());
      final pending = cubit.loadRouteActivity(_entity());
      audit.requests.single.complete(Success([_log()]));
      await pending;
      final state = cubit.state as RoutesLoaded;
      expect(state.activityFailure?.code, FailureCodes.serverError);
      expect(state.selectedRouteActivity, isEmpty);
      expect(state.activityTimestampFor('log-1'), isNull);
      expect(state.isActivityLoading, isFalse);
    },
  );

  test(
    'ignores old activity after a company switch even with the same entity id',
    () async {
      await cubit.loadRoutes(_context());
      final old = cubit.loadRouteActivity(_entity());
      await cubit.loadRoutes(_context(companyId: 'company-2', timezone: 'UTC'));
      final current = cubit.loadRouteActivity(_entity(companyId: 'company-2'));
      audit.requests[1].complete(Success([_log(companyId: 'company-2')]));
      await current;
      audit.requests[0].complete(Success([_log()]));
      await old;
      final state = cubit.state as RoutesLoaded;
      expect(state.selectedRouteActivity.single.companyId, 'company-2');
      expect(
        state.activityTimestampFor('log-1'),
        BusinessLocalDateTime(
          year: 2026,
          month: 9,
          day: 6,
          hour: 20,
          minute: 30,
        ),
      );
      expect(converter.timeZoneIds, ['UTC']);
    },
  );

  test(
    'latest activity request wins when replies arrive out of order',
    () async {
      await cubit.loadRoutes(_context());
      final old = cubit.loadRouteActivity(_entity());
      final current = cubit.loadRouteActivity(_entity());
      audit.requests[1].complete(Success([_log(id: 'new')]));
      await current;
      audit.requests[0].complete(Success([_log(id: 'old')]));
      await old;
      expect(
        (cubit.state as RoutesLoaded).selectedRouteActivity.single.id,
        'new',
      );
    },
  );

  test('closing details ignores a pending audit result', () async {
    await cubit.loadRoutes(_context());
    final pending = cubit.loadRouteActivity(_entity());
    cubit.clearRouteActivity();
    audit.requests.single.complete(Success([_log()]));
    await pending;
    expect((cubit.state as RoutesLoaded).selectedRoute, isNull);
    expect(converter.timeZoneIds, isEmpty);
  });

  test(
    'audit failure retains its typed code without invoking conversion',
    () async {
      await cubit.loadRoutes(_context());
      final pending = cubit.loadRouteActivity(_entity());
      audit.requests.single.complete(
        const FailureResult(ServerFailure(code: FailureCodes.serverError)),
      );
      await pending;
      final state = cubit.state as RoutesLoaded;
      expect(state.activityFailure?.code, FailureCodes.serverError);
      expect(state.isActivityLoading, isFalse);
      expect(converter.timeZoneIds, isEmpty);
    },
  );

  test('foreign-company entity does not initiate an audit read', () async {
    await cubit.loadRoutes(_context());
    await cubit.loadRouteActivity(_entity(companyId: 'company-2'));
    expect(audit.requests, isEmpty);
  });

  test(
    'closing details during projection does not restore the old selection',
    () async {
      await cubit.loadRoutes(_context());
      converter.onConvert = cubit.clearRouteActivity;
      final pending = cubit.loadRouteActivity(_entity());
      audit.requests.single.complete(Success([_log()]));
      await pending;
      final state = cubit.state as RoutesLoaded;
      expect(state.selectedRoute, isNull);
      expect(state.activityTimestampFor('log-1'), isNull);
    },
  );

  test('closing cubit ignores a pending audit result', () async {
    await cubit.loadRoutes(_context());
    final pending = cubit.loadRouteActivity(_entity());
    await cubit.close();
    audit.requests.single.complete(Success([_log()]));
    await pending;
    expect(converter.timeZoneIds, isEmpty);
  });
}

CurrentCompanyContext _context({
  String companyId = 'company-1',
  String timezone = 'Asia/Dubai',
}) => CurrentCompanyContext(
  company: Company(id: companyId, name: 'Company', businessTimezone: timezone),
  role: CompanyRole.owner,
);
RouteEntity _entity({String companyId = 'company-1'}) => RouteEntity(
  id: 'entity-1',
  companyId: companyId,
  loadingLocation: 'Dubai',
  unloadingLocation: 'Sharjah',
  isActive: true,
);
AuditLog _log({String companyId = 'company-1', String id = 'log-1'}) =>
    AuditLog(
      id: id,
      companyId: companyId,
      module: AuditModule.routes,
      entityType: AuditEntityType.route,
      entityId: 'entity-1',
      action: AuditAction.created,
      description: 'Created',
      createdAt: DateTime.utc(2026, 9, 6, 20, 30),
    );

final class _Repository implements RoutesRepository {
  @override
  Future<Result<List<RouteEntity>>> getRoutes({
    required String companyId,
  }) async => const Success([]);

  @override
  Future<Result<RouteEntity>> addRoute({
    required RouteWriteData data,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<RouteEntity>> saveRoute({
    required String id,
    required RouteWriteData data,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<RouteEntity>> deactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<RouteEntity>> reactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
  }) => throw UnimplementedError();
}
