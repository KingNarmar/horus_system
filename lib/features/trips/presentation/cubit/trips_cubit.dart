import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import '../../../../core/usecases/get_company_business_date_usecase.dart';
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
import '../../../expenses/domain/usecases/can_manage_trip_attributed_expense_usecase.dart';
import '../../../expenses/domain/usecases/create_trip_expense_usecase.dart';
import '../../../expenses/domain/usecases/get_trip_expense_ledger_entries_usecase.dart';
import '../../../expenses/domain/usecases/void_expense_ledger_entry_usecase.dart';
import '../../domain/entities/trip_business_local_timestamps.dart';
import '../../domain/entities/trip_document.dart';
import '../../domain/entities/trip_document_kind.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_status_filter.dart';
import '../../domain/entities/trip_status_history.dart';
import '../../domain/entities/trip_timestamp_instants.dart';
import '../../domain/usecases/get_trip_permissions_usecase.dart';
import '../../domain/usecases/has_required_trip_evidence_usecase.dart';
import '../../domain/usecases/trips_usecases.dart';
import '../models/trip_mutation_result.dart';
import 'trips_state.dart';

part 'trips_details_actions.dart';
part 'trips_document_actions.dart';
part 'trips_expense_actions.dart';
part 'trips_filter_actions.dart';
part 'trips_form_lookup_actions.dart';
part 'trips_mutation_actions.dart';

