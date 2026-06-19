import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_status_filter.dart';

const Object _notSet = Object();

sealed class DriversState {
  const DriversState();
}

class DriversInitial extends DriversState {
  const DriversInitial();
}

class DriversLoading extends DriversState {
  const DriversLoading();
}

class DriversLoaded extends DriversState {
  final CurrentCompanyContext currentCompanyContext;
  final List<Driver> allDrivers;
  final bool canManageDrivers;
  final String searchQuery;
  final DriverStatusFilter statusFilter;
  final String? pendingActionDriverId;
  final Driver? selectedDriver;
  final List<AuditLog> selectedDriverActivity;
  final bool isActivityLoading;
  final Failure? activityFailure;

  const DriversLoaded({
    required this.currentCompanyContext,
    required this.allDrivers,
    required this.canManageDrivers,
    this.searchQuery = '',
    this.statusFilter = DriverStatusFilter.active,
    this.pendingActionDriverId,
    this.selectedDriver,
    this.selectedDriverActivity = const [],
    this.isActivityLoading = false,
    this.activityFailure,
  });

  List<Driver> get drivers {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    return allDrivers.where((driver) {
      final matchesStatus = statusFilter.matches(driver);
      if (!matchesStatus) return false;
      if (normalizedQuery.isEmpty) return true;

      return [
        driver.fullName,
        driver.phone,
        driver.nationalId,
        driver.licenseNumber,
        driver.notes,
      ].whereType<String>().any(
            (value) => value.toLowerCase().contains(normalizedQuery),
          );
    }).toList();
  }

  DriversLoaded copyWith({
    List<Driver>? allDrivers,
    bool? canManageDrivers,
    String? searchQuery,
    DriverStatusFilter? statusFilter,
    Object? pendingActionDriverId = _notSet,
    Object? selectedDriver = _notSet,
    List<AuditLog>? selectedDriverActivity,
    bool? isActivityLoading,
    Object? activityFailure = _notSet,
  }) {
    return DriversLoaded(
      currentCompanyContext: currentCompanyContext,
      allDrivers: allDrivers ?? this.allDrivers,
      canManageDrivers: canManageDrivers ?? this.canManageDrivers,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      pendingActionDriverId: pendingActionDriverId == _notSet
          ? this.pendingActionDriverId
          : pendingActionDriverId as String?,
      selectedDriver: selectedDriver == _notSet
          ? this.selectedDriver
          : selectedDriver as Driver?,
      selectedDriverActivity:
          selectedDriverActivity ?? this.selectedDriverActivity,
      isActivityLoading: isActivityLoading ?? this.isActivityLoading,
      activityFailure: activityFailure == _notSet
          ? this.activityFailure
          : activityFailure as Failure?,
    );
  }
}

class DriversFailure extends DriversState {
  final Failure failure;

  const DriversFailure(this.failure);
}
