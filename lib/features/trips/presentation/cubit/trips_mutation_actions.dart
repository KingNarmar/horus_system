part of 'trips_cubit.dart';

mixin TripsMutationActions on Cubit<TripsState> {
  Future<TripMutationResult> saveTrip({
    TripEntity? trip,
    required String customerId,
    required String routeId,
    String? driverId,
    String? tractorHeadId,
    String? trailerId,
    String? loadingOrderNumber,
    String? waybillNumber,
    String? quantityTonsInput,
    String? agreedFreightRatePerTonInput,
    BusinessLocalDateTime? scheduledLoadingAt,
    BusinessLocalDateTime? scheduledDeliveryAt,
    BusinessLocalDateTime? actualLoadingAt,
    BusinessLocalDateTime? actualDeliveryAt,
    String? notes,
  }) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    final current = state;
    if (context == null ||
        current is! TripsLoaded ||
        current.isTripSaving ||
        current.currentCompanyContext.companyId != context.companyId) {
      return const TripMutationIgnored();
    }

    final companyGeneration = owner._companyRequestGeneration;
    final companyId = context.companyId;
    emit(current.copyWith(isTripSaving: true, tripSaveFailure: null));

    final timestampsResult = await owner
        .resolveTripBusinessLocalTimestampsUseCase(
          ResolveTripBusinessLocalTimestampsParams(
            currentCompanyContext: context,
            scheduledLoadingAt: scheduledLoadingAt,
            scheduledDeliveryAt: scheduledDeliveryAt,
            actualLoadingAt: actualLoadingAt,
            actualDeliveryAt: actualDeliveryAt,
          ),
        );

    if (!owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId)) {
      return const TripMutationIgnored();
    }

    if (timestampsResult is FailureResult<TripTimestampInstants>) {
      emit(
        (state as TripsLoaded).copyWith(
          isTripSaving: false,
          tripSaveFailure: timestampsResult.failure,
        ),
      );
      return TripMutationFailed(timestampsResult.failure);
    }
    final timestamps = timestampsResult.dataOrNull!;

    final result = trip == null
        ? await owner.createTripUseCase(
            CreateTripParams(
              currentCompanyContext: context,
              customerId: customerId,
              routeId: routeId,
              driverId: driverId,
              tractorHeadId: tractorHeadId,
              trailerId: trailerId,
              loadingOrderNumber: loadingOrderNumber,
              waybillNumber: waybillNumber,
              quantityTonsInput: quantityTonsInput,
              agreedFreightRatePerTonInput: agreedFreightRatePerTonInput,
              scheduledLoadingAt: timestamps.scheduledLoadingAt,
              scheduledDeliveryAt: timestamps.scheduledDeliveryAt,
              actualLoadingAt: timestamps.actualLoadingAt,
              actualDeliveryAt: timestamps.actualDeliveryAt,
              notes: notes,
            ),
          )
        : await owner.saveTripUseCase(
            SaveTripParams(
              currentCompanyContext: context,
              id: trip.id,
              customerId: customerId,
              routeId: routeId,
              driverId: driverId,
              tractorHeadId: tractorHeadId,
              trailerId: trailerId,
              loadingOrderNumber: loadingOrderNumber,
              waybillNumber: waybillNumber,
              quantityTonsInput: quantityTonsInput,
              agreedFreightRatePerTonInput: agreedFreightRatePerTonInput,
              scheduledLoadingAt: timestamps.scheduledLoadingAt,
              scheduledDeliveryAt: timestamps.scheduledDeliveryAt,
              actualLoadingAt: timestamps.actualLoadingAt,
              actualDeliveryAt: timestamps.actualDeliveryAt,
              notes: notes,
            ),
          );

    if (!owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId)) {
      return const TripMutationIgnored();
    }

    if (result is FailureResult<TripEntity>) {
      emit(
        (state as TripsLoaded).copyWith(
          isTripSaving: false,
          tripSaveFailure: result.failure,
        ),
      );
      return TripMutationFailed(result.failure);
    }

    owner._upsertTrip(
      (result as Success<TripEntity>).data,
      businessLocalTimestamps: TripBusinessLocalTimestamps(
        scheduledLoadingAt: scheduledLoadingAt,
        scheduledDeliveryAt: scheduledDeliveryAt,
        actualLoadingAt: actualLoadingAt,
        actualDeliveryAt: actualDeliveryAt,
      ),
    );
    owner._mapLoaded(
      (state) => state.copyWith(isTripSaving: false, tripSaveFailure: null),
    );
    return const TripMutationSucceeded();
  }

  Future<TripMutationResult> updateTripStatus({
    required TripEntity trip,
    required TripStatus newStatus,
    String? notes,
  }) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    final current = state;
    if (context == null ||
        current is! TripsLoaded ||
        current.currentCompanyContext.companyId != context.companyId ||
        owner._isTripStatusChanging(trip.id)) {
      return const TripMutationIgnored();
    }

    final companyGeneration = owner._companyRequestGeneration;
    final companyId = context.companyId;
    owner._beginTripStatusChange(trip.id);

    final result = await owner.updateTripStatusUseCase(
      UpdateTripStatusParams(
        currentCompanyContext: context,
        id: trip.id,
        newStatus: newStatus,
        notes: notes,
      ),
    );

    if (!owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId)) {
      return const TripMutationIgnored();
    }

    if (result is FailureResult<TripEntity>) {
      owner._finishTripStatusChange(trip.id, failure: result.failure);
      return TripMutationFailed(result.failure);
    }

    final updatedTrip = (result as Success<TripEntity>).data;
    owner._finishTripStatusChange(trip.id);
    owner._upsertTrip(updatedTrip);

    final latest = state;
    if (latest is TripsLoaded && latest.selectedTrip?.id == updatedTrip.id) {
      await owner._loadSelectedTripStatusHistory(updatedTrip);
      await owner._loadSelectedTripActivity(updatedTrip);
    }

    return const TripMutationSucceeded();
  }
}
