part of 'trips_cubit.dart';

mixin TripsDetailsActions on Cubit<TripsState> {
  Future<void> loadTripDetails(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded) return;

    emit(
      current.copyWith(
        selectedTrip: trip,
        selectedTripNetProfit: null,
        selectedTripActivity: const [],
        selectedTripStatusHistory: const [],
        selectedTripExpenses: const [],
        isDetailsLoading: true,
        isActivityLoading: true,
        isStatusHistoryLoading: true,
        isExpensesLoading: true,
        detailsFailure: null,
        activityFailure: null,
        statusHistoryFailure: null,
        expensesFailure: null,
      ),
    );

    await _loadSelectedTripDetails(trip);
    await owner._loadSelectedTripExpenses(trip);
    await owner._loadExpenseTypesIfNeeded();
    await _loadSelectedTripStatusHistory(trip);
    await _loadSelectedTripActivity(trip);
  }

  void clearTripDetails() {
    final current = state;
    if (current is TripsLoaded) {
      emit(
        current.copyWith(
          selectedTrip: null,
          selectedTripNetProfit: null,
          selectedTripActivity: const [],
          selectedTripStatusHistory: const [],
          selectedTripExpenses: const [],
          isDetailsLoading: false,
          isActivityLoading: false,
          isStatusHistoryLoading: false,
          isExpensesLoading: false,
          detailsFailure: null,
          activityFailure: null,
          statusHistoryFailure: null,
          expensesFailure: null,
        ),
      );
    }
  }

  Future<Result<double>> calculateNetProfit({
    required double? freightPrice,
    required double? totalExpenses,
  }) {
    final owner = this as TripsCubit;
    return owner.calculateTripNetProfitUseCase(
      CalculateTripNetProfitParams(
        freightPrice: freightPrice,
        totalExpenses: totalExpenses,
      ),
    );
  }

  Future<void> _loadSelectedTripDetails(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded) return;

    final result = await owner.getTripDetailsUseCase(
      GetTripDetailsParams(
        currentCompanyContext: current.currentCompanyContext,
        id: trip.id,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    if (result is Success<TripEntity>) {
      final details = result.data;
      final netProfit = await _calculateSelectedTripNetProfit(details);
      final currentAfterCalculation = state;
      if (currentAfterCalculation is! TripsLoaded) return;

      emit(
        currentAfterCalculation.copyWith(
          selectedTrip: details,
          selectedTripNetProfit: netProfit,
          isDetailsLoading: false,
          detailsFailure: null,
          allTrips: _upsertTripInList(
            currentAfterCalculation.allTrips,
            details,
          ),
        ),
      );
      return;
    }

    if (result is FailureResult<TripEntity>) {
      emit(
        latestState.copyWith(
          isDetailsLoading: false,
          detailsFailure: result.failure,
        ),
      );
    }
  }

  Future<void> _loadSelectedTripStatusHistory(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded) return;

    emit(
      current.copyWith(
        isStatusHistoryLoading: true,
        statusHistoryFailure: null,
      ),
    );

    final result = await owner.getTripStatusHistoryUseCase(
      GetTripStatusHistoryParams(
        currentCompanyContext: current.currentCompanyContext,
        tripId: trip.id,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (history) {
        emit(
          latestState.copyWith(
            selectedTripStatusHistory: history,
            isStatusHistoryLoading: false,
            statusHistoryFailure: null,
          ),
        );
      },
      failure: (failure) {
        emit(
          latestState.copyWith(
            isStatusHistoryLoading: false,
            statusHistoryFailure: failure,
          ),
        );
      },
    );
  }

  Future<void> _loadSelectedTripActivity(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded) return;

    emit(current.copyWith(isActivityLoading: true, activityFailure: null));

    final result = await owner.getTripAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: current.currentCompanyContext.companyId,
        module: AuditModule.trips,
        entityType: AuditEntityType.trip,
        entityId: trip.id,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (activity) {
        emit(
          latestState.copyWith(
            selectedTripActivity: activity,
            isActivityLoading: false,
            activityFailure: null,
          ),
        );
      },
      failure: (failure) {
        emit(
          latestState.copyWith(
            isActivityLoading: false,
            activityFailure: failure,
          ),
        );
      },
    );
  }

  Future<double?> _calculateSelectedTripNetProfit(TripEntity trip) async {
    final owner = this as TripsCubit;
    final result = await owner.calculateTripNetProfitUseCase(
      CalculateTripNetProfitParams(
        freightPrice: trip.freightPrice,
        totalExpenses: trip.totalExpenses,
      ),
    );

    return result.dataOrNull;
  }
}
