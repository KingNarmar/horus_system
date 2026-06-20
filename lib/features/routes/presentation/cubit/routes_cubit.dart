import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log.dart';
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

  CurrentCompanyContext? _currentCompanyContext;

  RoutesCubit({
    required this.getRoutesUseCase,
    required this.saveRouteUseCase,
    required this.deactivateRouteUseCase,
    required this.reactivateRouteUseCase,
    required this.getRouteAuditLogsUseCase,
  }) : super(const RoutesInitial());

  Future<void> loadRoutes(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;

    final previous = state;
    final searchQuery = previous is RoutesLoaded ? previous.searchQuery : '';
    final statusFilter = previous is RoutesLoaded
        ? previous.statusFilter
        : RouteStatusFilter.active;

    emit(const RoutesLoading());

    final result = await getRoutesUseCase(
      GetRoutesParams(currentCompanyContext: currentCompanyContext),
    );

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

  Future<Result<List<AuditLog>>> getRouteActivity(RouteEntity route) {
    final context = _currentCompanyContext;
    if (context == null) {
      final current = state;
      if (current is RoutesLoaded) {
        return getRouteAuditLogsUseCase(
          GetEntityAuditLogsParams(
            companyId: current.currentCompanyContext.companyId,
            module: AuditModule.routes,
            entityType: AuditEntityType.route,
            entityId: route.id,
          ),
        );
      }
    }

    return getRouteAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: context!.companyId,
        module: AuditModule.routes,
        entityType: AuditEntityType.route,
        entityId: route.id,
      ),
    );
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
