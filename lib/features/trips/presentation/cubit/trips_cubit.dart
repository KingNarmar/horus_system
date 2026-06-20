import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_filter.dart';
import '../../domain/policies/trips_permission_policy.dart';
import '../../domain/usecases/trips_usecases.dart';
import 'trips_state.dart';

class TripsCubit extends Cubit<TripsState> {
  final GetTripsUseCase getTripsUseCase;
  final GetTripDetailsUseCase getTripDetailsUseCase;
  final CreateTripUseCase createTripUseCase;
  final SaveTripUseCase saveTripUseCase;
  final UpdateTripStatusUseCase updateTripStatusUseCase;
  final GetTripStatusHistoryUseCase getTripStatusHistoryUseCase;
  final CalculateTripNetProfitUseCase calculateTripNetProfitUseCase;
  final GetEntityAuditLogsUseCase getTripAuditLogsUseCase;

  CurrentCompanyContext? _currentCompanyContext;

  TripsCubit({
    required this.getTripsUseCase,
    required this.getTripDetailsUseCase,
    required this.createTripUseCase,
    required this.saveTripUseCase,
    required this.updateTripStatusUseCase,
    required this.getTripStatusHistoryUseCase,
    required this.calculateTripNetProfitUseCase,
    required this.getTripAuditLogsUseCase,
  }) : super(const TripsInitial());

  Future<void> loadTrips(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;

    final previous = state;
    final searchQuery = previous is TripsLoaded ? previous.searchQuery : '';
    final statusFilter = previous is TripsLoaded
        ? previous.statusFilter
        : TripStatusFilter.open;

    emit(const TripsLoading());

    final result = await getTripsUseCase(
      GetTripsParams(currentCompanyContext: currentCompanyContext),
    );

    result.when(
      success: (trips) {
        emit(
          TripsLoaded(
            currentCompanyContext: currentCompanyContext,
            allTrips: trips,
            canManageTrips: TripsPermissionPolicy.canManageTrips(
              currentCompanyContext.role,
            ),
            canUpdateTripStatus: TripsPermissionPolicy.canUpdateTripStatus(
              currentCompanyContext.role,
            ),
            canViewTripFinancials: TripsPermissionPolicy.canViewTripFinancials(
              currentCompanyContext.role,
            ),
            searchQuery: searchQuery,
            statusFilter: statusFilter,
          ),
        );
      },
      failure: (failure) => emit(TripsFailure(failure)),
    );
  }

  void setSearchQuery(String query) {
    _mapLoaded((state) => state.copyWith(searchQuery: query));
  }

  void setStatusFilter(TripStatusFilter filter) {
    _mapLoaded((state) => state.copyWith(statusFilter: filter));
  }

  Future<void> loadTripDetails(TripEntity trip) async {
    final current = state;
    if (current is! TripsLoaded) return;

    emit(
      current.copyWith(
        selectedTrip: trip,
        selectedTripActivity: const [],
        selectedTripStatusHistory: const [],
        isDetailsLoading: true,
        isActivityLoading: true,
        isStatusHistoryLoading: true,
        detailsFailure: null,
        activityFailure: null,
        statusHistoryFailure: null,
      ),
    );

    await _loadSelectedTripDetails(trip);
    await _loadSelectedTripStatusHistory(trip);
    await _loadSelectedTripActivity(trip);
  }

