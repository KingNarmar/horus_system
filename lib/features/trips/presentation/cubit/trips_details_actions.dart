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
        selectedTripActivityBusinessTimesById: const {},
        selectedTripStatusHistory: const [],
        selectedTripStatusHistoryBusinessTimesById: const {},
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
          selectedTripActivityBusinessTimesById: const {},
          selectedTripStatusHistory: const [],
          selectedTripStatusHistoryBusinessTimesById: const {},
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
      final localTimestampsResult = await owner
          .getTripBusinessLocalTimestampsUseCase(
            GetTripBusinessLocalTimestampsParams(
              currentCompanyContext: latestState.currentCompanyContext,
              trip: details,
            ),
          );
      if (localTimestampsResult is FailureResult<TripBusinessLocalTimestamps>) {
        emit(
          latestState.copyWith(
            isDetailsLoading: false,
            detailsFailure: localTimestampsResult.failure,
          ),
        );
        return;
      }

      final netProfit = await _calculateSelectedTripNetProfit(details);
      final currentAfterCalculation = state;
      if (currentAfterCalculation is! TripsLoaded) return;
      final localTimestamps = {
        ...currentAfterCalculation.businessLocalTimestampsByTripId,
        details.id:
            (localTimestampsResult as Success<TripBusinessLocalTimestamps>)
                .data,
      };

      emit(
        currentAfterCalculation.copyWith(
          selectedTrip: details,
          selectedTripNetProfit: netProfit,
          businessLocalTimestampsByTripId: localTimestamps,
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

    if (result is FailureResult<List<TripStatusHistory>>) {
      emit(
        latestState.copyWith(
          isStatusHistoryLoading: false,
          statusHistoryFailure: result.failure,
        ),
      );
      return;
    }

    final history = (result as Success<List<TripStatusHistory>>).data;
    final businessTimesResult = await owner._convertCompanyInstants(
      latestState.currentCompanyContext,
      {for (final item in history) item.id: item.changedAt},
    );
    final currentAfterConversion = state;
    if (currentAfterConversion is! TripsLoaded) return;

    if (businessTimesResult
        is FailureResult<Map<String, BusinessLocalDateTime>>) {
      emit(
        currentAfterConversion.copyWith(
          isStatusHistoryLoading: false,
          statusHistoryFailure: businessTimesResult.failure,
        ),
      );
      return;
    }

    emit(
      currentAfterConversion.copyWith(
        selectedTripStatusHistory: history,
        selectedTripStatusHistoryBusinessTimesById:
            (businessTimesResult
                    as Success<Map<String, BusinessLocalDateTime>>)
                .data,
        isStatusHistoryLoading: false,
        statusHistoryFailure: null,
      ),
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

    if (result is FailureResult<List<AuditLog>>) {
      emit(
        latestState.copyWith(
          isActivityLoading: false,
          activityFailure: result.failure,
        ),
      );
      return;
    }

    final activity = (result as Success<List<AuditLog>>).data;
    final businessTimesResult = await owner._convertCompanyInstants(
      latestState.currentCompanyContext,
      {for (final log in activity) log.id: log.createdAt},
    );
    final currentAfterConversion = state;
    if (currentAfterConversion is! TripsLoaded) return;

    if (businessTimesResult
        is FailureResult<Map<String, BusinessLocalDateTime>>) {
      emit(
        currentAfterConversion.copyWith(
          isActivityLoading: false,
          activityFailure: businessTimesResult.failure,
        ),
      );
      return;
    }

    emit(
      currentAfterConversion.copyWith(
        selectedTripActivity: activity,
        selectedTripActivityBusinessTimesById:
            (businessTimesResult
                    as Success<Map<String, BusinessLocalDateTime>>)
                .data,
        isActivityLoading: false,
        activityFailure: null,
      ),
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
