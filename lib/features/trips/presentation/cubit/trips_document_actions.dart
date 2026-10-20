part of 'trips_cubit.dart';

mixin TripsDocumentActions on Cubit<TripsState> {
  Future<void> uploadTripDocument({
    required String tripId,
    required TripDocumentKind kind,
    required BusinessDocumentFile document,
  }) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    final current = state;
    if (context == null ||
        current is! TripsLoaded ||
        current.currentCompanyContext.companyId != context.companyId ||
        current.selectedTrip?.id != tripId ||
        current.isTripDocumentMutating) {
      return;
    }

    final companyGeneration = owner._companyRequestGeneration;
    final detailsGeneration = owner._detailsRequestGeneration;
    final companyId = context.companyId;
    emit(
      current.copyWith(isTripDocumentMutating: true, documentsFailure: null),
    );

    final result = await owner.uploadTripDocumentUseCase(
      UploadTripDocumentParams(
        currentCompanyContext: context,
        tripId: tripId,
        kind: kind,
        document: document,
      ),
    );

    if (!owner._isCurrentDetailsRequest(
      companyGeneration: companyGeneration,
      detailsGeneration: detailsGeneration,
      companyId: companyId,
      tripId: tripId,
    )) {
      return;
    }

    owner._mapLoaded((state) => state.copyWith(isTripDocumentMutating: false));

    result.when(
      success: (_) => _refreshSelectedTripDocuments(tripId),
      failure: (failure) => owner._mapLoaded(
        (state) => state.copyWith(documentsFailure: failure),
      ),
    );
    if (owner._documentsRealtimeRefreshPending) {
      unawaited(refreshSelectedTripDocumentsFromRealtime());
    }
  }

  Future<void> replaceTripDocument({
    required TripDocument document,
    required BusinessDocumentFile replacement,
  }) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    final current = state;
    if (context == null ||
        current is! TripsLoaded ||
        current.currentCompanyContext.companyId != context.companyId ||
        current.selectedTrip?.id != document.tripId ||
        current.isTripDocumentMutating) {
      return;
    }

    final companyGeneration = owner._companyRequestGeneration;
    final detailsGeneration = owner._detailsRequestGeneration;
    final companyId = context.companyId;
    emit(
      current.copyWith(isTripDocumentMutating: true, documentsFailure: null),
    );

    final result = await owner.replaceTripDocumentUseCase(
      ReplaceTripDocumentParams(
        currentCompanyContext: context,
        document: document,
        replacement: replacement,
      ),
    );

    if (!owner._isCurrentDetailsRequest(
      companyGeneration: companyGeneration,
      detailsGeneration: detailsGeneration,
      companyId: companyId,
      tripId: document.tripId,
    )) {
      return;
    }

    owner._mapLoaded((state) => state.copyWith(isTripDocumentMutating: false));

    result.when(
      success: (_) => _refreshSelectedTripDocuments(document.tripId),
      failure: (failure) => owner._mapLoaded(
        (state) => state.copyWith(documentsFailure: failure),
      ),
    );
    if (owner._documentsRealtimeRefreshPending) {
      unawaited(refreshSelectedTripDocumentsFromRealtime());
    }
  }

  Future<void> removeTripDocument({
    required TripEntity trip,
    required TripDocument document,
  }) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    final current = state;
    if (context == null ||
        current is! TripsLoaded ||
        current.currentCompanyContext.companyId != context.companyId ||
        current.selectedTrip?.id != trip.id ||
        current.isTripDocumentMutating) {
      return;
    }

    final companyGeneration = owner._companyRequestGeneration;
    final detailsGeneration = owner._detailsRequestGeneration;
    final companyId = context.companyId;
    emit(
      current.copyWith(isTripDocumentMutating: true, documentsFailure: null),
    );

    final result = await owner.removeTripDocumentUseCase(
      RemoveTripDocumentParams(
        currentCompanyContext: context,
        trip: trip,
        document: document,
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

    owner._mapLoaded((state) => state.copyWith(isTripDocumentMutating: false));

    result.when(
      success: (_) => _refreshSelectedTripDocuments(trip.id),
      failure: (failure) => owner._mapLoaded(
        (state) => state.copyWith(documentsFailure: failure),
      ),
    );
    if (owner._documentsRealtimeRefreshPending) {
      unawaited(refreshSelectedTripDocumentsFromRealtime());
    }
  }

  Future<Uint8List?> downloadTripDocument(TripDocument document) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    final current = state;
    if (context == null ||
        current is! TripsLoaded ||
        current.currentCompanyContext.companyId != context.companyId ||
        current.selectedTrip?.id != document.tripId) {
      return null;
    }

    final result = await owner.downloadTripDocumentUseCase(
      TripDocumentActionParams(
        currentCompanyContext: context,
        document: document,
      ),
    );

    if (result is FailureResult<Uint8List>) {
      owner._mapLoaded(
        (state) => state.copyWith(documentsFailure: result.failure),
      );
      return null;
    }

    owner._mapLoaded((state) => state.copyWith(documentsFailure: null));
    return (result as Success<Uint8List>).data;
  }

  Future<BusinessDocumentAccess?> createTripDocumentAccess(
    TripDocument document,
  ) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    final current = state;
    if (context == null ||
        current is! TripsLoaded ||
        current.currentCompanyContext.companyId != context.companyId ||
        current.selectedTrip?.id != document.tripId) {
      return null;
    }

    final result = await owner.getTripDocumentAccessUseCase(
      TripDocumentActionParams(
        currentCompanyContext: context,
        document: document,
      ),
    );

    if (result is FailureResult<BusinessDocumentAccess>) {
      owner._mapLoaded(
        (state) => state.copyWith(documentsFailure: result.failure),
      );
      return null;
    }

    owner._mapLoaded((state) => state.copyWith(documentsFailure: null));
    return (result as Success<BusinessDocumentAccess>).data;
  }

  /// Re-read only the open Trip's documents and audit from authorized use cases.
  /// Coalesce hints and defer them while a local document mutation is active.
  Future<void> refreshSelectedTripDocumentsFromRealtime() async {
    final owner = this as TripsCubit;
    if (owner.isClosed) return;
    final current = state;
    if (current is! TripsLoaded || current.selectedTrip == null) return;

    owner._documentsRealtimeRefreshPending = true;
    if (owner._documentsRealtimeRefreshInProgress ||
        current.isDocumentsLoading ||
        current.isTripDocumentMutating) {
      return;
    }

    owner._documentsRealtimeRefreshInProgress = true;
    try {
      while (owner._documentsRealtimeRefreshPending && !owner.isClosed) {
        final latest = state;
        if (latest is! TripsLoaded || latest.selectedTrip == null) {
          owner._documentsRealtimeRefreshPending = false;
          break;
        }
        if (latest.isDocumentsLoading || latest.isTripDocumentMutating) break;

        owner._documentsRealtimeRefreshPending = false;
        final trip = latest.selectedTrip!;
        final companyGeneration = owner._companyRequestGeneration;
        final detailsGeneration = owner._detailsRequestGeneration;
        final companyId = latest.currentCompanyContext.companyId;

        await _loadSelectedTripDocuments(trip, silent: true);
        if (owner._isCurrentDetailsRequest(
          companyGeneration: companyGeneration,
          detailsGeneration: detailsGeneration,
          companyId: companyId,
          tripId: trip.id,
        )) {
          await owner._loadSelectedTripActivity(trip);
        }
      }
    } finally {
      owner._documentsRealtimeRefreshInProgress = false;
      final latest = state;
      if (!owner.isClosed &&
          owner._documentsRealtimeRefreshPending &&
          latest is TripsLoaded &&
          latest.selectedTrip != null &&
          !latest.isDocumentsLoading &&
          !latest.isTripDocumentMutating) {
        unawaited(refreshSelectedTripDocumentsFromRealtime());
      }
    }
  }

  Future<void> _refreshSelectedTripDocuments(String tripId) async {
    final owner = this as TripsCubit;
    final latest = state;
    if (latest is! TripsLoaded || latest.selectedTrip?.id != tripId) return;

    final trip = latest.selectedTrip!;
    await _loadSelectedTripDocuments(trip);
    if (owner._documentsRealtimeRefreshPending) {
      unawaited(refreshSelectedTripDocumentsFromRealtime());
    }
    await owner._loadSelectedTripActivity(trip);
  }

  Future<void> _loadSelectedTripDocuments(
    TripEntity trip, {
    bool silent = false,
  }) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded || current.selectedTrip?.id != trip.id) return;

    final companyGeneration = owner._companyRequestGeneration;
    final detailsGeneration = owner._detailsRequestGeneration;
    final companyId = current.currentCompanyContext.companyId;
    final documentsRevision = ++owner._documentsLoadRevision;

    if (!silent) {
      emit(current.copyWith(isDocumentsLoading: true, documentsFailure: null));
    }

    final result = await owner.getTripDocumentsUseCase(
      GetTripDocumentsParams(
        currentCompanyContext: current.currentCompanyContext,
        tripId: trip.id,
      ),
    );

    if (owner.isClosed ||
        documentsRevision != owner._documentsLoadRevision ||
        !owner._isCurrentDetailsRequest(
          companyGeneration: companyGeneration,
          detailsGeneration: detailsGeneration,
          companyId: companyId,
          tripId: trip.id,
        )) {
      return;
    }

    final latest = state as TripsLoaded;
    if (silent && latest.isTripDocumentMutating) {
      owner._documentsRealtimeRefreshPending = true;
      return;
    }
    if (result is FailureResult<List<TripDocument>>) {
      final accessRevoked =
          result.failure is PermissionFailure || result.failure is AuthFailure;
      emit(
        latest.copyWith(
          selectedTripDocuments: accessRevoked
              ? const <TripDocument>[]
              : latest.selectedTripDocuments,
          hasRequiredTripEvidence: accessRevoked
              ? false
              : latest.hasRequiredTripEvidence,
          isDocumentsLoading: false,
          documentsFailure: result.failure,
        ),
      );
      return;
    }

    final documents = (result as Success<List<TripDocument>>).data;
    final evidenceResult = await owner.hasRequiredTripEvidenceUseCase(
      HasRequiredTripEvidenceParams(documents: documents),
    );

    if (owner.isClosed ||
        documentsRevision != owner._documentsLoadRevision ||
        !owner._isCurrentDetailsRequest(
          companyGeneration: companyGeneration,
          detailsGeneration: detailsGeneration,
          companyId: companyId,
          tripId: trip.id,
        )) {
      return;
    }

    final evidenceFailure = evidenceResult.failureOrNull;
    if (evidenceFailure != null) {
      final projected = state as TripsLoaded;
      emit(
        projected.copyWith(
          isDocumentsLoading: false,
          documentsFailure: evidenceFailure,
        ),
      );
      return;
    }

    final projected = state as TripsLoaded;
    if (silent && projected.isTripDocumentMutating) {
      owner._documentsRealtimeRefreshPending = true;
      return;
    }
    emit(
      projected.copyWith(
        selectedTripDocuments: documents,
        hasRequiredTripEvidence: evidenceResult.dataOrNull ?? false,
        isDocumentsLoading: false,
        documentsFailure: null,
      ),
    );
  }
}
