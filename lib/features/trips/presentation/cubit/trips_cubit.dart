import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../expense_types/domain/entities/expense_type.dart';
import '../../../expense_types/domain/usecases/get_expense_type_catalog_usecase.dart';
import '../../../expense_types/domain/usecases/get_ledger_eligible_expense_types_usecase.dart';
import '../../../expenses/domain/entities/expense_funding_source.dart';
import '../../../expenses/domain/entities/expense_ledger_entry.dart';
import '../../../expenses/domain/policies/expense_ledger_permission_policy.dart';
import '../../../expenses/domain/usecases/create_trip_expense_usecase.dart';
import '../../../expenses/domain/usecases/get_trip_expense_ledger_entries_usecase.dart';
import '../../../expenses/domain/usecases/void_expense_ledger_entry_usecase.dart';
import '../../domain/entities/trip_business_local_timestamps.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_filter.dart';
import '../../domain/entities/trip_status_history.dart';
import '../../domain/entities/trip_timestamp_instants.dart';
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
  final GetTripBusinessLocalTimestampsUseCase
  getTripBusinessLocalTimestampsUseCase;
  final ResolveTripBusinessLocalTimestampsUseCase
  resolveTripBusinessLocalTimestampsUseCase;
  final ConvertInstantsToBusinessLocalDateTimesUseCase
  convertInstantsToBusinessLocalDateTimesUseCase;
  final GetEntityAuditLogsUseCase getTripAuditLogsUseCase;
  final GetTripExpenseLedgerEntriesUseCase getTripExpenseLedgerEntriesUseCase;
  final GetExpenseTypeCatalogUseCase getExpenseTypeCatalogUseCase;
  final GetLedgerEligibleExpenseTypesUseCase
  getLedgerEligibleExpenseTypesUseCase;
  final CreateTripExpenseUseCase createTripExpenseUseCase;
  final VoidExpenseLedgerEntryUseCase voidExpenseLedgerEntryUseCase;

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
    required this.getTripBusinessLocalTimestampsUseCase,
    required this.resolveTripBusinessLocalTimestampsUseCase,
    required this.convertInstantsToBusinessLocalDateTimesUseCase,
    required this.getTripAuditLogsUseCase,
    required this.getTripExpenseLedgerEntriesUseCase,
    required this.getExpenseTypeCatalogUseCase,
    required this.getLedgerEligibleExpenseTypesUseCase,
    required this.createTripExpenseUseCase,
    required this.voidExpenseLedgerEntryUseCase,
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
    if (result is FailureResult<List<TripEntity>>) {
      emit(TripsFailure(result.failure));
      return;
    }

    final trips = (result as Success<List<TripEntity>>).data;
    final localTimestampsResult = await _loadBusinessLocalTimestamps(
      trips,
      currentCompanyContext,
    );
    if (localTimestampsResult
        is FailureResult<Map<String, TripBusinessLocalTimestamps>>) {
      emit(TripsFailure(localTimestampsResult.failure));
      return;
    }

    emit(
      TripsLoaded(
        currentCompanyContext: currentCompanyContext,
        allTrips: trips,
        businessLocalTimestampsByTripId:
            (localTimestampsResult
                    as Success<Map<String, TripBusinessLocalTimestamps>>)
                .data,
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
            ExpenseLedgerPermissionPolicy.canManageTripAttributed(
              currentCompanyContext.role,
            ),
        searchQuery: searchQuery,
        statusFilter: statusFilter,
      ),
    );
  }

  Future<Result<Map<String, TripBusinessLocalTimestamps>>>
  _loadBusinessLocalTimestamps(
    List<TripEntity> trips,
    CurrentCompanyContext currentCompanyContext,
  ) async {
    final values = <String, TripBusinessLocalTimestamps>{};
    for (final trip in trips) {
      final result = await getTripBusinessLocalTimestampsUseCase(
        GetTripBusinessLocalTimestampsParams(
          currentCompanyContext: currentCompanyContext,
          trip: trip,
        ),
      );
      if (result is FailureResult<TripBusinessLocalTimestamps>) {
        return FailureResult(result.failure);
      }
      values[trip.id] = (result as Success<TripBusinessLocalTimestamps>).data;
    }
    return Success(values);
  }

  Future<Result<Map<String, BusinessLocalDateTime>>> _convertCompanyInstants(
    CurrentCompanyContext currentCompanyContext,
    Map<String, DateTime> instantsByKey,
  ) {
    return convertInstantsToBusinessLocalDateTimesUseCase(
      ConvertInstantsToBusinessLocalDateTimesParams(
        timeZoneId: currentCompanyContext.company.businessTimezone ?? '',
        instantsByKey: instantsByKey,
      ),
    );
  }

  void _upsertTrip(
    TripEntity trip, {
    TripBusinessLocalTimestamps? businessLocalTimestamps,
  }) {
    _mapLoaded((state) {
      final localTimestamps = {...state.businessLocalTimestampsByTripId};
      if (businessLocalTimestamps != null) {
        localTimestamps[trip.id] = businessLocalTimestamps;
      }
      return state.copyWith(
        allTrips: _upsertTripInList(state.allTrips, trip),
        businessLocalTimestampsByTripId: localTimestamps,
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
    if (current is TripsLoaded) emit(mapper(current));
  }
}

List<TripEntity> _upsertTripInList(List<TripEntity> trips, TripEntity next) {
  final index = trips.indexWhere((trip) => trip.id == next.id);
  if (index == -1) return [next, ...trips];
  final updated = [...trips];
  updated[index] = next;
  return updated;
}
