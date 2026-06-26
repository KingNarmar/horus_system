import 'package:horus_system/features/trips/domain/entities/trip_status.dart';

import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../expenses/domain/entities/expense_type_option.dart';
import '../../../expenses/domain/entities/trip_expense.dart';
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
  final bool canManageTrips;
  final bool canUpdateTripStatus;
  final bool canViewTripFinancials;
  final bool canManageTripExpenses;
  final String searchQuery;
  final TripStatusFilter statusFilter;
  final Set<String> statusChangingTripIds;
  final TripEntity? selectedTrip;
  final double? selectedTripNetProfit;
  final List<AuditLog> selectedTripActivity;
  final List<TripStatusHistory> selectedTripStatusHistory;
  final List<TripExpense> selectedTripExpenses;
  final List<ExpenseTypeOption> expenseTypes;
  final bool isDetailsLoading;
  final bool isActivityLoading;
  final bool isStatusHistoryLoading;
  final bool isExpensesLoading;
  final bool isExpenseTypesLoading;
  final bool isTripExpenseSaving;
  final Failure? detailsFailure;
  final Failure? activityFailure;
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
    required this.canViewTripFinancials,
    required this.canManageTripExpenses,
    this.searchQuery = '',
    this.statusFilter = TripStatusFilter.open,
    this.statusChangingTripIds = const <String>{},
    this.selectedTrip,
    this.selectedTripNetProfit,
    this.selectedTripActivity = const <AuditLog>[],
    this.selectedTripStatusHistory = const <TripStatusHistory>[],
    this.selectedTripExpenses = const <TripExpense>[],
    this.expenseTypes = const <ExpenseTypeOption>[],
    this.isDetailsLoading = false,
    this.isActivityLoading = false,
    this.isStatusHistoryLoading = false,
    this.isExpensesLoading = false,
    this.isExpenseTypesLoading = false,
    this.isTripExpenseSaving = false,
    this.detailsFailure,
    this.activityFailure,
    this.statusHistoryFailure,
    this.expensesFailure,
    this.expenseTypesFailure,
    this.formLookups,
    this.isFormLookupsLoading = false,
    this.formLookupsFailure,
  });

  bool isStatusChanging(String id) {
    return statusChangingTripIds.contains(id);
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
        trip.quantityTons?.toString(),
        trip.freightPrice?.toString(),
        trip.totalExpenses?.toString(),
        trip.notes,
      ].whereType<String>().any((value) {
        return value.toLowerCase().contains(query);
      });
    }).toList();
  }

  TripsLoaded copyWith({
    List<TripEntity>? allTrips,
    bool? canManageTrips,
    bool? canUpdateTripStatus,
    bool? canViewTripFinancials,
    bool? canManageTripExpenses,
    String? searchQuery,
    TripStatusFilter? statusFilter,
    Set<String>? statusChangingTripIds,
    Object? selectedTrip = _notSet,
    Object? selectedTripNetProfit = _notSet,
    List<AuditLog>? selectedTripActivity,
    List<TripStatusHistory>? selectedTripStatusHistory,
    List<TripExpense>? selectedTripExpenses,
    List<ExpenseTypeOption>? expenseTypes,
    bool? isDetailsLoading,
    bool? isActivityLoading,
    bool? isStatusHistoryLoading,
    bool? isExpensesLoading,
    bool? isExpenseTypesLoading,
    bool? isTripExpenseSaving,
    Object? detailsFailure = _notSet,
    Object? activityFailure = _notSet,
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
      canManageTrips: canManageTrips ?? this.canManageTrips,
      canUpdateTripStatus: canUpdateTripStatus ?? this.canUpdateTripStatus,
      canViewTripFinancials:
          canViewTripFinancials ?? this.canViewTripFinancials,
      canManageTripExpenses:
          canManageTripExpenses ?? this.canManageTripExpenses,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      statusChangingTripIds:
          statusChangingTripIds ?? this.statusChangingTripIds,
      selectedTrip: selectedTrip == _notSet
          ? this.selectedTrip
          : selectedTrip as TripEntity?,
      selectedTripNetProfit: selectedTripNetProfit == _notSet
          ? this.selectedTripNetProfit
          : selectedTripNetProfit as double?,
      selectedTripActivity: selectedTripActivity ?? this.selectedTripActivity,
      selectedTripStatusHistory:
          selectedTripStatusHistory ?? this.selectedTripStatusHistory,
      selectedTripExpenses: selectedTripExpenses ?? this.selectedTripExpenses,
      expenseTypes: expenseTypes ?? this.expenseTypes,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      isActivityLoading: isActivityLoading ?? this.isActivityLoading,
      isStatusHistoryLoading:
          isStatusHistoryLoading ?? this.isStatusHistoryLoading,
      isExpensesLoading: isExpensesLoading ?? this.isExpensesLoading,
      isExpenseTypesLoading:
          isExpenseTypesLoading ?? this.isExpenseTypesLoading,
      isTripExpenseSaving: isTripExpenseSaving ?? this.isTripExpenseSaving,
      detailsFailure: detailsFailure == _notSet
          ? this.detailsFailure
          : detailsFailure as Failure?,
      activityFailure: activityFailure == _notSet
          ? this.activityFailure
          : activityFailure as Failure?,
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
