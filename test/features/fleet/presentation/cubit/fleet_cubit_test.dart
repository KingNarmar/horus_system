import 'dart:async';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/fleet/domain/entities/tractor_head.dart';
import 'package:horus_system/features/fleet/domain/entities/tractor_head_write_data.dart';
import 'package:horus_system/features/fleet/domain/entities/trailer_entity.dart';
import 'package:horus_system/features/fleet/domain/entities/trailer_write_data.dart';
import 'package:horus_system/features/fleet/domain/entities/vehicle_status.dart';
import 'package:horus_system/features/fleet/domain/entities/vehicle_status_filter.dart';
import 'package:horus_system/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:horus_system/features/fleet/domain/usecases/fleet_usecases.dart';
import 'package:horus_system/features/fleet/presentation/cubit/fleet_cubit.dart';
import 'package:horus_system/features/fleet/presentation/cubit/fleet_state.dart';
import 'package:test/test.dart';

void main() {
  group('FleetCubit', () {
    test(
      'loads both asset types and uses injected manage permission use case',
      () async {
        final repository = _FakeFleetRepository();
        final cubit = _createCubit(
          repository,
          canManageFleetUseCase: const _FixedCanManageFleetUseCase(false),
        );
        addTearDown(cubit.close);

        await cubit.loadFleet(_ownerContext);

        final state = cubit.state as FleetLoaded;
        expect(repository.getTractorHeadsCalls, 1);
        expect(repository.getTrailersCalls, 1);
        expect(state.allTractorHeads, [_tractor]);
        expect(state.allTrailers, [_trailer]);
        expect(state.canManageFleet, isFalse);
      },
    );

    test('reload preserves search, status filter, and selected tab', () async {
      final repository = _FakeFleetRepository();
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadFleet(_ownerContext);
      cubit.setStatusFilter(VehicleStatusFilter.all);
      cubit.selectTab(FleetAssetTab.trailers);
      cubit.setSearchQuery('TR');

      await cubit.loadFleet(_ownerContext);

      final state = cubit.state as FleetLoaded;
      expect(state.statusFilter, VehicleStatusFilter.all);
      expect(state.selectedTab, FleetAssetTab.trailers);
      expect(state.searchQuery, 'TR');
      expect(state.canManageFleet, isTrue);
    });

    test('load failure emits FleetFailure', () async {
      const failure = UnexpectedFailure(message: 'load failed');
      final repository = _FakeFleetRepository(loadTractorHeadsFailure: failure);
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadFleet(_ownerContext);

      expect(cubit.state, isA<FleetFailure>());
      expect((cubit.state as FleetFailure).failure, same(failure));
      expect(repository.getTractorHeadsCalls, 1);
      expect(repository.getTrailersCalls, 1);
    });

    test('successful creates insert new tractor and trailer first', () async {
      final repository = _FakeFleetRepository(
        nextAddedTractor: _newTractor,
        nextAddedTrailer: _newTrailer,
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadFleet(_ownerContext);
      await cubit.saveTractorHead(
        plateNumber: _newTractor.plateNumber,
        status: _newTractor.status,
      );
      await cubit.saveTrailer(
        plateNumber: _newTrailer.plateNumber,
        status: _newTrailer.status,
      );

      final state = cubit.state as FleetLoaded;
      expect(state.allTractorHeads.map((item) => item.id), [
        _newTractor.id,
        _tractor.id,
      ]);
      expect(state.allTrailers.map((item) => item.id), [
        _newTrailer.id,
        _trailer.id,
      ]);
    });

    test('successful edits replace matching ids without duplication', () async {
      const updatedTractor = TractorHead(
        id: 'tractor-1',
        companyId: _companyId,
        plateNumber: 'T-UPDATED',
        status: VehicleStatus.maintenance,
        isActive: true,
      );
      const updatedTrailer = TrailerEntity(
        id: 'trailer-1',
        companyId: _companyId,
        plateNumber: 'TR-UPDATED',
        status: VehicleStatus.maintenance,
        isActive: true,
      );
      final repository = _FakeFleetRepository(
        nextSavedTractor: updatedTractor,
        nextSavedTrailer: updatedTrailer,
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      await cubit.loadFleet(_ownerContext);
      await cubit.saveTractorHead(
        tractorHead: _tractor,
        plateNumber: updatedTractor.plateNumber,
        status: updatedTractor.status,
      );
      await cubit.saveTrailer(
        trailer: _trailer,
        plateNumber: updatedTrailer.plateNumber,
        status: updatedTrailer.status,
      );

      final state = cubit.state as FleetLoaded;
      expect(state.allTractorHeads, hasLength(1));
      expect(state.allTractorHeads.single.plateNumber, 'T-UPDATED');
      expect(state.allTrailers, hasLength(1));
      expect(state.allTrailers.single.plateNumber, 'TR-UPDATED');
    });

    test(
      'duplicate active-state action for same id is ignored while pending',
      () async {
        final completer = Completer<Result<TractorHead>>();
        final repository = _FakeFleetRepository(
          deactivateTractorCompleter: completer,
        );
        final cubit = _createCubit(repository);
        addTearDown(cubit.close);

        await cubit.loadFleet(_ownerContext);
        final firstAction = cubit.deactivateTractorHead(_tractor);
        await Future<void>.delayed(Duration.zero);

        expect(
          (cubit.state as FleetLoaded).isActiveStateChanging(_tractor.id),
          isTrue,
        );

        await cubit.deactivateTractorHead(_tractor);
        expect(repository.deactivateTractorHeadCalls, 1);

        completer.complete(const Success<TractorHead>(_inactiveTractor));
        await firstAction;

        final state = cubit.state as FleetLoaded;
        expect(state.isActiveStateChanging(_tractor.id), isFalse);
        expect(state.allTractorHeads.single.isActive, isFalse);
      },
    );
  });
}

const _companyId = 'company-1';

const _ownerContext = CurrentCompanyContext(
  company: Company(id: _companyId, name: 'Company'),
  role: CompanyRole.owner,
);

const _tractor = TractorHead(
  id: 'tractor-1',
  companyId: _companyId,
  plateNumber: 'T-100',
  status: VehicleStatus.available,
  isActive: true,
);

const _inactiveTractor = TractorHead(
  id: 'tractor-1',
  companyId: _companyId,
  plateNumber: 'T-100',
  status: VehicleStatus.available,
  isActive: false,
);

const _newTractor = TractorHead(
  id: 'tractor-2',
  companyId: _companyId,
  plateNumber: 'T-200',
  status: VehicleStatus.available,
  isActive: true,
);

const _trailer = TrailerEntity(
  id: 'trailer-1',
  companyId: _companyId,
  plateNumber: 'TR-100',
  status: VehicleStatus.available,
  isActive: true,
);

const _newTrailer = TrailerEntity(
  id: 'trailer-2',
  companyId: _companyId,
  plateNumber: 'TR-200',
  status: VehicleStatus.available,
  isActive: true,
);

FleetCubit _createCubit(
  _FakeFleetRepository repository, {
  CanManageFleetUseCase canManageFleetUseCase = const CanManageFleetUseCase(),
}) {
  return FleetCubit(
    getTractorHeadsUseCase: GetTractorHeadsUseCase(repository),
    getTrailersUseCase: GetTrailersUseCase(repository),
    canManageFleetUseCase: canManageFleetUseCase,
    saveTractorHeadUseCase: SaveTractorHeadUseCase(repository),
    saveTrailerUseCase: SaveTrailerUseCase(repository),
    deactivateTractorHeadUseCase: DeactivateTractorHeadUseCase(repository),
    reactivateTractorHeadUseCase: ReactivateTractorHeadUseCase(repository),
    deactivateTrailerUseCase: DeactivateTrailerUseCase(repository),
    reactivateTrailerUseCase: ReactivateTrailerUseCase(repository),
    getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(
      _FakeAuditLogRepository(),
    ),
  );
}

class _FixedCanManageFleetUseCase extends CanManageFleetUseCase {
  final bool value;

  const _FixedCanManageFleetUseCase(this.value);

  @override
  Future<Result<bool>> call(CanManageFleetParams params) async {
    return Success<bool>(value);
  }
}

class _FakeFleetRepository implements FleetRepository {
  final List<TractorHead> tractorHeads = const [_tractor];
  final List<TrailerEntity> trailers = const [_trailer];
  final UnexpectedFailure? loadTractorHeadsFailure;
  final TractorHead? nextAddedTractor;
  final TractorHead? nextSavedTractor;
  final TrailerEntity? nextAddedTrailer;
  final TrailerEntity? nextSavedTrailer;
  final Completer<Result<TractorHead>>? deactivateTractorCompleter;

  int getTractorHeadsCalls = 0;
  int getTrailersCalls = 0;
  int deactivateTractorHeadCalls = 0;

  _FakeFleetRepository({
    this.loadTractorHeadsFailure,
    this.nextAddedTractor,
    this.nextSavedTractor,
    this.nextAddedTrailer,
    this.nextSavedTrailer,
    this.deactivateTractorCompleter,
  });

  @override
  Future<Result<List<TractorHead>>> getTractorHeads({
    required String companyId,
  }) async {
    getTractorHeadsCalls += 1;
    final failure = loadTractorHeadsFailure;
    if (failure != null) return FailureResult<List<TractorHead>>(failure);
    return Success<List<TractorHead>>(tractorHeads);
  }

  @override
  Future<Result<List<TrailerEntity>>> getTrailers({
    required String companyId,
  }) async {
    getTrailersCalls += 1;
    return Success<List<TrailerEntity>>(trailers);
  }

  @override
  Future<Result<TractorHead>> addTractorHead({
    required TractorHeadWriteData data,
    required String actorRole,
  }) async {
    return Success<TractorHead>(
      nextAddedTractor ??
          TractorHead(
            id: 'tractor-added',
            companyId: data.companyId,
            plateNumber: data.plateNumber,
            status: data.status,
            isActive: true,
          ),
    );
  }

  @override
  Future<Result<TractorHead>> saveTractorHead({
    required String id,
    required TractorHeadWriteData data,
    required String actorRole,
  }) async {
    return Success<TractorHead>(
      nextSavedTractor ??
          TractorHead(
            id: id,
            companyId: data.companyId,
            plateNumber: data.plateNumber,
            status: data.status,
            isActive: true,
          ),
    );
  }

  @override
  Future<Result<TractorHead>> deactivateTractorHead({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    deactivateTractorHeadCalls += 1;
    final completer = deactivateTractorCompleter;
    if (completer != null) return completer.future;
    return Future.value(const Success<TractorHead>(_inactiveTractor));
  }

  @override
  Future<Result<TractorHead>> reactivateTractorHead({
    required String companyId,
    required String id,
    required String actorRole,
  }) async {
    return const Success<TractorHead>(_tractor);
  }

  @override
  Future<Result<TrailerEntity>> addTrailer({
    required TrailerWriteData data,
    required String actorRole,
  }) async {
    return Success<TrailerEntity>(
      nextAddedTrailer ??
          TrailerEntity(
            id: 'trailer-added',
            companyId: data.companyId,
            plateNumber: data.plateNumber,
            status: data.status,
            isActive: true,
          ),
    );
  }

  @override
  Future<Result<TrailerEntity>> editTrailer({
    required String id,
    required TrailerWriteData data,
    required String actorRole,
  }) async {
    return Success<TrailerEntity>(
      nextSavedTrailer ??
          TrailerEntity(
            id: id,
            companyId: data.companyId,
            plateNumber: data.plateNumber,
            status: data.status,
            isActive: true,
          ),
    );
  }

  @override
  Future<Result<TrailerEntity>> deactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  }) async {
    return Success<TrailerEntity>(
      TrailerEntity(
        id: id,
        companyId: companyId,
        plateNumber: _trailer.plateNumber,
        status: _trailer.status,
        isActive: false,
      ),
    );
  }

  @override
  Future<Result<TrailerEntity>> reactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  }) async {
    return const Success<TrailerEntity>(_trailer);
  }
}

class _FakeAuditLogRepository implements AuditLogRepository {
  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
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
