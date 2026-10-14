part of 'fleet_cubit.dart';

/// Coalesces Fleet invalidations while the page is mounted. New data always
/// comes from RLS-protected Fleet use cases, never from Broadcast payloads.
mixin FleetRealtimeActions on Cubit<FleetState> {
  /// Shared by the existing document-detail refresh and Realtime invalidation.
  Future<void> refreshAssets() {
    final owner = this as FleetCubit;
    final context = owner._currentCompanyContext;
    return context == null ? Future<void>.value() : refreshFleetAssets(context);
  }

  Future<void> refreshFleetAssets(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    final owner = this as FleetCubit;
    if (!owner._isCurrentFleetContext(currentCompanyContext)) return;

    if (owner._initialLoadInProgress || owner._isRealtimeRefreshing) {
      owner._realtimeRefreshPending = true;
      return;
    }

    if (state is! FleetLoaded) {
      await owner.loadFleet(currentCompanyContext);
      return;
    }

    owner._isRealtimeRefreshing = true;
    try {
      do {
        owner._realtimeRefreshPending = false;
        await _refreshFleetOnce(currentCompanyContext);
      } while (owner._realtimeRefreshPending &&
          owner._isCurrentFleetContext(currentCompanyContext) &&
          state is FleetLoaded);
    } finally {
      owner._isRealtimeRefreshing = false;
    }
  }

  Future<void> _refreshFleetOnce(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    final owner = this as FleetCubit;
    final current = state;
    if (!owner._isCurrentFleetContext(currentCompanyContext) ||
        current is! FleetLoaded) {
      return;
    }

    final requestId = ++owner._loadRequestId;
    final params = GetFleetParams(currentCompanyContext: currentCompanyContext);
    final tractorsResult = await owner.getTractorHeadsUseCase(params);
    if (!owner._isCurrentFleetRequest(currentCompanyContext, requestId)) {
      return;
    }

    final trailersResult = await owner.getTrailersUseCase(params);
    if (!owner._isCurrentFleetRequest(currentCompanyContext, requestId)) {
      return;
    }

    final latest = state;
    if (latest is! FleetLoaded ||
        latest.currentCompanyContext.companyId !=
            currentCompanyContext.companyId) {
      return;
    }

    final failure =
        tractorsResult.failureOrNull ?? trailersResult.failureOrNull;
    if (failure != null) {
      if (failure is PermissionFailure || failure is AuthFailure) {
        ++owner._activityRequestId;
        emit(FleetFailure(failure));
      } else {
        emit(latest.copyWith(refreshFailure: failure));
      }
      return;
    }

    final tractors = tractorsResult.dataOrNull ?? const <TractorHead>[];
    final trailers = trailersResult.dataOrNull ?? const <TrailerEntity>[];
    final selectedId = latest.selectedAssetId;

    TractorHead? selectedTractor;
    TrailerEntity? selectedTrailer;
    if (selectedId != null) {
      for (final item in tractors) {
        if (item.id == selectedId) {
          selectedTractor = item;
          break;
        }
      }
      for (final item in trailers) {
        if (item.id == selectedId) {
          selectedTrailer = item;
          break;
        }
      }
    }
    final selectedRemoved =
        selectedId != null &&
        selectedTractor == null &&
        selectedTrailer == null;
    if (selectedRemoved) ++owner._activityRequestId;

    emit(
      latest.copyWith(
        allTractorHeads: tractors,
        allTrailers: trailers,
        selectedAssetId: selectedRemoved ? null : selectedId,
        selectedAssetActivity: selectedRemoved
            ? const []
            : latest.selectedAssetActivity,
        selectedAssetActivityTimestampsByLogId: selectedRemoved
            ? const {}
            : latest.selectedAssetActivityTimestampsByLogId,
        isActivityLoading: selectedRemoved ? false : latest.isActivityLoading,
        activityFailure: selectedRemoved ? null : latest.activityFailure,
        refreshFailure: null,
      ),
    );

    if (selectedTractor != null) {
      unawaited(owner.loadTractorHeadActivity(selectedTractor));
    } else if (selectedTrailer != null) {
      unawaited(owner.loadTrailerActivity(selectedTrailer));
    }
  }
}
