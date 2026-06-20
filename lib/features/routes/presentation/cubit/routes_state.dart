import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_status_filter.dart';

const Object _notSet = Object();

sealed class RoutesState {
  const RoutesState();
}

class RoutesInitial extends RoutesState {
  const RoutesInitial();
}

class RoutesLoading extends RoutesState {
  const RoutesLoading();
}

class RoutesLoaded extends RoutesState {
  final CurrentCompanyContext currentCompanyContext;
  final List<RouteEntity> allRoutes;
  final bool canManageRoutes;
  final String searchQuery;
  final RouteStatusFilter statusFilter;
  final Set<String> activeStateChangingRouteIds;
  final RouteEntity? selectedRoute;
  final List<AuditLog> selectedRouteActivity;
  final bool isActivityLoading;
  final Failure? activityFailure;

  const RoutesLoaded({
    required this.currentCompanyContext,
    required this.allRoutes,
    required this.canManageRoutes,
    this.searchQuery = '',
    this.statusFilter = RouteStatusFilter.active,
    this.activeStateChangingRouteIds = const <String>{},
    this.selectedRoute,
    this.selectedRouteActivity = const <AuditLog>[],
    this.isActivityLoading = false,
    this.activityFailure,
  });

  bool isActiveStateChanging(String id) {
    return activeStateChangingRouteIds.contains(id);
  }

  List<RouteEntity> get routes {
    final query = searchQuery.trim().toLowerCase();

    return allRoutes.where((route) {
      if (!statusFilter.matches(route.isActive)) return false;
      if (query.isEmpty) return true;

      return [
        route.loadingLocation,
        route.unloadingLocation,
        route.governorateFrom,
        route.governorateTo,
        route.defaultFreightPrice?.toString(),
        route.notes,
      ].whereType<String>().any((value) {
        return value.toLowerCase().contains(query);
      });
    }).toList();
  }

  RoutesLoaded copyWith({
    List<RouteEntity>? allRoutes,
    bool? canManageRoutes,
    String? searchQuery,
    RouteStatusFilter? statusFilter,
    Set<String>? activeStateChangingRouteIds,
    Object? selectedRoute = _notSet,
    List<AuditLog>? selectedRouteActivity,
    bool? isActivityLoading,
    Object? activityFailure = _notSet,
  }) {
    return RoutesLoaded(
      currentCompanyContext: currentCompanyContext,
      allRoutes: allRoutes ?? this.allRoutes,
      canManageRoutes: canManageRoutes ?? this.canManageRoutes,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      activeStateChangingRouteIds:
          activeStateChangingRouteIds ?? this.activeStateChangingRouteIds,
      selectedRoute: selectedRoute == _notSet
          ? this.selectedRoute
          : selectedRoute as RouteEntity?,
      selectedRouteActivity:
          selectedRouteActivity ?? this.selectedRouteActivity,
      isActivityLoading: isActivityLoading ?? this.isActivityLoading,
      activityFailure: activityFailure == _notSet
          ? this.activityFailure
          : activityFailure as Failure?,
    );
  }
}

class RoutesFailure extends RoutesState {
  final Failure failure;

  const RoutesFailure(this.failure);
}
