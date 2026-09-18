part of 'trips_cubit.dart';

mixin TripsDetailsActions on Cubit<TripsState> {
  Future<void> loadTripDetails(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded) return;

    owner._beginDetailsRequest();
    emit(
      current.copyWith(
        selectedTrip: trip,
        selectedTripTotalExpenses: null,
        selectedTripNetProfit: null,
        selectedTripActivity: const [],
        selectedTripActivityBusinessTimesById: const {},
        selectedTripDocuments: const [],
        hasRequiredTripEvidence: false,
        selectedTripStatusHistory: const [],
        selectedTripStatusHistoryBusinessTimesById: const {},
        selectedTripExpenses: const [],
        isDetailsLoading: true,
        isActivityLoading: true,
        isDocumentsLoading: true,
        isStatusHistoryLoading: true,
        isExpensesLoading: true,
        detailsFailure: null,
        activityFailure: null,
        documentsFailure: null,
        statusHistoryFailure: null,
        expensesFailure: null,
      ),
    );

    await _loadSelectedTripDetails(trip);
    await owner._loadSelectedTripExpenses(trip);
    await owner._loadSelectedTripDocuments(trip);
    await owner._loadExpenseTypesIfNeeded();
    await _loadSelectedTripStatusHistory(trip);
    await _loadSelectedTripActivity(trip);
  }

  void clearTripDetails() {
    final owner = this as TripsCubit;
    owner._beginDetailsRequest();

    final current = state;
    if (current is TripsLoaded) {
      emit(
        current.copyWith(
          selectedTrip: null,
          selectedTripTotalExpenses: null,
          selectedTripNetProfit: null,
          selectedTripActivity: const [],
          selectedTripActivityBusinessTimesById: const {},
          selectedTripDocuments: const [],
          hasRequiredTripEvidence: false,
          selectedTripStatusHistory: const [],
          selectedTripStatusHistoryBusinessTimesById: const {},
          selectedTripExpenses: const [],
          isDetailsLoading: false,
          isActivityLoading: false,
          isDocumentsLoading: false,
          isTripDocumentMutating: false,
          isStatusHistoryLoading: false,
          isExpensesLoading: false,
          detailsFailure: null,
          activityFailure: null,
          documentsFailure: null,
          statusHistoryFailure: null,
          expensesFailure: null,
        ),
      );
    }
  }

  Future<void> _loadSelectedTripDetails(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded || current.selectedTrip?.id != trip.id) return;

    final companyGeneration = owner._companyRequestGeneration;
    final detailsGeneration = owner._detailsRequestGeneration;
    final companyId = current.currentCompanyContext.companyId;

    final result = await owner.getTripDetailsUseCase(
      GetTripDetailsParams(
        currentCompanyContext: current.currentCompanyContext,
        id: trip.id,
      ),
    );

    if (!owner._isCurrentDetailsRequest(
      companyGeneration: companyGeneration,
      detailsGeneration: detailsGeneration,
      companyId: companyId,
      tripId: trip.id,
    )) {
      return;
    }

    if (result is FailureResult<TripEntity>) {
      emit(
        (state as TripsLoaded).copyWith(
          isDetailsLoading: false,
          detailsFailure: result.failure,
        ),
      );
      return;
    }

    final details = (result as Success<TripEntity>).data;
    final localTimestampsResult = await owner
        .getTripBusinessLocalTimestampsUseCase(
          GetTripBusinessLocalTimestampsParams(
            currentCompanyContext: current.currentCompanyContext,
            trip: details,
          ),
        );

    if (!owner._isCurrentDetailsRequest(
      companyGeneration: companyGeneration,
      detailsGeneration: detailsGeneration,
      companyId: companyId,
      tripId: trip.id,
    )) {
      return;
    }

    final latest = state as TripsLoaded;
    if (localTimestampsResult is FailureResult<TripBusinessLocalTimestamps>) {
      emit(
        latest.copyWith(
          isDetailsLoading: false,
          detailsFailure: localTimestampsResult.failure,
        ),
      );
      return;
    }

    final localTimestamps = {
      ...latest.businessLocalTimestampsByTripId,
      details.id:
          (localTimestampsResult as Success<TripBusinessLocalTimestamps>).data,
    };

    emit(
      latest.copyWith(
        selectedTrip: details,
        businessLocalTimestampsByTripId: localTimestamps,
        isDetailsLoading: false,
        detailsFailure: null,
        allTrips: _upsertTripInList(latest.allTrips, details),
      ),
    );
  }

  Future<void> _loadSelectedTripStatusHistory(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded || current.selectedTrip?.id != trip.id) return;

    final companyGeneration = owner._companyRequestGeneration;
    final detailsGeneration = owner._detailsRequestGeneration;
    final companyId = current.currentCompanyContext.companyId;

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

    if (!owner._isCurrentDetailsRequest(
      companyGeneration: companyGeneration,
      detailsGeneration: detailsGeneration,
      companyId: companyId,
      tripId: trip.id,
    )) {
      return;
    }

    if (result is FailureResult<List<TripStatusHistory>>) {
      emit(
        (state as TripsLoaded).copyWith(
          isStatusHistoryLoading: false,
          statusHistoryFailure: result.failure,
        ),
      );
      return;
    }

    final history = (result as Success<List<TripStatusHistory>>).data;
    final businessTimesResult = await owner._convertCompanyInstants(
      current.currentCompanyContext,
      {for (final item in history) item.id: item.changedAt},
    );

    if (!owner._isCurrentDetailsRequest(
      companyGeneration: companyGeneration,
      detailsGeneration: detailsGeneration,
      companyId: companyId,
      tripId: trip.id,
    )) {
      return;
    }

    final latest = state as TripsLoaded;
    if (businessTimesResult
        is FailureResult<Map<String, BusinessLocalDateTime>>) {
      emit(
        latest.copyWith(
          isStatusHistoryLoading: false,
          statusHistoryFailure: businessTimesResult.failure,
        ),
      );
      return;
    }

    emit(
      latest.copyWith(
        selectedTripStatusHistory: history,
        selectedTripStatusHistoryBusinessTimesById:
            (businessTimesResult as Success<Map<String, BusinessLocalDateTime>>)
                .data,
        isStatusHistoryLoading: false,
        statusHistoryFailure: null,
      ),
    );
  }

  Future<void> _loadSelectedTripActivity(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded || current.selectedTrip?.id != trip.id) return;

    final companyGeneration = owner._companyRequestGeneration;
    final detailsGeneration = owner._detailsRequestGeneration;
    final companyId = current.currentCompanyContext.companyId;

    emit(current.copyWith(isActivityLoading: true, activityFailure: null));
    final result = await owner.getTripAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: companyId,
        module: AuditModule.trips,
        entityType: AuditEntityType.trip,
        entityId: trip.id,
      ),
    );

    if (!owner._isCurrentDetailsRequest(
      companyGeneration: companyGeneration,
      detailsGeneration: detailsGeneration,
      companyId: companyId,
      tripId: trip.id,
    )) {
      return;
    }

    if (result is FailureResult<List<AuditLog>>) {
      emit(
        (state as TripsLoaded).copyWith(
          isActivityLoading: false,
          activityFailure: result.failure,
        ),
      );
      return;
    }

    final activity = (result as Success<List<AuditLog>>).data;
    final businessTimesResult = await owner._convertCompanyInstants(
      current.currentCompanyContext,
      {for (final log in activity) log.id: log.createdAt},
    );

    if (!owner._isCurrentDetailsRequest(
      companyGeneration: companyGeneration,
      detailsGeneration: detailsGeneration,
      companyId: companyId,
      tripId: trip.id,
    )) {
      return;
    }

    final latest = state as TripsLoaded;
    if (businessTimesResult
        is FailureResult<Map<String, BusinessLocalDateTime>>) {
      emit(
        latest.copyWith(
          isActivityLoading: false,
          activityFailure: businessTimesResult.failure,
        ),
      );
      return;
    }

    emit(
      latest.copyWith(
        selectedTripActivity: activity,
        selectedTripActivityBusinessTimesById:
            (businessTimesResult as Success<Map<String, BusinessLocalDateTime>>)
                .data,
        isActivityLoading: false,
        activityFailure: null,
      ),
    );
  }
}
