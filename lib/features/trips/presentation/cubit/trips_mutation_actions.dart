part of 'trips_cubit.dart';

mixin TripsMutationActions on Cubit<TripsState> {
  Future<void> saveTrip({
    TripEntity? trip,
    required String customerId,
    required String routeId,
    String? driverId,
    String? tractorHeadId,
    String? trailerId,
    String? loadingOrderNumber,
    String? waybillNumber,
    double? quantityTons,
    double? freightPrice,
    BusinessLocalDateTime? scheduledLoadingAt,
    BusinessLocalDateTime? scheduledDeliveryAt,
    BusinessLocalDateTime? actualLoadingAt,
    BusinessLocalDateTime? actualDeliveryAt,
    String? notes,
  }) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    if (context == null) return;

    final timestampsResult = await owner.resolveTripBusinessLocalTimestampsUseCase(
      ResolveTripBusinessLocalTimestampsParams(
        currentCompanyContext: context,
        scheduledLoadingAt: scheduledLoadingAt,
        scheduledDeliveryAt: scheduledDeliveryAt,
        actualLoadingAt: actualLoadingAt,
        actualDeliveryAt: actualDeliveryAt,
      ),
    );
    if (timestampsResult is FailureResult<TripTimestampInstants>) {
      emit(TripsFailure(timestampsResult.failure));
      return;
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
              quantityTons: quantityTons,
              freightPrice: freightPrice,
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
              quantityTons: quantityTons,
              freightPrice: freightPrice,
              scheduledLoadingAt: timestamps.scheduledLoadingAt,
              scheduledDeliveryAt: timestamps.scheduledDeliveryAt,
              actualLoadingAt: timestamps.actualLoadingAt,
              actualDeliveryAt: timestamps.actualDeliveryAt,
              notes: notes,
            ),
          );

    if (result is FailureResult<TripEntity>) {
      emit(TripsFailure(result.failure));
      return;
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
  }

  Future<void> updateTripStatus({
    required TripEntity trip,
    required TripStatus newStatus,
    String? notes,
  }) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    if (context == null || owner._isTripStatusChanging(trip.id)) return;

    owner._setTripStatusChanging(trip.id, true);

    final result = await owner.updateTripStatusUseCase(
      UpdateTripStatusParams(
        currentCompanyContext: context,
        id: trip.id,
        newStatus: newStatus,
        notes: notes,
      ),
    );

    owner._setTripStatusChanging(trip.id, false);

    result.when(
      success: (updatedTrip) async {
        owner._upsertTrip(updatedTrip);

        final current = state;
        if (current is TripsLoaded &&
            current.selectedTrip?.id == updatedTrip.id) {
          await owner._loadSelectedTripStatusHistory(updatedTrip);
          await owner._loadSelectedTripActivity(updatedTrip);
        }
      },
      failure: (failure) => emit(TripsFailure(failure)),
    );
  }
}
