part of 'drivers_cubit.dart';

mixin DriversSelectedDriverActions on Cubit<DriversState> {
  Future<void> loadDriverActivity(Driver driver) async {
    final owner = this as DriversCubit;
    final context = owner._currentCompanyContext;
    final currentState = state;
    if (context == null || currentState is! DriversLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        selectedDriver: driver,
        selectedDriverActivity: const [],
        isActivityLoading: true,
        activityFailure: null,
      ),
    );

    final result = await owner.getEntityAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: context.companyId,
        module: AuditModule.drivers,
        entityType: AuditEntityType.driver,
        entityId: driver.id,
      ),
    );

    final latestState = state;
    if (latestState is! DriversLoaded ||
        latestState.selectedDriver?.id != driver.id) {
      return;
    }

    result.when(
      success: (activity) => emit(
        latestState.copyWith(
          selectedDriverActivity: activity,
          isActivityLoading: false,
          activityFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          isActivityLoading: false,
          activityFailure: failure,
        ),
      ),
    );
  }

  Future<void> loadDriverImageUrls(Driver driver) async {
    final owner = this as DriversCubit;
    final context = owner._currentCompanyContext;
    final currentState = state;
    if (context == null || currentState is! DriversLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        selectedDriver: driver,
        selectedDriverImageUrls: DriverImageUrls.empty,
        isImageUrlsLoading: true,
        imageUrlsFailure: null,
      ),
    );

    final result = await owner.getDriverImageUrlsUseCase(
      GetDriverImageUrlsParams(currentCompanyContext: context, driver: driver),
    );

    final latestState = state;
    if (latestState is! DriversLoaded ||
        latestState.selectedDriver?.id != driver.id) {
      return;
    }

    result.when(
      success: (imageUrls) => emit(
        latestState.copyWith(
          selectedDriverImageUrls: imageUrls,
          isImageUrlsLoading: false,
          imageUrlsFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          selectedDriverImageUrls: DriverImageUrls.empty,
          isImageUrlsLoading: false,
          imageUrlsFailure: failure,
        ),
      ),
    );
  }

  Future<void> loadDriverTripOptions(Driver driver) async {
    final owner = this as DriversCubit;
    final context = owner._currentCompanyContext;
    final currentState = state;
    if (context == null || currentState is! DriversLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        selectedDriver: driver,
        selectedDriverTripOptions: const [],
        isTripOptionsLoading: true,
        tripOptionsFailure: null,
      ),
    );

    final result = await owner.getDriverTripOptionsUseCase(
      GetDriverTripOptionsParams(
        currentCompanyContext: context,
        driverId: driver.id,
      ),
    );

    final latestState = state;
    if (latestState is! DriversLoaded ||
        latestState.selectedDriver?.id != driver.id) {
      return;
    }

    result.when(
      success: (tripOptions) => emit(
        latestState.copyWith(
          selectedDriverTripOptions: tripOptions,
          isTripOptionsLoading: false,
          tripOptionsFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          selectedDriverTripOptions: const [],
          isTripOptionsLoading: false,
          tripOptionsFailure: failure,
        ),
      ),
    );
  }

  void clearDriverActivity() {
    final currentState = state;
    if (currentState is DriversLoaded) {
      emit(
        currentState.copyWith(
          selectedDriver: null,
          selectedDriverImageUrls: DriverImageUrls.empty,
          isImageUrlsLoading: false,
          imageUrlsFailure: null,
          selectedDriverActivity: const [],
          isActivityLoading: false,
          activityFailure: null,
          selectedDriverFinancialMovements: const [],
          selectedDriverBalance: null,
          selectedDriverTripOptions: const [],
          isTripOptionsLoading: false,
          tripOptionsFailure: null,
          isFinancialMovementsLoading: false,
          isSavingFinancialMovement: false,
          financialMovementsFailure: null,
        ),
      );
    }
  }
}
