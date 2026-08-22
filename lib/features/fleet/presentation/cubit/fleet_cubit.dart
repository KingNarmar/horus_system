import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/trailer_entity.dart';
import '../../domain/entities/vehicle_status.dart';
import '../../domain/entities/vehicle_status_filter.dart';
import '../../domain/usecases/fleet_usecases.dart';
import 'fleet_state.dart';

class FleetCubit extends Cubit<FleetState> {
  final GetTractorHeadsUseCase getTractorHeadsUseCase;
  final GetTrailersUseCase getTrailersUseCase;
  final CanManageFleetUseCase canManageFleetUseCase;
  final SaveTractorHeadUseCase saveTractorHeadUseCase;
  final SaveTrailerUseCase saveTrailerUseCase;
  final DeactivateTractorHeadUseCase deactivateTractorHeadUseCase;
  final ReactivateTractorHeadUseCase reactivateTractorHeadUseCase;
  final DeactivateTrailerUseCase deactivateTrailerUseCase;
  final ReactivateTrailerUseCase reactivateTrailerUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;
  CurrentCompanyContext? _currentCompanyContext;

  FleetCubit({
    required this.getTractorHeadsUseCase,
    required this.getTrailersUseCase,
    required this.canManageFleetUseCase,
    required this.saveTractorHeadUseCase,
    required this.saveTrailerUseCase,
    required this.deactivateTractorHeadUseCase,
    required this.reactivateTractorHeadUseCase,
    required this.deactivateTrailerUseCase,
    required this.reactivateTrailerUseCase,
    required this.getEntityAuditLogsUseCase,
  }) : super(const FleetInitial());

  Future<void> loadFleet(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final previous = state;
    final query = previous is FleetLoaded ? previous.searchQuery : '';
    final filter = previous is FleetLoaded
        ? previous.statusFilter
        : VehicleStatusFilter.active;
    final tab = previous is FleetLoaded
        ? previous.selectedTab
        : FleetAssetTab.tractorHeads;
    emit(const FleetLoading());
    final params = GetFleetParams(currentCompanyContext: currentCompanyContext);
    final tractorHeadsResult = await getTractorHeadsUseCase(params);
    final trailersResult = await getTrailersUseCase(params);
    final failure =
        tractorHeadsResult.failureOrNull ?? trailersResult.failureOrNull;
    if (failure != null) {
      emit(FleetFailure(failure));
      return;
    }

    final manageResult = await canManageFleetUseCase(
      CanManageFleetParams(currentCompanyContext: currentCompanyContext),
    );
    final manageFailure = manageResult.failureOrNull;
    if (manageFailure != null) {
      emit(FleetFailure(manageFailure));
      return;
    }

    emit(
      FleetLoaded(
        currentCompanyContext: currentCompanyContext,
        allTractorHeads: tractorHeadsResult.dataOrNull ?? const [],
        allTrailers: trailersResult.dataOrNull ?? const [],
        canManageFleet: manageResult.dataOrNull ?? false,
        searchQuery: query,
        statusFilter: filter,
        selectedTab: tab,
      ),
    );
  }

  void setSearchQuery(String query) =>
      _mapLoaded((s) => s.copyWith(searchQuery: query));
  void setStatusFilter(VehicleStatusFilter filter) =>
      _mapLoaded((s) => s.copyWith(statusFilter: filter));
  void selectTab(FleetAssetTab tab) =>
      _mapLoaded((s) => s.copyWith(selectedTab: tab, searchQuery: ''));

  Future<void> loadTractorHeadActivity(TractorHead item) =>
      _loadActivity(item.id, AuditEntityType.tractorHead);
  Future<void> loadTrailerActivity(TrailerEntity item) =>
      _loadActivity(item.id, AuditEntityType.trailer);

