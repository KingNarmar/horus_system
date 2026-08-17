part of 'trips_cubit.dart';

mixin TripsFormLookupActions on Cubit<TripsState> {
  Future<void> loadTripFormLookups() async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded || current.isFormLookupsLoading) return;

    if (current.formLookups != null && current.formLookupsFailure == null) {
      return;
    }

    emit(
      current.copyWith(isFormLookupsLoading: true, formLookupsFailure: null),
    );

    final result = await owner.getTripFormLookupsUseCase(
      GetTripFormLookupsParams(
        currentCompanyContext: current.currentCompanyContext,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (lookups) {
        emit(
          latestState.copyWith(
            formLookups: lookups,
            isFormLookupsLoading: false,
            formLookupsFailure: null,
          ),
        );
      },
      failure: (failure) {
        emit(
          latestState.copyWith(
            isFormLookupsLoading: false,
            formLookupsFailure: failure,
          ),
        );
      },
    );
  }
}
