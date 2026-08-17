part of 'trips_cubit.dart';

mixin TripsFilterActions on Cubit<TripsState> {
  void setSearchQuery(String query) {
    final owner = this as TripsCubit;
    owner._mapLoaded((state) => state.copyWith(searchQuery: query));
  }

  void setStatusFilter(TripStatusFilter filter) {
    final owner = this as TripsCubit;
    owner._mapLoaded((state) => state.copyWith(statusFilter: filter));
  }
}
