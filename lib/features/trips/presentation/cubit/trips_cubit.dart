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

part 'trips_details_actions.dart';
part 'trips_expense_actions.dart';
part 'trips_filter_actions.dart';
part 'trips_form_lookup_actions.dart';
part 'trips_mutation_actions.dart';

class TripsCubit extends Cubit<TripsState>
    with
        TripsFilterActions,
        TripsFormLookupActions,
        TripsDetailsActions,
        TripsExpenseActions,
        TripsMutationActions {
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
