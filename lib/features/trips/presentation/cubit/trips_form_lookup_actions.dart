part of 'trips_cubit.dart';

mixin TripsFormLookupActions on Cubit<TripsState> {
  Future<void> loadTripFormLookups() async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded || current.isFormLookupsLoading) return;

    if (current.formLookups != null && current.formLookupsFailure == null) {
      return;
    }

    final companyGeneration = owner._companyRequestGeneration;
    final companyId = current.currentCompanyContext.companyId;

    emit(
      current.copyWith(isFormLookupsLoading: true, formLookupsFailure: null),
    );

    final result = await owner.getTripFormLookupsUseCase(
      GetTripFormLookupsParams(
        currentCompanyContext: current.currentCompanyContext,
      ),
    );

    if (!owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId)) {
      return;
    }

    final latestState = state as TripsLoaded;
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
