part of 'trips_cubit.dart';

/// Route mutations can change joined Trip route names without mutating Trips.
/// Never reset open details, filters, form inputs or financial snapshots.
mixin TripsRouteInvalidationActions on Cubit<TripsState> {
  Future<void> refreshRouteReferences() async {
    final owner = this as TripsCubit;
    await Future.wait([
      refreshTripRouteNames(),
      owner.refreshTripFormLookups(),
    ]);
  }

  Future<void> refreshTripRouteNames() async {
    final owner = this as TripsCubit;
    if (owner.isClosed || state is! TripsLoaded) {
      if (!owner.isClosed) owner._routeNamesRefreshPending = true;
      return;
    }
    if (owner._routeNamesRefreshInProgress) {
      owner._routeNamesRefreshPending = true;
      return;
    }

    owner._routeNamesRefreshInProgress = true;
    try {
      do {
        owner._routeNamesRefreshPending = false;
        await _refreshTripRouteNamesOnce();
      } while (owner._routeNamesRefreshPending &&
          !owner.isClosed &&
          state is TripsLoaded);
    } finally {
      owner._routeNamesRefreshInProgress = false;
    }
  }

  Future<void> _refreshTripRouteNamesOnce() async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded) return;
    final companyId = current.currentCompanyContext.companyId;
    final generation = owner._companyRequestGeneration;

    final result = await owner.getTripsUseCase(
      GetTripsParams(currentCompanyContext: current.currentCompanyContext),
    );
    if (owner.isClosed ||
        !owner._isCurrentLoadedCompanyRequest(generation, companyId)) {
      return;
    }

    final latest = state as TripsLoaded;
    final failure = result.failureOrNull;
    if (failure != null) {
      if (failure is AuthFailure || failure is PermissionFailure) {
        emit(TripsFailure(failure));
      } else {
        emit(latest.copyWith(routeReferenceRefreshFailure: failure));
      }
      return;
    }

    final trips = result.dataOrNull ?? const <TripEntity>[];
    final selectedTripId = latest.selectedTrip?.id;
    TripEntity? selectedTrip;
    if (selectedTripId != null) {
      for (final trip in trips) {
        if (trip.id == selectedTripId) {
          selectedTrip = trip;
          break;
        }
      }
    }

    emit(
      latest.copyWith(
        allTrips: trips,
        selectedTrip: selectedTrip ?? latest.selectedTrip,
        routeReferenceRefreshFailure: null,
      ),
    );
  }
}
