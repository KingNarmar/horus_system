import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../driver_finance/domain/entities/driver_balance.dart';
import '../../../driver_finance/domain/entities/driver_finance_trip_option.dart';
import '../../../driver_finance/domain/entities/driver_financial_movement.dart';
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
  final bool canManageDriverFinance;
  final String searchQuery;
  final DriverStatusFilter statusFilter;
  final String? pendingActionDriverId;
  final Driver? selectedDriver;
  final List<AuditLog> selectedDriverActivity;
  final bool isActivityLoading;
  final Failure? activityFailure;
  final List<DriverFinancialMovement> selectedDriverFinancialMovements;
  final DriverBalance? selectedDriverBalance;
  final List<DriverFinanceTripOption> selectedDriverTripOptions;
  final bool isTripOptionsLoading;
  final Failure? tripOptionsFailure;
  final bool isFinancialMovementsLoading;
  final bool isSavingFinancialMovement;
  final Failure? financialMovementsFailure;

  const DriversLoaded({
    required this.currentCompanyContext,
    required this.allDrivers,
    required this.canManageDrivers,
    required this.canManageDriverFinance,
    this.searchQuery = '',
    this.statusFilter = DriverStatusFilter.active,
    this.pendingActionDriverId,
    this.selectedDriver,
    this.selectedDriverActivity = const [],
    this.isActivityLoading = false,
    this.activityFailure,
    this.selectedDriverFinancialMovements = const [],
    this.selectedDriverBalance,
    this.selectedDriverTripOptions = const [],
    this.isTripOptionsLoading = false,
    this.tripOptionsFailure,
    this.isFinancialMovementsLoading = false,
    this.isSavingFinancialMovement = false,
    this.financialMovementsFailure,
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
    bool? canManageDriverFinance,
    String? searchQuery,
    DriverStatusFilter? statusFilter,
    Object? pendingActionDriverId = _notSet,
    Object? selectedDriver = _notSet,
    List<AuditLog>? selectedDriverActivity,
    bool? isActivityLoading,
    Object? activityFailure = _notSet,
    List<DriverFinancialMovement>? selectedDriverFinancialMovements,
    Object? selectedDriverBalance = _notSet,
    List<DriverFinanceTripOption>? selectedDriverTripOptions,
    bool? isTripOptionsLoading,
    Object? tripOptionsFailure = _notSet,
    bool? isFinancialMovementsLoading,
    bool? isSavingFinancialMovement,
    Object? financialMovementsFailure = _notSet,
  }) {
    return DriversLoaded(
      currentCompanyContext: currentCompanyContext,
      allDrivers: allDrivers ?? this.allDrivers,
      canManageDrivers: canManageDrivers ?? this.canManageDrivers,
      canManageDriverFinance:
          canManageDriverFinance ?? this.canManageDriverFinance,
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
      selectedDriverFinancialMovements:
          selectedDriverFinancialMovements ??
          this.selectedDriverFinancialMovements,
      selectedDriverBalance: selectedDriverBalance == _notSet
          ? this.selectedDriverBalance
          : selectedDriverBalance as DriverBalance?,
      selectedDriverTripOptions:
          selectedDriverTripOptions ?? this.selectedDriverTripOptions,
      isTripOptionsLoading: isTripOptionsLoading ?? this.isTripOptionsLoading,
      tripOptionsFailure: tripOptionsFailure == _notSet
          ? this.tripOptionsFailure
          : tripOptionsFailure as Failure?,
      isFinancialMovementsLoading:
          isFinancialMovementsLoading ?? this.isFinancialMovementsLoading,
      isSavingFinancialMovement:
          isSavingFinancialMovement ?? this.isSavingFinancialMovement,
      financialMovementsFailure: financialMovementsFailure == _notSet
          ? this.financialMovementsFailure
          : financialMovementsFailure as Failure?,
    );
  }
}

class DriversFailure extends DriversState {
  final Failure failure;

  const DriversFailure(this.failure);
}
