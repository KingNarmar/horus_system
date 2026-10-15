part of 'routes_cubit.dart';

/// Authoritative, company-scoped refresh without replacing the loaded page.
/// One pending refresh is retained while a query or initial load is running.
mixin RoutesRealtimeActions on Cubit<RoutesState> {
  Future<void> refreshRoutes(CurrentCompanyContext currentCompanyContext) async {
    final owner = this as RoutesCubit;
    if (owner.isClosed ||
        owner._currentCompanyContext?.companyId !=
            currentCompanyContext.companyId) {
      return;
    }

    if (owner._initialLoadInProgress || owner._isRealtimeRefreshing) {
      owner._realtimeRefreshPending = true;
      return;
    }
    if (state is! RoutesLoaded) {
      await owner.loadRoutes(currentCompanyContext);
      return;
    }

    owner._isRealtimeRefreshing = true;
    try {
      do {
        owner._realtimeRefreshPending = false;
        await _refreshRoutesOnce(currentCompanyContext);
      } while (owner._realtimeRefreshPending &&
          !owner.isClosed &&
          owner._currentCompanyContext?.companyId ==
              currentCompanyContext.companyId &&
          state is RoutesLoaded);
    } finally {
      owner._isRealtimeRefreshing = false;
    }
  }

  Future<void> _refreshRoutesOnce(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    final owner = this as RoutesCubit;
    final requestId = ++owner._loadRequestId;
    final result = await owner.getRoutesUseCase(
      GetRoutesParams(currentCompanyContext: currentCompanyContext),
    );
    if (!owner._isCurrentRoutesRequest(currentCompanyContext, requestId)) {
      return;
    }

    final latest = state;
    if (latest is! RoutesLoaded ||
        latest.currentCompanyContext.companyId !=
            currentCompanyContext.companyId) {
      return;
    }

    final failure = result.failureOrNull;
    if (failure != null) {
      if (failure is AuthFailure || failure is PermissionFailure) {
        ++owner._activityRequestId;
        emit(RoutesFailure(failure));
      } else {
        emit(latest.copyWith(refreshFailure: failure));
      }
      return;
    }

    final routes = result.dataOrNull ?? const <RouteEntity>[];
    final selectedId = latest.selectedRoute?.id;
    RouteEntity? selectedRoute;
    if (selectedId != null) {
      for (final route in routes) {
        if (route.id == selectedId) {
          selectedRoute = route;
          break;
        }
      }
    }
    final selectedRemoved = selectedId != null && selectedRoute == null;
    if (selectedRemoved) ++owner._activityRequestId;

    emit(
      latest.copyWith(
        allRoutes: routes,
        selectedRoute: selectedRoute,
        selectedRouteActivity: selectedRemoved
            ? const []
            : latest.selectedRouteActivity,
        selectedRouteActivityTimestampsByLogId: selectedRemoved
            ? const {}
            : latest.selectedRouteActivityTimestampsByLogId,
        isActivityLoading: selectedRemoved ? false : latest.isActivityLoading,
        activityFailure: selectedRemoved ? null : latest.activityFailure,
        refreshFailure: null,
      ),
    );

    if (selectedRoute != null) {
      await owner.loadRouteActivity(selectedRoute);
    }
  }
}
