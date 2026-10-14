import 'dart:async';

import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/fleet/domain/entities/tractor_head.dart';
import 'package:horus_system/features/fleet/domain/entities/trailer_entity.dart';
import 'package:horus_system/features/fleet/domain/entities/vehicle_status.dart';
import 'package:horus_system/features/fleet/domain/entities/vehicle_status_filter.dart';
import 'package:horus_system/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:horus_system/features/fleet/domain/usecases/fleet_usecases.dart';
import 'package:horus_system/features/fleet/presentation/cubit/fleet_cubit.dart';
import 'package:horus_system/features/fleet/presentation/cubit/fleet_state.dart';
import 'package:test/test.dart';

import '../../../../helpers/fake_business_time_zone_converter.dart';

void main() {
  test(
    'coalesces hints and keeps filters, tab and latest Fleet rows',
    () async {
      final repository = _QueuedFleetRepository();
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final initial = cubit.loadFleet(_companyA);
      repository.completeTractors(0, [_tractor('a', 'T-100')]);
      await Future<void>.delayed(Duration.zero);
      repository.completeTrailers(0, [_trailer('a', 'TR-100')]);
      await initial;

      cubit.setStatusFilter(VehicleStatusFilter.all);
      cubit.selectTab(FleetAssetTab.trailers);
      cubit.setSearchQuery('NEW');

      final refresh = cubit.refreshFleetAssets(_companyA);
      final duplicateHint = cubit.refreshFleetAssets(_companyA);
      expect(repository.tractorRequests, ['company-a', 'company-a']);

      repository.completeTractors(1, [_tractor('a', 'T-OLD')]);
      await Future<void>.delayed(Duration.zero);
      repository.completeTrailers(1, [_trailer('a', 'TR-OLD')]);
      await Future<void>.delayed(Duration.zero);
      expect(repository.tractorRequests, [
        'company-a',
        'company-a',
        'company-a',
      ]);

      repository.completeTractors(2, [_tractor('a', 'T-NEW')]);
      await Future<void>.delayed(Duration.zero);
      repository.completeTrailers(2, [_trailer('a', 'TR-NEW')]);
      await refresh;
      await duplicateHint;

      final state = cubit.state as FleetLoaded;
      expect(state.searchQuery, 'NEW');
      expect(state.statusFilter, VehicleStatusFilter.all);
      expect(state.selectedTab, FleetAssetTab.trailers);
      expect(state.allTractorHeads.single.plateNumber, 'T-NEW');
      expect(state.allTrailers.single.plateNumber, 'TR-NEW');
      expect(state.trailers.single.plateNumber, 'TR-NEW');
    },
  );

  test('late tenant-A loads never overwrite tenant-B data', () async {
    final repository = _QueuedFleetRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    final first = cubit.loadFleet(_companyA);
    final next = cubit.loadFleet(_companyB);
    repository.completeTractors(1, [
      _tractor('b', 'B-HEAD', companyId: 'company-b'),
    ]);
    await Future<void>.delayed(Duration.zero);
    repository.completeTrailers(0, [
      _trailer('b', 'B-TRAILER', companyId: 'company-b'),
    ]);
    await next;
    repository.completeTractors(0, [_tractor('a', 'A-OLD')]);
    await first;

    final state = cubit.state as FleetLoaded;
    expect(state.currentCompanyContext.companyId, 'company-b');
    expect(state.allTractorHeads.single.companyId, 'company-b');
    expect(state.allTrailers.single.companyId, 'company-b');
    expect(repository.trailerRequests, ['company-b']);
  });

  test('permission revocation hides previously loaded Fleet lists', () async {
    final repository = _QueuedFleetRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    final initial = cubit.loadFleet(_companyA);
    repository.completeTractors(0, [_tractor('a', 'T-100')]);
    await Future<void>.delayed(Duration.zero);
    repository.completeTrailers(0, [_trailer('a', 'TR-100')]);
    await initial;

    final refresh = cubit.refreshFleetAssets(_companyA);
    repository.completeTractorsResult(
      1,
      const FailureResult<List<TractorHead>>(
        PermissionFailure(code: FailureCodes.permissionFleetView),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    repository.completeTrailers(1, []);
    await refresh;
    expect(cubit.state, isA<FleetFailure>());
  });

  test(
    'temporary refresh failure keeps Fleet list and typed failure',
    () async {
      final repository = _QueuedFleetRepository();
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final initial = cubit.loadFleet(_companyA);
      repository.completeTractors(0, [_tractor('a', 'T-100')]);
      await Future<void>.delayed(Duration.zero);
      repository.completeTrailers(0, [_trailer('a', 'TR-100')]);
      await initial;

      final refresh = cubit.refreshFleetAssets(_companyA);
      repository.completeTractorsResult(
        1,
        const FailureResult<List<TractorHead>>(
          NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      repository.completeTrailers(1, []);
      await refresh;

      final state = cubit.state as FleetLoaded;
      expect(state.allTractorHeads.single.plateNumber, 'T-100');
      expect(state.allTrailers.single.plateNumber, 'TR-100');
      expect(
        state.refreshFailure?.code,
        FailureCodes.realtimeSubscriptionUnavailable,
      );
    },
  );

  test('disposed Cubit rejects a late initial Fleet result', () async {
    final repository = _QueuedFleetRepository();
    final cubit = _createCubit(repository);
    final loading = cubit.loadFleet(_companyA);
    await cubit.close();
    repository.completeTractors(0, [_tractor('a', 'T-100')]);
    await loading;
    expect(cubit.isClosed, isTrue);
    expect(repository.trailerRequests, isEmpty);
  });
}

const _companyA = CurrentCompanyContext(
  company: Company(id: 'company-a', name: 'A'),
  role: CompanyRole.owner,
);
const _companyB = CurrentCompanyContext(
  company: Company(id: 'company-b', name: 'B'),
  role: CompanyRole.owner,
);

TractorHead _tractor(
  String id,
  String plate, {
  String companyId = 'company-a',
}) => TractorHead(
  id: id,
  companyId: companyId,
  plateNumber: plate,
  status: VehicleStatus.available,
  isActive: true,
);

TrailerEntity _trailer(
  String id,
  String plate, {
  String companyId = 'company-a',
}) => TrailerEntity(
  id: id,
  companyId: companyId,
  plateNumber: plate,
  status: VehicleStatus.available,
  isActive: true,
);

FleetCubit _createCubit(_QueuedFleetRepository repository) => FleetCubit(
  getTractorHeadsUseCase: GetTractorHeadsUseCase(repository),
  getTrailersUseCase: GetTrailersUseCase(repository),
  canManageFleetUseCase: const CanManageFleetUseCase(),
  saveTractorHeadUseCase: SaveTractorHeadUseCase(repository),
  saveTrailerUseCase: SaveTrailerUseCase(repository),
  deactivateTractorHeadUseCase: DeactivateTractorHeadUseCase(repository),
  reactivateTractorHeadUseCase: ReactivateTractorHeadUseCase(repository),
  deactivateTrailerUseCase: DeactivateTrailerUseCase(repository),
  reactivateTrailerUseCase: ReactivateTrailerUseCase(repository),
  getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(
    _UnusedAuditRepository(),
  ),
  convertInstantsToBusinessLocalDateTimesUseCase:
      const ConvertInstantsToBusinessLocalDateTimesUseCase(
        FakeBusinessTimeZoneConverter(),
      ),
  getCompanyBusinessDateUseCase: GetCompanyBusinessDateUseCase(
    _UnusedDateProvider(),
  ),
);

final class _QueuedFleetRepository implements FleetRepository {
  final List<String> tractorRequests = [];
  final List<String> trailerRequests = [];
  final List<Completer<Result<List<TractorHead>>>> _tractorCompleters = [];
  final List<Completer<Result<List<TrailerEntity>>>> _trailerCompleters = [];

  @override
  Future<Result<List<TractorHead>>> getTractorHeads({
    required String companyId,
  }) {
    tractorRequests.add(companyId);
    final completer = Completer<Result<List<TractorHead>>>();
    _tractorCompleters.add(completer);
    return completer.future;
  }

  @override
  Future<Result<List<TrailerEntity>>> getTrailers({required String companyId}) {
    trailerRequests.add(companyId);
    final completer = Completer<Result<List<TrailerEntity>>>();
    _trailerCompleters.add(completer);
    return completer.future;
  }

  void completeTractors(int index, List<TractorHead> assets) =>
      completeTractorsResult(index, Success(assets));

  void completeTractorsResult(int index, Result<List<TractorHead>> result) =>
      _tractorCompleters[index].complete(result);

  void completeTrailers(int index, List<TrailerEntity> assets) =>
      _trailerCompleters[index].complete(Success(assets));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedAuditRepository implements AuditLogRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedDateProvider implements CompanyBusinessDateProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
