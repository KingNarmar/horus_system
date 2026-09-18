import 'package:horus_system/features/trips/domain/entities/trip_status.dart';

import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../expense_types/domain/entities/expense_type.dart';
import '../../../expenses/domain/entities/expense_ledger_entry.dart';
import '../../domain/entities/trip_business_local_timestamps.dart';
import '../../domain/entities/trip_document.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/entities/trip_form_lookups.dart';
import '../../domain/entities/trip_status_filter.dart';
import '../../domain/entities/trip_status_history.dart';

const Object _notSet = Object();

sealed class TripsState {
  const TripsState();
}

class TripsInitial extends TripsState {
  const TripsInitial();
}

class TripsLoading extends TripsState {
  const TripsLoading();
}

class TripsLoaded extends TripsState {
  final CurrentCompanyContext currentCompanyContext;
  final List<TripEntity> allTrips;
  final Map<String, TripBusinessLocalTimestamps>
  businessLocalTimestampsByTripId;
  final Map<String, BusinessLocalDateTime>
  selectedTripActivityBusinessTimesById;
  final Map<String, BusinessLocalDateTime>
  selectedTripStatusHistoryBusinessTimesById;
  final bool canManageTrips;
  final bool canUpdateTripStatus;
  final bool canManageTripDocuments;
  final bool canViewTripFinancials;
  final bool canManageTripExpenses;
  final String searchQuery;
  final TripStatusFilter statusFilter;
  final Set<String> statusChangingTripIds;
  final Map<String, Failure> statusChangeFailuresByTripId;
  final bool isTripSaving;
  final Failure? tripSaveFailure;
  final TripEntity? selectedTrip;
  final Money? selectedTripTotalExpenses;
  final Money? selectedTripNetProfit;
  final List<AuditLog> selectedTripActivity;
  final List<TripDocument> selectedTripDocuments;
  final bool hasRequiredTripEvidence;
  final List<TripStatusHistory> selectedTripStatusHistory;
  final List<ExpenseLedgerEntry> selectedTripExpenses;
  final List<ExpenseType> expenseTypes;
  final List<ExpenseType> selectableExpenseTypes;
  final bool isDetailsLoading;
  final bool isActivityLoading;
  final bool isDocumentsLoading;
  final bool isTripDocumentMutating;
  final bool isStatusHistoryLoading;
  final bool isExpensesLoading;
  final bool isExpenseTypesLoading;
  final bool isTripExpenseMutating;
  final Failure? detailsFailure;
  final Failure? activityFailure;
  final Failure? documentsFailure;
  final Failure? statusHistoryFailure;
  final Failure? expensesFailure;
  final Failure? expenseTypesFailure;
  final TripFormLookups? formLookups;
  final bool isFormLookupsLoading;
  final Failure? formLookupsFailure;

  const TripsLoaded({
    required this.currentCompanyContext,
    required this.allTrips,
    required this.canManageTrips,
    required this.canUpdateTripStatus,
    required this.canManageTripDocuments,
    required this.canViewTripFinancials,
    required this.canManageTripExpenses,
    this.businessLocalTimestampsByTripId =
        const <String, TripBusinessLocalTimestamps>{},
    this.selectedTripActivityBusinessTimesById =
        const <String, BusinessLocalDateTime>{},
    this.selectedTripStatusHistoryBusinessTimesById =
        const <String, BusinessLocalDateTime>{},
    this.searchQuery = '',
    this.statusFilter = TripStatusFilter.open,
    this.statusChangingTripIds = const <String>{},
    this.statusChangeFailuresByTripId = const <String, Failure>{},
    this.isTripSaving = false,
    this.tripSaveFailure,
    this.selectedTrip,
    this.selectedTripTotalExpenses,
    this.selectedTripNetProfit,
    this.selectedTripActivity = const <AuditLog>[],
    this.selectedTripDocuments = const <TripDocument>[],
    this.hasRequiredTripEvidence = false,
    this.selectedTripStatusHistory = const <TripStatusHistory>[],
    this.selectedTripExpenses = const <ExpenseLedgerEntry>[],
    this.expenseTypes = const <ExpenseType>[],
    this.selectableExpenseTypes = const <ExpenseType>[],
    this.isDetailsLoading = false,
    this.isActivityLoading = false,
    this.isDocumentsLoading = false,
    this.isTripDocumentMutating = false,
    this.isStatusHistoryLoading = false,
    this.isExpensesLoading = false,
    this.isExpenseTypesLoading = false,
    this.isTripExpenseMutating = false,
    this.detailsFailure,
    this.activityFailure,
    this.documentsFailure,
    this.statusHistoryFailure,
    this.expensesFailure,
    this.expenseTypesFailure,
    this.formLookups,
    this.isFormLookupsLoading = false,
    this.formLookupsFailure,
  });

