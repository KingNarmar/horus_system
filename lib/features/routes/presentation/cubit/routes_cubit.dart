import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_status_filter.dart';
import '../../domain/policies/routes_permission_policy.dart';
import '../../domain/usecases/routes_usecases.dart';
import 'routes_state.dart';

class RoutesCubit extends Cubit<RoutesState> {
  final GetRoutesUseCase getRoutesUseCase;
  final SaveRouteUseCase saveRouteUseCase;
  final DeactivateRouteUseCase deactivateRouteUseCase;
  final ReactivateRouteUseCase reactivateRouteUseCase;
  final GetEntityAuditLogsUseCase getRouteAuditLogsUseCase;

  final ConvertInstantsToBusinessLocalDateTimesUseCase
  convertInstantsToBusinessLocalDateTimesUseCase;
  int _activityRequestId = 0;
  int _loadRequestId = 0;

  CurrentCompanyContext? _currentCompanyContext;

  RoutesCubit({
    required this.getRoutesUseCase,
    required this.saveRouteUseCase,
    required this.deactivateRouteUseCase,
    required this.reactivateRouteUseCase,
    required this.getRouteAuditLogsUseCase,
    required this.convertInstantsToBusinessLocalDateTimesUseCase,
  }) : super(const RoutesInitial());

  Future<void> loadRoutes(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final loadRequestId = ++_loadRequestId;
    ++_activityRequestId;

    final previous = state;
    final searchQuery = previous is RoutesLoaded ? previous.searchQuery : '';
    final statusFilter = previous is RoutesLoaded
        ? previous.statusFilter
        : RouteStatusFilter.active;

    emit(const RoutesLoading());

    final result = await getRoutesUseCase(
      GetRoutesParams(currentCompanyContext: currentCompanyContext),
    );

    if (isClosed || loadRequestId != _loadRequestId) return;

    result.when(
      success: (routes) {
        emit(
          RoutesLoaded(
            currentCompanyContext: currentCompanyContext,
            allRoutes: routes,
            canManageRoutes: RoutesPermissionPolicy.canManageRoutes(
              currentCompanyContext.role,
            ),
            searchQuery: searchQuery,
            statusFilter: statusFilter,
          ),
        );
      },
      failure: (failure) => emit(RoutesFailure(failure)),
    );
  }

  void setSearchQuery(String query) {
    _mapLoaded((state) => state.copyWith(searchQuery: query));
  }

  void setStatusFilter(RouteStatusFilter filter) {
    _mapLoaded((state) => state.copyWith(statusFilter: filter));
  }

