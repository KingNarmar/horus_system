part of 'driver_settlements_cubit.dart';

extension DriverSettlementsFilterActions on DriverSettlementsCubit {
  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is DriverSettlementsLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void setDriverFilter(String? driverId) {
    final currentState = state;
    if (currentState is DriverSettlementsLoaded) {
      emit(currentState.copyWith(driverIdFilter: driverId));
    }
  }

  void setStatusFilter(DriverSettlementStatus? status) {
    final currentState = state;
    if (currentState is DriverSettlementsLoaded) {
      emit(currentState.copyWith(statusFilter: status));
    }
  }

  Future<void> setIncludeVoided(bool includeVoided) async {
    final currentState = state;
    if (currentState is! DriverSettlementsLoaded) return;
    emit(
      currentState.copyWith(
        includeVoided: includeVoided,
        mutationFailure: null,
        feedback: null,
      ),
    );
    await _reloadSettlements();
  }

  Future<void> _reloadSettlements() async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! DriverSettlementsLoaded || context == null) return;

    final result = await getDriverSettlementsUseCase(
      GetDriverSettlementsParams(
        currentCompanyContext: context,
        includeVoided: currentState.includeVoided,
      ),
    );
    final latestState = state;
    if (latestState is! DriverSettlementsLoaded) return;

    result.when(
      success: (settlements) => emit(
        latestState.copyWith(
          allSettlements: settlements,
          mutationFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(mutationFailure: failure),
      ),
    );
  }
}
