part of 'drivers_cubit.dart';

mixin DriversFilterActions on Cubit<DriversState> {
  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is DriversLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void setStatusFilter(DriverStatusFilter statusFilter) {
    final currentState = state;
    if (currentState is DriversLoaded) {
      emit(currentState.copyWith(statusFilter: statusFilter));
    }
  }
}
