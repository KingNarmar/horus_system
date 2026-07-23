import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../expenses/domain/entities/trip_expense.dart';
import '../../../expenses/domain/entities/trip_expense_paid_by.dart';
import '../../../expenses/domain/policies/trip_expenses_permission_policy.dart';
import '../../../expenses/domain/usecases/trip_expenses_usecases.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_filter.dart';
import '../../domain/policies/trips_permission_policy.dart';
import '../../domain/usecases/trips_usecases.dart';
import 'trips_state.dart';

class TripsCubit extends Cubit<TripsState> {
  final GetTripsUseCase getTripsUseCase;
  final GetTripDetailsUseCase getTripDetailsUseCase;
  final GetTripFormLookupsUseCase getTripFormLookupsUseCase;
  final CreateTripUseCase createTripUseCase;
  final SaveTripUseCase saveTripUseCase;
  final UpdateTripStatusUseCase updateTripStatusUseCase;
  final GetTripStatusHistoryUseCase getTripStatusHistoryUseCase;
  final CalculateTripNetProfitUseCase calculateTripNetProfitUseCase;
  final GetEntityAuditLogsUseCase getTripAuditLogsUseCase;
  final GetTripExpensesUseCase getTripExpensesUseCase;
  final GetExpenseTypesUseCase getExpenseTypesUseCase;
  final AddTripExpenseUseCase addTripExpenseUseCase;
  final UpdateTripExpenseUseCase updateTripExpenseUseCase;

  CurrentCompanyContext? _currentCompanyContext;