  Future<void> loadRouteActivity(RouteEntity route) async {
    final current = state;
    if (isClosed || current is! RoutesLoaded) return;
    final context = current.currentCompanyContext;
    if (route.companyId != context.companyId) return;
    final requestId = ++_activityRequestId;
    emit(
      current.copyWith(
        selectedRoute: route,
        selectedRouteActivity: const [],
        selectedRouteActivityTimestampsByLogId: const {},
        isActivityLoading: true,
        activityFailure: null,
      ),
    );
    final result = await getRouteAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: context.companyId,
        module: AuditModule.routes,
        entityType: AuditEntityType.route,
        entityId: route.id,
      ),
    );
    if (!_isCurrentActivity(requestId, context.companyId, route.id)) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(
        (state as RoutesLoaded).copyWith(
          isActivityLoading: false,
          activityFailure: failure,
        ),
      );
      return;
    }
    final activity = result.dataOrNull!;
    final projected = await convertInstantsToBusinessLocalDateTimesUseCase(
      ConvertInstantsToBusinessLocalDateTimesParams(
        timeZoneId: context.company.businessTimezone ?? '',
        instantsByKey: {for (final log in activity) log.id: log.createdAt},
      ),
    );
    if (!_isCurrentActivity(requestId, context.companyId, route.id)) return;
    final latest = state as RoutesLoaded;
    final projectionFailure = projected.failureOrNull;
    if (projectionFailure != null) {
      emit(
        latest.copyWith(
          isActivityLoading: false,
          activityFailure: projectionFailure,
        ),
      );
      return;
    }
    emit(
      latest.copyWith(
        selectedRouteActivity: activity,
        selectedRouteActivityTimestampsByLogId: projected.dataOrNull!,
        isActivityLoading: false,
        activityFailure: null,
      ),
    );
  }

  bool _isCurrentActivity(int requestId, String companyId, String entityId) {
    final current = state;
    return !isClosed &&
        requestId == _activityRequestId &&
        current is RoutesLoaded &&
        current.currentCompanyContext.companyId == companyId &&
        current.selectedRoute?.id == entityId;
  }

  void clearRouteActivity() {
    ++_activityRequestId;
    final current = state;
    if (current is RoutesLoaded) {
      emit(
        current.copyWith(
          selectedRoute: null,
          selectedRouteActivity: const [],
          selectedRouteActivityTimestampsByLogId: const {},
          isActivityLoading: false,
          activityFailure: null,
        ),
      );
    }
  }

  Future<void> saveRoute({
    RouteEntity? route,
    required String loadingLocation,
    required String unloadingLocation,
    String? governorateFrom,
    String? governorateTo,
    double? defaultFreightPrice,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) return;

    final result = await saveRouteUseCase(
      SaveRouteParams(
        currentCompanyContext: context,
        id: route?.id,
        loadingLocation: loadingLocation,
        unloadingLocation: unloadingLocation,
        governorateFrom: governorateFrom,
        governorateTo: governorateTo,
        defaultFreightPrice: defaultFreightPrice,
        notes: notes,
      ),
    );

    result.when(
      success: _upsertRoute,
      failure: (failure) => emit(RoutesFailure(failure)),
    );
  }

  Future<void> deactivateRoute(RouteEntity route) {
    return _changeRouteActiveState(
      id: route.id,
      action: deactivateRouteUseCase.call,
    );
  }

  Future<void> reactivateRoute(RouteEntity route) {
    return _changeRouteActiveState(
      id: route.id,
      action: reactivateRouteUseCase.call,
    );
  }

  Future<void> _changeRouteActiveState({
    required String id,
    required Future<Result<RouteEntity>> Function(RouteActiveStateParams params)
    action,
  }) async {
    final context = _currentCompanyContext;
    if (context == null || _isRouteActionRunning(id)) return;

    _setRouteActionRunning(id, true);

    final result = await action(
      RouteActiveStateParams(currentCompanyContext: context, id: id),
    );

    _setRouteActionRunning(id, false);

    result.when(
      success: _upsertRoute,
      failure: (failure) => emit(RoutesFailure(failure)),
    );
  }

  void _upsertRoute(RouteEntity route) {
    _mapLoaded((state) {
      return state.copyWith(
        allRoutes: _upsertRouteInList(state.allRoutes, route),
        selectedRoute: state.selectedRoute?.id == route.id
            ? route
            : state.selectedRoute,
      );
    });
  }

  bool _isRouteActionRunning(String id) {
    final current = state;
    return current is RoutesLoaded && current.isActiveStateChanging(id);
  }

  void _setRouteActionRunning(String id, bool isRunning) {
    _mapLoaded((state) {
      final ids = {...state.activeStateChangingRouteIds};

      if (isRunning) {
        ids.add(id);
      } else {
        ids.remove(id);
      }

      return state.copyWith(activeStateChangingRouteIds: ids);
    });
  }

  void _mapLoaded(RoutesLoaded Function(RoutesLoaded state) mapper) {
    final current = state;
    if (current is RoutesLoaded) {
      emit(mapper(current));
    }
  }
}

List<RouteEntity> _upsertRouteInList(
  List<RouteEntity> routes,
  RouteEntity next,
) {
  final index = routes.indexWhere((route) => route.id == next.id);

  if (index == -1) {
    return [next, ...routes];
  }

  final updated = [...routes];
  updated[index] = next;
  return updated;
}