  void clearTripDetails() {
    final current = state;
    if (current is TripsLoaded) {
      emit(
        current.copyWith(
          selectedTrip: null,
          selectedTripActivity: const [],
          selectedTripStatusHistory: const [],
          isDetailsLoading: false,
          isActivityLoading: false,
          isStatusHistoryLoading: false,
          detailsFailure: null,
          activityFailure: null,
          statusHistoryFailure: null,
        ),
      );
    }
  }

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
    DateTime? scheduledLoadingAt,
    DateTime? scheduledDeliveryAt,
    DateTime? actualLoadingAt,
    DateTime? actualDeliveryAt,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) return;

    final result = trip == null
        ? await createTripUseCase(
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
              scheduledLoadingAt: scheduledLoadingAt,
              scheduledDeliveryAt: scheduledDeliveryAt,
              actualLoadingAt: actualLoadingAt,
              actualDeliveryAt: actualDeliveryAt,
              notes: notes,
            ),
          )
        : await saveTripUseCase(
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
              scheduledLoadingAt: scheduledLoadingAt,
              scheduledDeliveryAt: scheduledDeliveryAt,
              actualLoadingAt: actualLoadingAt,
              actualDeliveryAt: actualDeliveryAt,
              notes: notes,
            ),
          );

    result.when(
      success: _upsertTrip,
      failure: (failure) => emit(TripsFailure(failure)),
    );
  }

  Future<void> updateTripStatus({
    required TripEntity trip,
    required TripStatus newStatus,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null || _isTripStatusChanging(trip.id)) return;

    _setTripStatusChanging(trip.id, true);

    final result = await updateTripStatusUseCase(
      UpdateTripStatusParams(
        currentCompanyContext: context,
        id: trip.id,
        newStatus: newStatus,
        notes: notes,
      ),
    );

    _setTripStatusChanging(trip.id, false);

    result.when(
      success: (updatedTrip) async {
        _upsertTrip(updatedTrip);

        final current = state;
        if (current is TripsLoaded &&
            current.selectedTrip?.id == updatedTrip.id) {
          await _loadSelectedTripStatusHistory(updatedTrip);
          await _loadSelectedTripActivity(updatedTrip);
        }
      },
      failure: (failure) => emit(TripsFailure(failure)),
    );
  }

  Future<Result<double>> calculateNetProfit({
    required double? freightPrice,
    required double? totalExpenses,
  }) {
    return calculateTripNetProfitUseCase(
      CalculateTripNetProfitParams(
        freightPrice: freightPrice,
        totalExpenses: totalExpenses,
      ),
    );
  }

  Future<void> _loadSelectedTripDetails(TripEntity trip) async {
    final current = state;
    if (current is! TripsLoaded) return;

    final result = await getTripDetailsUseCase(
      GetTripDetailsParams(
        currentCompanyContext: current.currentCompanyContext,
        id: trip.id,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (details) {
        emit(
          latestState.copyWith(
            selectedTrip: details,
            isDetailsLoading: false,
            detailsFailure: null,
            allTrips: _upsertTripInList(latestState.allTrips, details),
          ),
        );
      },
      failure: (failure) {
        emit(
          latestState.copyWith(
            isDetailsLoading: false,
            detailsFailure: failure,
          ),
        );
      },
    );
  }

  Future<void> _loadSelectedTripStatusHistory(TripEntity trip) async {
    final current = state;
    if (current is! TripsLoaded) return;

    emit(
      current.copyWith(
        isStatusHistoryLoading: true,
        statusHistoryFailure: null,
      ),
    );

    final result = await getTripStatusHistoryUseCase(
      GetTripStatusHistoryParams(
        currentCompanyContext: current.currentCompanyContext,
        tripId: trip.id,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (history) {
        emit(
          latestState.copyWith(
            selectedTripStatusHistory: history,
            isStatusHistoryLoading: false,
            statusHistoryFailure: null,
          ),
        );
      },
      failure: (failure) {
        emit(
          latestState.copyWith(
            isStatusHistoryLoading: false,
            statusHistoryFailure: failure,
          ),
        );
      },
    );
  }

  Future<void> _loadSelectedTripActivity(TripEntity trip) async {
    final current = state;
    if (current is! TripsLoaded) return;

    emit(current.copyWith(isActivityLoading: true, activityFailure: null));

    final result = await getTripAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: current.currentCompanyContext.companyId,
        module: AuditModule.trips,
        entityType: AuditEntityType.trip,
        entityId: trip.id,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (activity) {
        emit(
          latestState.copyWith(
            selectedTripActivity: activity,
            isActivityLoading: false,
            activityFailure: null,
          ),
        );
      },
      failure: (failure) {
        emit(
          latestState.copyWith(
            isActivityLoading: false,
            activityFailure: failure,
          ),
        );
      },
    );
  }

  void _upsertTrip(TripEntity trip) {
    _mapLoaded((state) {
      return state.copyWith(
        allTrips: _upsertTripInList(state.allTrips, trip),
        selectedTrip: state.selectedTrip?.id == trip.id
            ? trip
            : state.selectedTrip,
      );
    });
  }

  bool _isTripStatusChanging(String id) {
    final current = state;
    return current is TripsLoaded && current.isStatusChanging(id);
  }

  void _setTripStatusChanging(String id, bool isRunning) {
    _mapLoaded((state) {
      final ids = {...state.statusChangingTripIds};

      if (isRunning) {
        ids.add(id);
      } else {
        ids.remove(id);
      }

      return state.copyWith(statusChangingTripIds: ids);
    });
  }

  void _mapLoaded(TripsLoaded Function(TripsLoaded state) mapper) {
    final current = state;
    if (current is TripsLoaded) {
      emit(mapper(current));
    }
  }
}

List<TripEntity> _upsertTripInList(List<TripEntity> trips, TripEntity next) {
  final index = trips.indexWhere((trip) => trip.id == next.id);

  if (index == -1) {
    return [next, ...trips];
  }

  final updated = [...trips];
  updated[index] = next;
  return updated;
}
