part of 'driver_finance_cubit.dart';

/// Re-fetches authorized Driver Finance projections without clearing the
/// selected driver, movements, balance, or an in-progress form.
mixin DriverFinanceRealtimeActions on Cubit<DriverFinanceState> {
  Future<void> reconcileDriverFinanceAfterReconnect(
    CurrentCompanyContext context,
  ) async {
    final owner = this as DriverFinanceCubit;
    if (owner.isClosed) return;
    final current = state;
    if (current is DriverFinanceInitial || current is DriverFinanceFailure) {
      await owner.load(context);
      return;
    }
    if (current is DriverFinanceLoading) {
      owner._realtimeRefreshPending = true;
      return;
    }
    if (current is! DriverFinanceLoaded ||
        current.currentCompanyContext.companyId != context.companyId ||
        current.currentCompanyContext.role != context.role) {
      return;
    }
    await refreshDriverReferencesFromRealtime();
    await refreshDriverFinanceFromRealtime();
  }

  /// Driver names and available selections are independent of financial
  /// movements. Refresh them only when the Drivers source changes.
  Future<void> refreshDriverReferencesFromRealtime() async {
    final owner = this as DriverFinanceCubit;
    if (owner.isClosed) return;
    final current = state;
    if (current is DriverFinanceLoading) {
      owner._driverReferencesRefreshPending = true;
      return;
    }
    if (current is! DriverFinanceLoaded) return;
    if (current.isSaving || owner._driverReferencesRefreshInProgress) {
      owner._driverReferencesRefreshPending = true;
      return;
    }

    owner._driverReferencesRefreshInProgress = true;
    try {
      do {
        owner._driverReferencesRefreshPending = false;
        await _refreshDriverReferencesOnce();
      } while (owner._driverReferencesRefreshPending &&
          !owner.isClosed &&
          state is DriverFinanceLoaded &&
          !(state as DriverFinanceLoaded).isSaving);
    } finally {
      owner._driverReferencesRefreshInProgress = false;
    }
  }

  Future<void> _refreshDriverReferencesOnce() async {
    final owner = this as DriverFinanceCubit;
    final before = state;
    if (before is! DriverFinanceLoaded || before.isSaving) return;
    final context = before.currentCompanyContext;
    final generation = owner._loadRequestId;
    final result = await owner.getDriversUseCase(
      GetDriversParams(currentCompanyContext: context),
    );
    if (!owner._isCurrentLoad(generation, context)) return;

    final latest = state;
    if (latest is! DriverFinanceLoaded) return;
    if (latest.isSaving) {
      owner._driverReferencesRefreshPending = true;
      return;
    }
    final failure = result.failureOrNull;
    if (failure != null) {
      _handleRealtimeFailure(failure);
      return;
    }

    final drivers = result.dataOrNull ?? const <Driver>[];
    final selectedId = latest.selectedDriverId;
    final retainsSelection =
        selectedId == null || drivers.any((driver) => driver.id == selectedId);
    if (!retainsSelection) owner._detailsRequestId++;
    emit(
      latest.copyWith(
        drivers: List.unmodifiable(drivers),
        selectedDriverId: retainsSelection ? selectedId : null,
        activity: retainsSelection ? latest.activity : null,
        tripOptions: retainsSelection ? latest.tripOptions : const [],
        isDetailsLoading: retainsSelection ? latest.isDetailsLoading : false,
        realtimeRefreshFailure: null,
      ),
    );
  }

  /// Serializes burst invalidations. On permission failures do not retain
  /// protected financial data; on network failures retain last-good values.
  Future<void> refreshDriverFinanceFromRealtime() async {
    final owner = this as DriverFinanceCubit;
    if (owner.isClosed) return;
    final current = state;
    if (current is DriverFinanceLoading) {
      owner._realtimeRefreshPending = true;
      return;
    }
    if (current is! DriverFinanceLoaded) return;
    if (current.isSaving || owner._realtimeRefreshInProgress) {
      owner._realtimeRefreshPending = true;
      return;
    }

    owner._realtimeRefreshInProgress = true;
    try {
      do {
        owner._realtimeRefreshPending = false;
        await _refreshVisibleDriverOnce();
      } while (owner._realtimeRefreshPending &&
          !owner.isClosed &&
          state is DriverFinanceLoaded &&
          !(state as DriverFinanceLoaded).isSaving);
    } finally {
      owner._realtimeRefreshInProgress = false;
    }
  }

  Future<void> _refreshVisibleDriverOnce() async {
    final owner = this as DriverFinanceCubit;
    final before = state;
    if (before is! DriverFinanceLoaded || before.isSaving) return;
    final driverId = before.selectedDriverId;
    if (driverId == null) return;
    final context = before.currentCompanyContext;
    final companyGeneration = owner._loadRequestId;
    final requestId = ++owner._detailsRequestId;

    bool stillCurrent() =>
        owner._loadRequestId == companyGeneration &&
        owner._isCurrentDetailsRequest(
          requestId,
          context.companyId,
          driverId,
        ) &&
        state is DriverFinanceLoaded &&
        !(state as DriverFinanceLoaded).isSaving;

    final activity = await owner.getCurrentDriverBalanceActivityUseCase(
      GetCurrentDriverBalanceActivityParams(
        currentCompanyContext: context,
        driverId: driverId,
      ),
    );
    if (!stillCurrent()) return;
    if (_handleRealtimeFailure(activity.failureOrNull)) return;

    final options = await owner.getDriverTripOptionsUseCase(
      GetDriverTripOptionsParams(
        currentCompanyContext: context,
        driverId: driverId,
      ),
    );
    if (!stillCurrent()) return;
    final optionsFailure = options.failureOrNull;
    if (optionsFailure is AuthFailure ||
        optionsFailure is PermissionFailure) {
      _handleRealtimeFailure(optionsFailure);
      return;
    }

    // Optional Trip labels must not hold back a newer canonical balance and
    // statement. Retain last-good labels on transient lookup failure.
    final latest = state as DriverFinanceLoaded;
    emit(
      latest.copyWith(
        activity: activity.dataOrNull,
        tripOptions: optionsFailure == null
            ? List.unmodifiable(
                options.dataOrNull ?? const <DriverFinanceTripOption>[],
              )
            : latest.tripOptions,
        isDetailsLoading: false,
        realtimeRefreshFailure: optionsFailure,
      ),
    );
  }

  bool _handleRealtimeFailure(Failure? failure) {
    if (failure == null) return false;
    if (failure is AuthFailure || failure is PermissionFailure) {
      emit(DriverFinanceFailure(failure));
    } else {
      final latest = state;
      if (latest is DriverFinanceLoaded) {
        emit(latest.copyWith(realtimeRefreshFailure: failure));
      }
    }
    return true;
  }
}