  TripsCubit({
    required this.getTripsUseCase,
    required this.getTripDetailsUseCase,
    required this.getTripFormLookupsUseCase,
    required this.createTripUseCase,
    required this.saveTripUseCase,
    required this.updateTripStatusUseCase,
    required this.getTripStatusHistoryUseCase,
    required this.calculateTripNetProfitUseCase,
    required this.getTripAuditLogsUseCase,
    required this.getTripExpensesUseCase,
    required this.getExpenseTypesUseCase,
    required this.addTripExpenseUseCase,
    required this.updateTripExpenseUseCase,
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
            canManageTripExpenses:
                TripExpensesPermissionPolicy.canManageTripExpenses(
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

  Future<void> loadTripFormLookups() async {
    final current = state;
    if (current is! TripsLoaded || current.isFormLookupsLoading) return;

    if (current.formLookups != null && current.formLookupsFailure == null) {
      return;
    }

    emit(
      current.copyWith(isFormLookupsLoading: true, formLookupsFailure: null),
    );

    final result = await getTripFormLookupsUseCase(
      GetTripFormLookupsParams(
        currentCompanyContext: current.currentCompanyContext,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (lookups) {
        emit(
          latestState.copyWith(
            formLookups: lookups,
            isFormLookupsLoading: false,
            formLookupsFailure: null,
          ),
        );
      },
      failure: (failure) {
        emit(
          latestState.copyWith(
            isFormLookupsLoading: false,
            formLookupsFailure: failure,
          ),
        );
      },
    );
  }

  Future<void> loadTripDetails(TripEntity trip) async {
    final current = state;
    if (current is! TripsLoaded) return;

    emit(
      current.copyWith(
        selectedTrip: trip,
        selectedTripNetProfit: null,
        selectedTripActivity: const [],
        selectedTripStatusHistory: const [],
        selectedTripExpenses: const [],
        isDetailsLoading: true,
        isActivityLoading: true,
        isStatusHistoryLoading: true,
        isExpensesLoading: true,
        detailsFailure: null,
        activityFailure: null,
        statusHistoryFailure: null,
        expensesFailure: null,
      ),
    );

    await _loadSelectedTripDetails(trip);
    await _loadSelectedTripExpenses(trip);
    await _loadExpenseTypesIfNeeded();
    await _loadSelectedTripStatusHistory(trip);
    await _loadSelectedTripActivity(trip);
  }

  void clearTripDetails() {
    final current = state;
    if (current is TripsLoaded) {
      emit(
        current.copyWith(
          selectedTrip: null,
          selectedTripNetProfit: null,
          selectedTripActivity: const [],
          selectedTripStatusHistory: const [],
          selectedTripExpenses: const [],
          isDetailsLoading: false,
          isActivityLoading: false,
          isStatusHistoryLoading: false,
          isExpensesLoading: false,
          detailsFailure: null,
          activityFailure: null,
          statusHistoryFailure: null,
          expensesFailure: null,
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

  Future<void> saveTripExpense({
    TripExpense? expense,
    required String tripId,
    required String? expenseTypeId,
    required String expenseName,
    required double amount,
    required TripExpensePaidBy paidBy,
    required DateTime expenseDate,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    final current = state;
    if (context == null ||
        current is! TripsLoaded ||
        current.isTripExpenseSaving) {
      return;
    }

    emit(current.copyWith(isTripExpenseSaving: true));

    final result = expense == null
        ? await addTripExpenseUseCase(
            AddTripExpenseParams(
              currentCompanyContext: context,
              tripId: tripId,
              expenseTypeId: expenseTypeId,
              expenseName: expenseName,
              amount: amount,
              paidBy: paidBy,
              expenseDate: expenseDate,
              notes: notes,
            ),
          )
        : await updateTripExpenseUseCase(
            UpdateTripExpenseParams(
              currentCompanyContext: context,
              id: expense.id,
              tripId: tripId,
              expenseTypeId: expenseTypeId,
              expenseName: expenseName,
              amount: amount,
              paidBy: paidBy,
              expenseDate: expenseDate,
              notes: notes,
            ),
          );

    _mapLoaded((state) => state.copyWith(isTripExpenseSaving: false));

    result.when(
      success: (_) async {
        final latest = state;
        if (latest is! TripsLoaded || latest.selectedTrip?.id != tripId) return;
        final selectedTrip = latest.selectedTrip!;
        await _loadSelectedTripExpenses(selectedTrip);
        await _loadSelectedTripDetails(selectedTrip);
        await _loadSelectedTripActivity(selectedTrip);
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

    if (result is Success<TripEntity>) {
      final details = result.data;
      final netProfit = await _calculateSelectedTripNetProfit(details);
      final currentAfterCalculation = state;
      if (currentAfterCalculation is! TripsLoaded) return;

      emit(
        currentAfterCalculation.copyWith(
          selectedTrip: details,
          selectedTripNetProfit: netProfit,
          isDetailsLoading: false,
          detailsFailure: null,
          allTrips: _upsertTripInList(
            currentAfterCalculation.allTrips,
            details,
          ),
        ),
      );
      return;
    }

    if (result is FailureResult<TripEntity>) {
      emit(
        latestState.copyWith(
          isDetailsLoading: false,
          detailsFailure: result.failure,
        ),
      );
    }
  }

  Future<void> _loadSelectedTripExpenses(TripEntity trip) async {
    final current = state;
    if (current is! TripsLoaded) return;

    emit(current.copyWith(isExpensesLoading: true, expensesFailure: null));

    final result = await getTripExpensesUseCase(
      GetTripExpensesParams(
        currentCompanyContext: current.currentCompanyContext,
        tripId: trip.id,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (expenses) {
        emit(
          latestState.copyWith(
            selectedTripExpenses: expenses,
            isExpensesLoading: false,
            expensesFailure: null,
          ),
        );
      },
      failure: (failure) {
        emit(
          latestState.copyWith(
            isExpensesLoading: false,
            expensesFailure: failure,
          ),
        );
      },
    );
  }

  Future<void> _loadExpenseTypesIfNeeded() async {
    final current = state;
    if (current is! TripsLoaded || current.isExpenseTypesLoading) return;
    if (current.expenseTypes.isNotEmpty &&
        current.expenseTypesFailure == null) {
      return;
    }

    emit(
      current.copyWith(isExpenseTypesLoading: true, expenseTypesFailure: null),
    );

    final result = await getExpenseTypesUseCase(
      GetExpenseTypesParams(
        currentCompanyContext: current.currentCompanyContext,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (types) {
        emit(
          latestState.copyWith(
            expenseTypes: types,
            isExpenseTypesLoading: false,
            expenseTypesFailure: null,
          ),
        );
      },
      failure: (failure) {
        emit(
          latestState.copyWith(
            isExpenseTypesLoading: false,
            expenseTypesFailure: failure,
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

  Future<double?> _calculateSelectedTripNetProfit(TripEntity trip) async {
    final result = await calculateTripNetProfitUseCase(
      CalculateTripNetProfitParams(
        freightPrice: trip.freightPrice,
        totalExpenses: trip.totalExpenses,
      ),
    );

    return result.dataOrNull;
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
