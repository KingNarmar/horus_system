part of 'trips_cubit.dart';

mixin TripsFormLookupActions on Cubit<TripsState> {
  Future<void> loadTripFormLookups() async {
    final current = state;
    if (current is! TripsLoaded) return;
    if (current.formLookups != null && current.formLookupsFailure == null) {
      return;
    }
    await refreshTripFormLookups();
  }

  /// Refreshes only the form lookups. Keep the open form and its typed values.
  Future<void> refreshTripFormLookups() async {
    final owner = this as TripsCubit;
    if (owner.isClosed || state is! TripsLoaded) {
      if (!owner.isClosed) owner._lookupsRefreshPending = true;
      return;
    }
    if (owner._lookupsRefreshInProgress) {
      owner._lookupsRefreshPending = true;
      return;
    }

    owner._lookupsRefreshInProgress = true;
    try {
      do {
        owner._lookupsRefreshPending = false;
        await _refreshTripFormLookupsOnce();
      } while (owner._lookupsRefreshPending &&
          !owner.isClosed &&
          state is TripsLoaded);
    } finally {
      owner._lookupsRefreshInProgress = false;
    }
  }

  Future<void> _refreshTripFormLookupsOnce() async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded) return;

    final generation = owner._companyRequestGeneration;
    final companyId = current.currentCompanyContext.companyId;
    if (current.formLookups == null) {
      emit(current.copyWith(isFormLookupsLoading: true, formLookupsFailure: null));
    }

    final result = await owner.getTripFormLookupsUseCase(
      GetTripFormLookupsParams(
        currentCompanyContext: current.currentCompanyContext,
      ),
    );

    if (owner.isClosed ||
        !owner._isCurrentLoadedCompanyRequest(generation, companyId)) {
      return;
    }

    final latest = state as TripsLoaded;
    result.when(
      success: (lookups) {
        emit(
          latest.copyWith(
            formLookups: lookups,
            isFormLookupsLoading: false,
            formLookupsFailure: null,
          ),
        );
      },
      failure: (failure) {
        emit(
          latest.copyWith(
            isFormLookupsLoading: false,
            formLookupsFailure: failure,
          ),
        );
      },
    );
  }
}
