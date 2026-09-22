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

  Future<void> _refreshSelectedTripDocuments(String tripId) async {
    final owner = this as TripsCubit;
    final latest = state;
    if (latest is! TripsLoaded || latest.selectedTrip?.id != tripId) return;

    final trip = latest.selectedTrip!;
    await _loadSelectedTripDocuments(trip);
    await owner._loadSelectedTripActivity(trip);
  }

  Future<void> _loadSelectedTripDocuments(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded || current.selectedTrip?.id != trip.id) return;

    final companyGeneration = owner._companyRequestGeneration;
    final detailsGeneration = owner._detailsRequestGeneration;
    final companyId = current.currentCompanyContext.companyId;

    emit(current.copyWith(isDocumentsLoading: true, documentsFailure: null));

    final result = await owner.getTripDocumentsUseCase(
      GetTripDocumentsParams(
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

    final latest = state as TripsLoaded;
    if (result is FailureResult<List<TripDocument>>) {
      emit(
        latest.copyWith(
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

    if (!owner._isCurrentDetailsRequest(
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