class TripsCubit extends Cubit<TripsState>
    with
        TripsFilterActions,
        TripsFormLookupActions,
        TripsDetailsActions,
        TripsDocumentActions,
        TripsExpenseActions,
        TripsMutationActions {
  final GetTripsUseCase getTripsUseCase;
  final GetTripPermissionsUseCase getTripPermissionsUseCase;
  final CanManageTripAttributedExpenseUseCase
  canManageTripAttributedExpenseUseCase;
  final GetTripDetailsUseCase getTripDetailsUseCase;
  final GetTripFormLookupsUseCase getTripFormLookupsUseCase;
  final CreateTripUseCase createTripUseCase;
  final SaveTripUseCase saveTripUseCase;
  final UpdateTripStatusUseCase updateTripStatusUseCase;
  final GetTripStatusHistoryUseCase getTripStatusHistoryUseCase;
  final GetTripDocumentsUseCase getTripDocumentsUseCase;
  final HasRequiredTripEvidenceUseCase hasRequiredTripEvidenceUseCase;
  final UploadTripDocumentUseCase uploadTripDocumentUseCase;
  final GetTripDocumentAccessUseCase getTripDocumentAccessUseCase;
  final DownloadTripDocumentUseCase downloadTripDocumentUseCase;
  final RemoveTripDocumentUseCase removeTripDocumentUseCase;
  final ReplaceTripDocumentUseCase replaceTripDocumentUseCase;
  final CalculateTripNetProfitUseCase calculateTripNetProfitUseCase;
  final GetTripBusinessLocalTimestampsUseCase
  getTripBusinessLocalTimestampsUseCase;
  final ResolveTripBusinessLocalTimestampsUseCase
  resolveTripBusinessLocalTimestampsUseCase;
  final ConvertInstantsToBusinessLocalDateTimesUseCase
  convertInstantsToBusinessLocalDateTimesUseCase;
  final GetCompanyBusinessDateUseCase getCompanyBusinessDateUseCase;
  final GetEntityAuditLogsUseCase getTripAuditLogsUseCase;
  final GetTripExpenseLedgerEntriesUseCase getTripExpenseLedgerEntriesUseCase;
  final GetExpenseTypeCatalogUseCase getExpenseTypeCatalogUseCase;
  final GetLedgerEligibleExpenseTypesUseCase
  getLedgerEligibleExpenseTypesUseCase;
  final CreateTripExpenseUseCase createTripExpenseUseCase;
  final VoidExpenseLedgerEntryUseCase voidExpenseLedgerEntryUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _companyRequestGeneration = 0;
  int _detailsRequestGeneration = 0;

  TripsCubit({
    required this.getTripsUseCase,
    required this.getTripPermissionsUseCase,
    required this.canManageTripAttributedExpenseUseCase,
    required this.getTripDetailsUseCase,
    required this.getTripFormLookupsUseCase,
    required this.createTripUseCase,
    required this.saveTripUseCase,
    required this.updateTripStatusUseCase,
    required this.getTripStatusHistoryUseCase,
    required this.getTripDocumentsUseCase,
    required this.hasRequiredTripEvidenceUseCase,
    required this.uploadTripDocumentUseCase,
    required this.getTripDocumentAccessUseCase,
    required this.downloadTripDocumentUseCase,
    required this.removeTripDocumentUseCase,
    required this.replaceTripDocumentUseCase,
    required this.calculateTripNetProfitUseCase,
    required this.getTripBusinessLocalTimestampsUseCase,
    required this.resolveTripBusinessLocalTimestampsUseCase,
    required this.convertInstantsToBusinessLocalDateTimesUseCase,
    required this.getCompanyBusinessDateUseCase,
    required this.getTripAuditLogsUseCase,
    required this.getTripExpenseLedgerEntriesUseCase,
    required this.getExpenseTypeCatalogUseCase,
    required this.getLedgerEligibleExpenseTypesUseCase,
    required this.createTripExpenseUseCase,
    required this.voidExpenseLedgerEntryUseCase,
  }) : super(const TripsInitial());

  Future<void> loadTrips(CurrentCompanyContext currentCompanyContext) async {
    final requestGeneration = ++_companyRequestGeneration;
    _detailsRequestGeneration++;
    _currentCompanyContext = currentCompanyContext;
    final companyId = currentCompanyContext.companyId;

    final previous = state;
    final previousLoaded =
        previous is TripsLoaded &&
            previous.currentCompanyContext.companyId == companyId
        ? previous
        : null;
    final searchQuery = previousLoaded?.searchQuery ?? '';
    final statusFilter = previousLoaded?.statusFilter ?? TripStatusFilter.open;

    emit(const TripsLoading());

    final result = await getTripsUseCase(
      GetTripsParams(currentCompanyContext: currentCompanyContext),
    );
    if (!_isCurrentCompanyRequest(requestGeneration, companyId)) return;

    if (result is FailureResult<List<TripEntity>>) {
      emit(TripsFailure(result.failure));
      return;
    }

    final trips = (result as Success<List<TripEntity>>).data;
    final localTimestampsResult = await _loadBusinessLocalTimestamps(
      trips,
      currentCompanyContext,
    );
    if (!_isCurrentCompanyRequest(requestGeneration, companyId)) return;

    if (localTimestampsResult
        is FailureResult<Map<String, TripBusinessLocalTimestamps>>) {
      emit(TripsFailure(localTimestampsResult.failure));
      return;
    }

    final permissionsResult = await getTripPermissionsUseCase(
      GetTripPermissionsParams(currentCompanyContext: currentCompanyContext),
    );
    if (!_isCurrentCompanyRequest(requestGeneration, companyId)) return;
    final permissionsFailure = permissionsResult.failureOrNull;
    if (permissionsFailure != null) {
      emit(TripsFailure(permissionsFailure));
      return;
    }

    final expensePermissionResult = await canManageTripAttributedExpenseUseCase(
      CanManageTripAttributedExpenseParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (!_isCurrentCompanyRequest(requestGeneration, companyId)) return;
    final expensePermissionFailure = expensePermissionResult.failureOrNull;
    if (expensePermissionFailure != null) {
      emit(TripsFailure(expensePermissionFailure));
      return;
    }

    final permissions = permissionsResult.dataOrNull;
    if (permissions == null) {
      emit(const TripsFailure(UnexpectedFailure()));
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
        canManageTrips: permissions.canManageTrips,
        canUpdateTripStatus: permissions.canUpdateTripStatus,
        canManageTripDocuments: permissions.canManageTripDocuments,
        canViewTripFinancials: permissions.canViewTripFinancials,
        canManageTripExpenses: expensePermissionResult.dataOrNull ?? false,
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

  Future<Result<BusinessDate>> getCurrentBusinessDate() {
    final context = _currentCompanyContext;
    if (context == null) {
      return Future.value(
        const FailureResult<BusinessDate>(UnexpectedFailure()),
      );
    }
    return getCompanyBusinessDateUseCase(
      GetCompanyBusinessDateParams(companyId: context.companyId),
    );
  }

  Future<void> _recalculateSelectedTripFinancials() async {
    final current = state;
    final trip = current is TripsLoaded ? current.selectedTrip : null;
    if (current is! TripsLoaded || trip == null) return;

    final companyGeneration = _companyRequestGeneration;
    final detailsGeneration = _detailsRequestGeneration;
    final companyId = current.currentCompanyContext.companyId;

    final result = await calculateTripNetProfitUseCase(
      CalculateTripNetProfitParams(
        commercialAmount: trip.commercialAmount,
        expenses: current.selectedTripExpenses
            .where((expense) => !expense.isVoided)
            .map((expense) => expense.amount)
            .toList(),
      ),
    );

    if (!_isCurrentDetailsRequest(
      companyGeneration: companyGeneration,
      detailsGeneration: detailsGeneration,
      companyId: companyId,
      tripId: trip.id,
    )) {
      return;
    }

    final latest = state as TripsLoaded;
    result.when(
      success: (summary) => emit(
        latest.copyWith(
          selectedTripTotalExpenses: summary.totalExpenses,
          selectedTripNetProfit: summary.netProfit,
          detailsFailure: null,
        ),
      ),
      failure: (failure) => emit(latest.copyWith(detailsFailure: failure)),
    );
  }

  void _upsertTrip(
    TripEntity trip, {
    TripBusinessLocalTimestamps? businessLocalTimestamps,
  }) {
    _mapLoaded((state) {
      if (state.currentCompanyContext.companyId != trip.companyId) {
        return state;
      }

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

  void _beginTripStatusChange(String id) {
    _mapLoaded((state) {
      final ids = {...state.statusChangingTripIds, id};
      final failures = {...state.statusChangeFailuresByTripId}..remove(id);
      return state.copyWith(
        statusChangingTripIds: ids,
        statusChangeFailuresByTripId: failures,
      );
    });
  }

  void _finishTripStatusChange(String id, {Failure? failure}) {
    _mapLoaded((state) {
      final ids = {...state.statusChangingTripIds}..remove(id);
      final failures = {...state.statusChangeFailuresByTripId};
      if (failure == null) {
        failures.remove(id);
      } else {
        failures[id] = failure;
      }
      return state.copyWith(
        statusChangingTripIds: ids,
        statusChangeFailuresByTripId: failures,
      );
    });
  }

  void _beginDetailsRequest() {
    _detailsRequestGeneration++;
  }

  bool _isCurrentCompanyRequest(int generation, String companyId) {
    return generation == _companyRequestGeneration &&
        _currentCompanyContext?.companyId == companyId;
  }

  bool _isCurrentLoadedCompanyRequest(int generation, String companyId) {
    if (!_isCurrentCompanyRequest(generation, companyId)) return false;
    final current = state;
    return current is TripsLoaded &&
        current.currentCompanyContext.companyId == companyId;
  }

  bool _isCurrentDetailsRequest({
    required int companyGeneration,
    required int detailsGeneration,
    required String companyId,
    required String tripId,
  }) {
    if (companyGeneration != _companyRequestGeneration ||
        detailsGeneration != _detailsRequestGeneration ||
        _currentCompanyContext?.companyId != companyId) {
      return false;
    }

    final current = state;
    return current is TripsLoaded &&
        current.currentCompanyContext.companyId == companyId &&
        current.selectedTrip?.id == tripId;
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
