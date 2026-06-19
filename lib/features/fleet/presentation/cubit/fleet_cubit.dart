import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/trailer_entity.dart';
import '../../domain/entities/vehicle_status.dart';
import '../../domain/entities/vehicle_status_filter.dart';
import '../../domain/policies/fleet_permission_policy.dart';
import '../../domain/usecases/fleet_usecases.dart';
import 'fleet_state.dart';

class FleetCubit extends Cubit<FleetState> {
  final GetTractorHeadsUseCase getTractorHeadsUseCase;
  final GetTrailersUseCase getTrailersUseCase;
  final SaveTractorHeadUseCase saveTractorHeadUseCase;
  final SaveTrailerUseCase saveTrailerUseCase;

  CurrentCompanyContext? _currentCompanyContext;

  FleetCubit({
    required this.getTractorHeadsUseCase,
    required this.getTrailersUseCase,
    required this.saveTractorHeadUseCase,
    required this.saveTrailerUseCase,
  }) : super(const FleetInitial());

  Future<void> loadFleet(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final previousState = state;
    final previousSearchQuery = previousState is FleetLoaded ? previousState.searchQuery : '';
    final previousStatusFilter = previousState is FleetLoaded ? previousState.statusFilter : VehicleStatusFilter.active;
    final previousTab = previousState is FleetLoaded ? previousState.selectedTab : FleetAssetTab.tractorHeads;

    emit(const FleetLoading());

    final params = GetFleetParams(currentCompanyContext: currentCompanyContext);
    final tractorHeadsResult = await getTractorHeadsUseCase(params);
    final trailersResult = await getTrailersUseCase(params);

    final tractorHeadsFailure = tractorHeadsResult.failureOrNull;
    if (tractorHeadsFailure != null) {
      emit(FleetFailure(tractorHeadsFailure));
      return;
    }

    final trailersFailure = trailersResult.failureOrNull;
    if (trailersFailure != null) {
      emit(FleetFailure(trailersFailure));
      return;
    }

    emit(
      FleetLoaded(
        currentCompanyContext: currentCompanyContext,
        allTractorHeads: tractorHeadsResult.dataOrNull ?? const [],
        allTrailers: trailersResult.dataOrNull ?? const [],
        canManageFleet: FleetPermissionPolicy.canManageFleet(currentCompanyContext.role),
        searchQuery: previousSearchQuery,
        statusFilter: previousStatusFilter,
        selectedTab: previousTab,
      ),
    );
  }

  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is FleetLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void setStatusFilter(VehicleStatusFilter filter) {
    final currentState = state;
    if (currentState is FleetLoaded) {
      emit(currentState.copyWith(statusFilter: filter));
    }
  }

  void selectTab(FleetAssetTab tab) {
    final currentState = state;
    if (currentState is FleetLoaded) {
      emit(currentState.copyWith(selectedTab: tab, searchQuery: ''));
    }
  }

  Future<void> saveTractorHead({
    TractorHead? tractorHead,
    required String plateNumber,
    required VehicleStatus status,
    DateTime? licenseExpiryDate,
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
        notes: notes,
      ),
    );

    result.when(success: _upsertTractorHead, failure: (failure) => emit(FleetFailure(failure)));
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

    result.when(success: _upsertTrailer, failure: (failure) => emit(FleetFailure(failure)));
  }

  void _upsertTractorHead(TractorHead tractorHead) {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! FleetLoaded) {
      if (context != null) loadFleet(context);
      return;
    }

    final exists = currentState.allTractorHeads.any((item) => item.id == tractorHead.id);
    final updated = exists
        ? currentState.allTractorHeads.map((item) => item.id == tractorHead.id ? tractorHead : item).toList()
        : [tractorHead, ...currentState.allTractorHeads];
    emit(currentState.copyWith(allTractorHeads: updated));
  }

  void _upsertTrailer(TrailerEntity trailer) {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! FleetLoaded) {
      if (context != null) loadFleet(context);
      return;
    }

    final exists = currentState.allTrailers.any((item) => item.id == trailer.id);
    final updated = exists
        ? currentState.allTrailers.map((item) => item.id == trailer.id ? trailer : item).toList()
        : [trailer, ...currentState.allTrailers];
    emit(currentState.copyWith(allTrailers: updated));
  }
}