  Future<void> _loadActivity(String assetId, AuditEntityType entityType) async {
    final context = _currentCompanyContext;
    final current = state;
    if (context == null || current is! FleetLoaded) return;
    emit(
      current.copyWith(
        selectedAssetId: assetId,
        selectedAssetActivity: const [],
        isActivityLoading: true,
        activityFailure: null,
      ),
    );
    final result = await getEntityAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: context.companyId,
        module: AuditModule.fleet,
        entityType: entityType,
        entityId: assetId,
      ),
    );
    final latest = state;
    if (latest is! FleetLoaded || latest.selectedAssetId != assetId) return;
    result.when(
      success: (activity) => emit(
        latest.copyWith(
          selectedAssetActivity: activity,
          isActivityLoading: false,
          activityFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latest.copyWith(isActivityLoading: false, activityFailure: failure),
      ),
    );
  }

  void clearFleetAssetActivity() => _mapLoaded(
    (s) => s.copyWith(
      selectedAssetId: null,
      selectedAssetActivity: const [],
      isActivityLoading: false,
      activityFailure: null,
    ),
  );

  Future<void> saveTractorHead({
    TractorHead? tractorHead,
    required String plateNumber,
    required VehicleStatus status,
    DateTime? licenseExpiryDate,
    double? expectedFuelConsumption,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) return;
    final result = await saveTractorHeadUseCase(
      SaveTractorHeadParams(
        currentCompanyContext: context,
        id: tractorHead?.id,
        plateNumber: plateNumber,
        status: status,
        licenseExpiryDate: licenseExpiryDate,
        expectedFuelConsumption: expectedFuelConsumption,
        notes: notes,
      ),
    );
    result.when(
      success: _upsertTractorHead,
      failure: (failure) => emit(FleetFailure(failure)),
    );
  }

  Future<void> saveTrailer({
    TrailerEntity? trailer,
    required String plateNumber,
    required VehicleStatus status,
    DateTime? licenseExpiryDate,
    String? technicalNotes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) return;
    final result = await saveTrailerUseCase(
      SaveTrailerParams(
        currentCompanyContext: context,
        id: trailer?.id,
        plateNumber: plateNumber,
        status: status,
        licenseExpiryDate: licenseExpiryDate,
        technicalNotes: technicalNotes,
      ),
    );
    result.when(
      success: _upsertTrailer,
      failure: (failure) => emit(FleetFailure(failure)),
    );
  }

  Future<void> deactivateTractorHead(TractorHead item) =>
      _changeTractorHeadActiveState(item.id, deactivateTractorHeadUseCase.call);
  Future<void> reactivateTractorHead(TractorHead item) =>
      _changeTractorHeadActiveState(item.id, reactivateTractorHeadUseCase.call);
  Future<void> deactivateTrailer(TrailerEntity item) =>
      _changeTrailerActiveState(item.id, deactivateTrailerUseCase.call);
  Future<void> reactivateTrailer(TrailerEntity item) =>
      _changeTrailerActiveState(item.id, reactivateTrailerUseCase.call);

  Future<void> _changeTractorHeadActiveState(
    String id,
    Future<Result<TractorHead>> Function(FleetAssetStatusParams params) useCase,
  ) async {
    final context = _currentCompanyContext;
    if (context == null || _isAssetActionRunning(id)) return;
    _setAssetActionRunning(id, true);
    final result = await useCase(
      FleetAssetStatusParams(currentCompanyContext: context, id: id),
    );
    _setAssetActionRunning(id, false);
    result.when(
      success: _upsertTractorHead,
      failure: (failure) => emit(FleetFailure(failure)),
    );
  }

  Future<void> _changeTrailerActiveState(
    String id,
    Future<Result<TrailerEntity>> Function(FleetAssetStatusParams params)
    useCase,
  ) async {
    final context = _currentCompanyContext;
    if (context == null || _isAssetActionRunning(id)) return;
    _setAssetActionRunning(id, true);
    final result = await useCase(
      FleetAssetStatusParams(currentCompanyContext: context, id: id),
    );
    _setAssetActionRunning(id, false);
    result.when(
      success: _upsertTrailer,
      failure: (failure) => emit(FleetFailure(failure)),
    );
  }

  void _upsertTractorHead(TractorHead item) => _mapLoaded(
    (s) => s.copyWith(
      allTractorHeads: _upsertById(
        s.allTractorHeads,
        item,
        (current) => current.id,
      ),
    ),
  );

  void _upsertTrailer(TrailerEntity item) => _mapLoaded(
    (s) => s.copyWith(
      allTrailers: _upsertById(s.allTrailers, item, (current) => current.id),
    ),
  );

  bool _isAssetActionRunning(String id) =>
      state is FleetLoaded && (state as FleetLoaded).isActiveStateChanging(id);

  void _setAssetActionRunning(String id, bool isRunning) {
    _mapLoaded((s) {
      final ids = {...s.activeStateChangingAssetIds};
      isRunning ? ids.add(id) : ids.remove(id);
      return s.copyWith(activeStateChangingAssetIds: ids);
    });
  }

  void _mapLoaded(FleetLoaded Function(FleetLoaded state) mapper) {
    final current = state;
    if (current is FleetLoaded) emit(mapper(current));
  }
}

List<T> _upsertById<T>(List<T> items, T next, String Function(T item) idOf) {
  final nextId = idOf(next);
  final exists = items.any((item) => idOf(item) == nextId);
  if (!exists) return [next, ...items];
  return items.map((item) => idOf(item) == nextId ? next : item).toList();
}
