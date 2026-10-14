part of 'drivers_cubit.dart';

/// Reconcile only when Drivers is visible; Core owns the session subscription.
mixin DriversRealtimeActions on Cubit<DriversState> {
  Future<void> refreshDrivers(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    final owner = this as DriversCubit;
    if (!owner._isCurrentMutationContext(currentCompanyContext)) return;

    if (owner._isRealtimeRefreshing) {
      owner._realtimeRefreshPending = true;
      return;
    }

    owner._isRealtimeRefreshing = true;
    try {
      do {
        owner._realtimeRefreshPending = false;
        await _refreshDriversOnce(currentCompanyContext);
      } while (owner._realtimeRefreshPending &&
          owner._isCurrentMutationContext(currentCompanyContext));
    } finally {
      owner._isRealtimeRefreshing = false;
    }
  }

  Future<void> _refreshDriversOnce(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    final owner = this as DriversCubit;
    if (!owner._isCurrentMutationContext(currentCompanyContext)) return;

    final previous = state;
    if (previous is! DriversLoaded) {
      await owner.loadDrivers(currentCompanyContext);
      return;
    }

    final requestId = ++owner._loadRequestId;
    final result = await owner.getDriversUseCase(
      GetDriversParams(currentCompanyContext: currentCompanyContext),
    );

    if (!owner._isCurrentMutationContext(currentCompanyContext) ||
        requestId != owner._loadRequestId) {
      return;
    }

    final latest = state;
    if (latest is! DriversLoaded ||
        latest.currentCompanyContext.companyId !=
            currentCompanyContext.companyId) {
      return;
    }

    final failure = result.failureOrNull;
    if (failure != null) {
      if (failure is PermissionFailure || failure is AuthFailure) {
        ++owner._activityRequestId;
        ++owner._imageUrlsRequestId;
        emit(DriversFailure(failure));
      } else {
        emit(latest.copyWith(refreshFailure: failure));
      }
      return;
    }

    final drivers = result.dataOrNull ?? const <Driver>[];
    final oldSelectedId = latest.selectedDriver?.id;
    Driver? selected;
    for (final driver in drivers) {
      if (driver.id == oldSelectedId) {
        selected = driver;
        break;
      }
    }

    final selectionRemoved = oldSelectedId != null && selected == null;
    if (selectionRemoved) {
      ++owner._activityRequestId;
      ++owner._imageUrlsRequestId;
    }
    emit(
      latest.copyWith(
        allDrivers: drivers,
        selectedDriver: selected,
        selectedDriverActivity: selectionRemoved
            ? const []
            : latest.selectedDriverActivity,
        selectedDriverActivityTimestampsByLogId: selectionRemoved
            ? const {}
            : latest.selectedDriverActivityTimestampsByLogId,
        isActivityLoading: selectionRemoved ? false : latest.isActivityLoading,
        activityFailure: selectionRemoved ? null : latest.activityFailure,
        selectedDriverImageUrls: selectionRemoved
            ? DriverImageUrls.empty
            : latest.selectedDriverImageUrls,
        isImageUrlsLoading: selectionRemoved ? false : latest.isImageUrlsLoading,
        imageUrlsFailure: selectionRemoved ? null : latest.imageUrlsFailure,
        refreshFailure: null,
      ),
    );

    if (selected != null) {
      unawaited(owner.loadDriverActivity(selected));
      unawaited(owner.loadDriverImageUrls(selected));
    }
  }
}
