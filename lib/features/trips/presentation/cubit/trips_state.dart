import 'package:horus_system/features/trips/domain/entities/trip_status.dart';

import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/trip_entity.dart';
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
  final String searchQuery;
  final TripStatusFilter statusFilter;
  final Set<String> statusChangingTripIds;
  final TripEntity? selectedTrip;
  final List<AuditLog> selectedTripActivity;
  final List<TripStatusHistory> selectedTripStatusHistory;
  final bool isDetailsLoading;
  final bool isActivityLoading;
  final bool isStatusHistoryLoading;
  final Failure? detailsFailure;
  final Failure? activityFailure;
  final Failure? statusHistoryFailure;

  const TripsLoaded({
    required this.currentCompanyContext,
    required this.allTrips,
    required this.canManageTrips,
    required this.canUpdateTripStatus,
    required this.canViewTripFinancials,
    this.searchQuery = '',
    this.statusFilter = TripStatusFilter.open,
    this.statusChangingTripIds = const <String>{},
    this.selectedTrip,
    this.selectedTripActivity = const <AuditLog>[],
    this.selectedTripStatusHistory = const <TripStatusHistory>[],
    this.isDetailsLoading = false,
    this.isActivityLoading = false,
    this.isStatusHistoryLoading = false,
    this.detailsFailure,
    this.activityFailure,
    this.statusHistoryFailure,
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
    String? searchQuery,
    TripStatusFilter? statusFilter,
    Set<String>? statusChangingTripIds,
    Object? selectedTrip = _notSet,
    List<AuditLog>? selectedTripActivity,
    List<TripStatusHistory>? selectedTripStatusHistory,
    bool? isDetailsLoading,
    bool? isActivityLoading,
    bool? isStatusHistoryLoading,
    Object? detailsFailure = _notSet,
    Object? activityFailure = _notSet,
    Object? statusHistoryFailure = _notSet,
  }) {
    return TripsLoaded(
      currentCompanyContext: currentCompanyContext,
      allTrips: allTrips ?? this.allTrips,
      canManageTrips: canManageTrips ?? this.canManageTrips,
      canUpdateTripStatus: canUpdateTripStatus ?? this.canUpdateTripStatus,
      canViewTripFinancials:
          canViewTripFinancials ?? this.canViewTripFinancials,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      statusChangingTripIds:
          statusChangingTripIds ?? this.statusChangingTripIds,
      selectedTrip: selectedTrip == _notSet
          ? this.selectedTrip
          : selectedTrip as TripEntity?,
      selectedTripActivity: selectedTripActivity ?? this.selectedTripActivity,
      selectedTripStatusHistory:
          selectedTripStatusHistory ?? this.selectedTripStatusHistory,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      isActivityLoading: isActivityLoading ?? this.isActivityLoading,
      isStatusHistoryLoading:
          isStatusHistoryLoading ?? this.isStatusHistoryLoading,
      detailsFailure: detailsFailure == _notSet
          ? this.detailsFailure
          : detailsFailure as Failure?,
      activityFailure: activityFailure == _notSet
          ? this.activityFailure
          : activityFailure as Failure?,
      statusHistoryFailure: statusHistoryFailure == _notSet
          ? this.statusHistoryFailure
          : statusHistoryFailure as Failure?,
    );
  }
}

class TripsFailure extends TripsState {
  final Failure failure;

  const TripsFailure(this.failure);
}
