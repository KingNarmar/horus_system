part of 'drivers_cubit.dart';

mixin DriversMutationActions on Cubit<DriversState> {
  Future<Failure?> addDriver({
    required String fullName,
    String? phone,
    String? nationalId,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    DriverImageUploadSet? imageUploads,
    String? notes,
  }) async {
    final owner = this as DriversCubit;
    final context = owner._currentCompanyContext;
    if (context == null) {
      return const UnexpectedFailure();
    }

    final result = await owner.addDriverUseCase(
      AddDriverParams(
        currentCompanyContext: context,
        fullName: fullName,
        phone: phone,
        nationalId: nationalId,
        licenseNumber: licenseNumber,
        licenseExpiryDate: licenseExpiryDate,
        imageUploads: imageUploads,
        notes: notes,
      ),
    );

    if (result is Success<Driver>) {
      _upsertDriver(result.data);
      return null;
    }

    if (result is FailureResult<Driver>) {
      return result.failure;
    }

    return const UnexpectedFailure();
  }

  Future<Failure?> updateDriver({
    required Driver driver,
    required String fullName,
    String? phone,
    String? nationalId,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    DriverImageUploadSet? imageUploads,
    String? notes,
  }) async {
    final owner = this as DriversCubit;
    final context = owner._currentCompanyContext;
    if (context == null) {
      return const UnexpectedFailure();
    }

    final result = await owner.updateDriverUseCase(
      UpdateDriverParams(
        currentCompanyContext: context,
        driverId: driver.id,
        fullName: fullName,
        phone: phone,
        nationalId: nationalId,
        licenseNumber: licenseNumber,
        licenseExpiryDate: licenseExpiryDate,
        imageUploads: imageUploads,
        notes: notes,
      ),
    );

    if (result is Success<Driver>) {
      _upsertDriver(result.data);
      return null;
    }

    if (result is FailureResult<Driver>) {
      return result.failure;
    }

    return const UnexpectedFailure();
  }

  Future<void> deactivateDriver(Driver driver) async {
    final owner = this as DriversCubit;
    final context = owner._currentCompanyContext;
    if (context == null || !_startPendingAction(driver.id)) {
      return;
    }

    final result = await owner.deactivateDriverUseCase(
      DeactivateDriverParams(
        currentCompanyContext: context,
        driverId: driver.id,
      ),
    );

    result.when(success: _upsertDriver, failure: _emitMutationFailure);
  }

  Future<void> reactivateDriver(Driver driver) async {
    final owner = this as DriversCubit;
    final context = owner._currentCompanyContext;
    if (context == null || !_startPendingAction(driver.id)) {
      return;
    }

    final result = await owner.reactivateDriverUseCase(
      ReactivateDriverParams(
        currentCompanyContext: context,
        driverId: driver.id,
      ),
    );

    result.when(success: _upsertDriver, failure: _emitMutationFailure);
  }

  bool _startPendingAction(String driverId) {
    final currentState = state;
    if (currentState is! DriversLoaded) {
      return true;
    }
    if (currentState.pendingActionDriverId != null) {
      return false;
    }
    emit(currentState.copyWith(pendingActionDriverId: driverId));
    return true;
  }

  void _emitMutationFailure(Failure failure) {
    final currentState = state;
    if (currentState is DriversLoaded) {
      emit(currentState.copyWith(pendingActionDriverId: null));
    }
    emit(DriversFailure(failure));
  }

  void _upsertDriver(Driver driver) {
    final owner = this as DriversCubit;
    final currentState = state;
    final context = owner._currentCompanyContext;
    if (currentState is! DriversLoaded) {
      if (context != null) {
        owner.loadDrivers(context);
      }
      return;
    }

    final exists = currentState.allDrivers.any((item) => item.id == driver.id);
    final updatedDrivers = exists
        ? currentState.allDrivers
              .map((item) => item.id == driver.id ? driver : item)
              .toList()
        : [driver, ...currentState.allDrivers];

    if (currentState.selectedDriver?.id == driver.id) {
      emit(
        currentState.copyWith(
          allDrivers: updatedDrivers,
          pendingActionDriverId: null,
          selectedDriver: driver,
        ),
      );
      return;
    }

    emit(
      currentState.copyWith(
        allDrivers: updatedDrivers,
        pendingActionDriverId: null,
      ),
    );
  }
}
