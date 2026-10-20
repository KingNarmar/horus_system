part of 'trips_cubit.dart';

/// Silent, authoritative reconciliation of Trip projections.
/// The open form owns its unsaved controllers; no incoming hint modifies them.
mixin TripsRealtimeActions on Cubit<TripsState> {
  /// Reconcile missed server changes after an offline interval. The visible
  /// Trip details dialog must retain its selected Trip and local UI state.
  Future<void> reconcileTripsAfterReconnect(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    final owner = this as TripsCubit;
    if (owner.isClosed) return;

    final current = state;
    if (current is TripsInitial || current is TripsFailure) {
      await owner.loadTrips(currentCompanyContext);
      return;
    }
    if (current is TripsLoading) {
      owner._tripsRefreshPending = true;
      return;
    }
    if (current is! TripsLoaded ||
        current.currentCompanyContext.companyId !=
            currentCompanyContext.companyId ||
        current.currentCompanyContext.role != currentCompanyContext.role) {
      return;
    }

    final generation = owner._companyRequestGeneration;
    await refreshTripsFromRealtime();

    if (!owner._isCurrentLoadedCompanyRequest(
      generation,
      currentCompanyContext.companyId,
    )) {
      return;
    }

    // A missed financial broadcast is not guaranteed to be replayed by the
    // socket. Re-read the selected Trip ledger from the server, even when
    // there was no Trip list change during the offline interval.
    final latest = state as TripsLoaded;
    if (latest.selectedTrip != null && latest.canViewTripFinancials) {
      await owner.refreshSelectedTripFinancialsFromRealtime();
    }
  }

  Future<void> refreshTripsFromRealtime() async {
    final owner = this as TripsCubit;
    if (owner.isClosed || state is! TripsLoaded) {
      if (!owner.isClosed) owner._tripsRefreshPending = true;
      return;
    }
    if (owner._tripsRefreshInProgress) {
      owner._tripsRefreshPending = true;
      return;
    }

    owner._tripsRefreshInProgress = true;
    try {
      do {
        owner._tripsRefreshPending = false;
        await _refreshTripsOnce();
      } while (owner._tripsRefreshPending &&
          !owner.isClosed &&
          state is TripsLoaded);
    } finally {
      owner._tripsRefreshInProgress = false;
    }
  }

  Future<void> _refreshTripsOnce() async {
    final owner = this as TripsCubit;
    final before = state;
    if (before is! TripsLoaded) return;
    final companyId = before.currentCompanyContext.companyId;
    final companyGeneration = owner._companyRequestGeneration;
    final mutationRevision = owner._tripMutationRevision;
    final result = await owner.getTripsUseCase(
      GetTripsParams(currentCompanyContext: before.currentCompanyContext),
    );

    if (owner.isClosed ||
        !owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId)) {
      return;
    }
    if (owner._tripMutationRevision != mutationRevision) {
      owner._tripsRefreshPending = true;
      return;
    }

    final failure = result.failureOrNull;
    if (failure != null) {
      if (failure is AuthFailure || failure is PermissionFailure) {
        emit(TripsFailure(failure));
      } else {
        emit(
          (state as TripsLoaded).copyWith(tripsRealtimeRefreshFailure: failure),
        );
      }
      return;
    }

    final trips = result.dataOrNull ?? const <TripEntity>[];
    final latest = state as TripsLoaded;
    final previousTrips = {for (final trip in latest.allTrips) trip.id: trip};
    final localTimes = <String, TripBusinessLocalTimestamps>{};
    for (final trip in trips) {
      final old = previousTrips[trip.id];
      final cached = latest.businessLocalTimestampsByTripId[trip.id];
      if (old != null &&
          cached != null &&
          old.scheduledLoadingAt == trip.scheduledLoadingAt &&
          old.scheduledDeliveryAt == trip.scheduledDeliveryAt &&
          old.actualLoadingAt == trip.actualLoadingAt &&
          old.actualDeliveryAt == trip.actualDeliveryAt) {
        localTimes[trip.id] = cached;
        continue;
      }

      final converted = await owner.getTripBusinessLocalTimestampsUseCase(
        GetTripBusinessLocalTimestampsParams(
          currentCompanyContext: before.currentCompanyContext,
          trip: trip,
        ),
      );
      if (owner.isClosed ||
          !owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId)) {
        return;
      }
      if (owner._tripMutationRevision != mutationRevision) {
        owner._tripsRefreshPending = true;
        return;
      }
      final localFailure = converted.failureOrNull;
      if (localFailure != null) {
        emit(
          (state as TripsLoaded).copyWith(
            tripsRealtimeRefreshFailure: localFailure,
          ),
        );
        return;
      }
      final timestamps = converted.dataOrNull;
      if (timestamps != null) localTimes[trip.id] = timestamps;
    }

    if (!owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId) ||
        owner._tripMutationRevision != mutationRevision) {
      owner._tripsRefreshPending = true;
      return;
    }

    final now = state as TripsLoaded;
    final selectedId = now.selectedTrip?.id;
    TripEntity? selected;
    if (selectedId != null) {
      for (final trip in trips) {
        if (trip.id == selectedId) {
          selected = trip;
          break;
        }
      }
    }

    emit(
      now.copyWith(
        allTrips: trips,
        businessLocalTimestampsByTripId: localTimes,
        selectedTrip: selected ?? now.selectedTrip,
        tripsRealtimeRefreshFailure: null,
      ),
    );

    // Status history and Audit are server-authoritative. Document and expense
    // sections remain untouched and will get their own later Realtime PRs.
    if (selected != null) {
      await Future.wait([
        owner._loadSelectedTripStatusHistory(selected),
        owner._loadSelectedTripActivity(selected),
      ]);
    }
  }
}