  bool isStatusChanging(String id) => statusChangingTripIds.contains(id);

  Failure? statusChangeFailureFor(String id) {
    return statusChangeFailuresByTripId[id];
  }

  TripBusinessLocalTimestamps? businessLocalTimestampsFor(String tripId) {
    return businessLocalTimestampsByTripId[tripId];
  }

  BusinessLocalDateTime? activityBusinessTimeFor(String logId) {
    return selectedTripActivityBusinessTimesById[logId];
  }

  BusinessLocalDateTime? statusHistoryBusinessTimeFor(String historyId) {
    return selectedTripStatusHistoryBusinessTimesById[historyId];
  }

  List<TripEntity> get trips {
    final query = searchQuery.trim().toLowerCase();
    return allTrips.where((trip) {
      if (!statusFilter.matches(trip.status)) return false;
      if (query.isEmpty) return true;
      return [
        trip.displayName,
        trip.loadingOrderNumber,
        trip.waybillNumber,
        trip.customerName,
        trip.routeName,
        trip.driverName,
        trip.tractorHeadPlateNumber,
        trip.trailerPlateNumber,
        trip.status.value,
        trip.quantityTons?.toDecimalString(),
        trip.agreedFreightRatePerTon?.minorUnits.toString(),
        trip.commercialAmount?.minorUnits.toString(),
        trip.notes,
      ].whereType<String>().any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  TripsLoaded copyWith({
    List<TripEntity>? allTrips,
    Map<String, TripBusinessLocalTimestamps>? businessLocalTimestampsByTripId,
    Map<String, BusinessLocalDateTime>? selectedTripActivityBusinessTimesById,
    Map<String, BusinessLocalDateTime>?
    selectedTripStatusHistoryBusinessTimesById,
    bool? canManageTrips,
    bool? canUpdateTripStatus,
    bool? canManageTripDocuments,
    bool? canViewTripFinancials,
    bool? canManageTripExpenses,
    String? searchQuery,
    TripStatusFilter? statusFilter,
    Set<String>? statusChangingTripIds,
    Map<String, Failure>? statusChangeFailuresByTripId,
    bool? isTripSaving,
    Object? tripSaveFailure = _notSet,
    Object? selectedTrip = _notSet,
    Object? selectedTripTotalExpenses = _notSet,
    Object? selectedTripNetProfit = _notSet,
    List<AuditLog>? selectedTripActivity,
    List<TripDocument>? selectedTripDocuments,
    bool? hasRequiredTripEvidence,
    List<TripStatusHistory>? selectedTripStatusHistory,
    List<ExpenseLedgerEntry>? selectedTripExpenses,
    List<ExpenseType>? expenseTypes,
    List<ExpenseType>? selectableExpenseTypes,
    bool? isDetailsLoading,
    bool? isActivityLoading,
    bool? isDocumentsLoading,
    bool? isTripDocumentMutating,
    bool? isStatusHistoryLoading,
    bool? isExpensesLoading,
    bool? isExpenseTypesLoading,
    bool? isTripExpenseMutating,
    Object? detailsFailure = _notSet,
    Object? activityFailure = _notSet,
    Object? documentsFailure = _notSet,
    Object? statusHistoryFailure = _notSet,
    Object? expensesFailure = _notSet,
    Object? expenseTypesFailure = _notSet,
    Object? formLookups = _notSet,
    bool? isFormLookupsLoading,
    Object? formLookupsFailure = _notSet,
  }) {
    return TripsLoaded(
      currentCompanyContext: currentCompanyContext,
      allTrips: allTrips ?? this.allTrips,
      businessLocalTimestampsByTripId:
          businessLocalTimestampsByTripId ??
          this.businessLocalTimestampsByTripId,
      selectedTripActivityBusinessTimesById:
          selectedTripActivityBusinessTimesById ??
          this.selectedTripActivityBusinessTimesById,
      selectedTripStatusHistoryBusinessTimesById:
          selectedTripStatusHistoryBusinessTimesById ??
          this.selectedTripStatusHistoryBusinessTimesById,
      canManageTrips: canManageTrips ?? this.canManageTrips,
      canUpdateTripStatus: canUpdateTripStatus ?? this.canUpdateTripStatus,
      canManageTripDocuments:
          canManageTripDocuments ?? this.canManageTripDocuments,
      canViewTripFinancials:
          canViewTripFinancials ?? this.canViewTripFinancials,
      canManageTripExpenses:
          canManageTripExpenses ?? this.canManageTripExpenses,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      statusChangingTripIds:
          statusChangingTripIds ?? this.statusChangingTripIds,
      statusChangeFailuresByTripId:
          statusChangeFailuresByTripId ?? this.statusChangeFailuresByTripId,
      isTripSaving: isTripSaving ?? this.isTripSaving,
      tripSaveFailure: tripSaveFailure == _notSet
          ? this.tripSaveFailure
          : tripSaveFailure as Failure?,
      selectedTrip: selectedTrip == _notSet
          ? this.selectedTrip
          : selectedTrip as TripEntity?,
      selectedTripTotalExpenses: selectedTripTotalExpenses == _notSet
          ? this.selectedTripTotalExpenses
          : selectedTripTotalExpenses as Money?,
      selectedTripNetProfit: selectedTripNetProfit == _notSet
          ? this.selectedTripNetProfit
          : selectedTripNetProfit as Money?,
      selectedTripActivity: selectedTripActivity ?? this.selectedTripActivity,
      selectedTripDocuments:
          selectedTripDocuments ?? this.selectedTripDocuments,
      hasRequiredTripEvidence:
          hasRequiredTripEvidence ?? this.hasRequiredTripEvidence,
      selectedTripStatusHistory:
          selectedTripStatusHistory ?? this.selectedTripStatusHistory,
      selectedTripExpenses: selectedTripExpenses ?? this.selectedTripExpenses,
      expenseTypes: expenseTypes ?? this.expenseTypes,
      selectableExpenseTypes:
          selectableExpenseTypes ?? this.selectableExpenseTypes,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      isActivityLoading: isActivityLoading ?? this.isActivityLoading,
      isDocumentsLoading: isDocumentsLoading ?? this.isDocumentsLoading,
      isTripDocumentMutating:
          isTripDocumentMutating ?? this.isTripDocumentMutating,
      isStatusHistoryLoading:
          isStatusHistoryLoading ?? this.isStatusHistoryLoading,
      isExpensesLoading: isExpensesLoading ?? this.isExpensesLoading,
      isExpenseTypesLoading:
          isExpenseTypesLoading ?? this.isExpenseTypesLoading,
      isTripExpenseMutating:
          isTripExpenseMutating ?? this.isTripExpenseMutating,
      detailsFailure: detailsFailure == _notSet
          ? this.detailsFailure
          : detailsFailure as Failure?,
      activityFailure: activityFailure == _notSet
          ? this.activityFailure
          : activityFailure as Failure?,
      documentsFailure: documentsFailure == _notSet
          ? this.documentsFailure
          : documentsFailure as Failure?,
      statusHistoryFailure: statusHistoryFailure == _notSet
          ? this.statusHistoryFailure
          : statusHistoryFailure as Failure?,
      expensesFailure: expensesFailure == _notSet
          ? this.expensesFailure
          : expensesFailure as Failure?,
      expenseTypesFailure: expenseTypesFailure == _notSet
          ? this.expenseTypesFailure
          : expenseTypesFailure as Failure?,
      formLookups: formLookups == _notSet
          ? this.formLookups
          : formLookups as TripFormLookups?,
      isFormLookupsLoading: isFormLookupsLoading ?? this.isFormLookupsLoading,
      formLookupsFailure: formLookupsFailure == _notSet
          ? this.formLookupsFailure
          : formLookupsFailure as Failure?,
    );
  }
}

class TripsFailure extends TripsState {
  final Failure failure;

  const TripsFailure(this.failure);
}
