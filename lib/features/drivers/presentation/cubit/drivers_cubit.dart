import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_status_filter.dart';
import '../../domain/policies/drivers_permission_policy.dart';
import '../../domain/usecases/add_driver_usecase.dart';
import '../../domain/usecases/deactivate_driver_usecase.dart';
import '../../domain/usecases/get_drivers_usecase.dart';
import '../../domain/usecases/reactivate_driver_usecase.dart';
import '../../domain/usecases/update_driver_usecase.dart';
import 'drivers_state.dart';

class DriversCubit extends Cubit<DriversState> {
  final GetDriversUseCase getDriversUseCase;
  final AddDriverUseCase addDriverUseCase;
  final UpdateDriverUseCase updateDriverUseCase;
  final DeactivateDriverUseCase deactivateDriverUseCase;
  final ReactivateDriverUseCase reactivateDriverUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;

  CurrentCompanyContext? _currentCompanyContext;

  DriversCubit({
    required this.getDriversUseCase,
    required this.addDriverUseCase,
    required this.updateDriverUseCase,
    required this.deactivateDriverUseCase,
    required this.reactivateDriverUseCase,
    required this.getEntityAuditLogsUseCase,
  }) : super(const DriversInitial());

  Future<void> loadDrivers(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final previousState = state;
    final previousSearchQuery = previousState is DriversLoaded
        ? previousState.searchQuery
        : '';
    final previousStatusFilter = previousState is DriversLoaded
        ? previousState.statusFilter
        : DriverStatusFilter.active;

    emit(const DriversLoading());

    final result = await getDriversUseCase(
      GetDriversParams(currentCompanyContext: currentCompanyContext),
    );

    result.when(
      success: (drivers) => emit(
        DriversLoaded(
          currentCompanyContext: currentCompanyContext,
          allDrivers: drivers,
          searchQuery: previousSearchQuery,
          statusFilter: previousStatusFilter,
          canManageDrivers: DriversPermissionPolicy.canManageDrivers(
            currentCompanyContext.role,
          ),
        ),
      ),
      failure: (failure) => emit(DriversFailure(failure)),
    );
  }

  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is DriversLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void setStatusFilter(DriverStatusFilter statusFilter) {
    final currentState = state;
    if (currentState is DriversLoaded) {
      emit(currentState.copyWith(statusFilter: statusFilter));
    }
  }

  Future<void> loadDriverActivity(Driver driver) async {
    final currentCompanyContext = _currentCompanyContext;
    final currentState = state;
    if (currentCompanyContext == null || currentState is! DriversLoaded) return;

    emit(
      currentState.copyWith(
        selectedDriver: driver,
        selectedDriverActivity: const [],
        isActivityLoading: true,
        activityFailure: null,
      ),
    );

    final result = await getEntityAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: currentCompanyContext.companyId,
        module: AuditModule.drivers,
        entityType: AuditEntityType.driver,
        entityId: driver.id,
      ),
    );

    final latestState = state;
    if (latestState is! DriversLoaded ||
        latestState.selectedDriver?.id != driver.id) {
      return;
    }

    result.when(
      success: (activity) => emit(
        latestState.copyWith(
          selectedDriverActivity: activity,
          isActivityLoading: false,
          activityFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(isActivityLoading: false, activityFailure: failure),
      ),
    );
  }

  void clearDriverActivity() {
    final currentState = state;
    if (currentState is DriversLoaded) {
      emit(
        currentState.copyWith(
          selectedDriver: null,
          selectedDriverActivity: const [],
          isActivityLoading: false,
          activityFailure: null,
        ),
      );
    }
  }

  Future<void> addDriver({
    required String fullName,
    String? phone,
    String? nationalId,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    String? notes,
  }) async {
    final currentCompanyContext = _currentCompanyContext;
    if (currentCompanyContext == null) return;

    final result = await addDriverUseCase(
      AddDriverParams(
        currentCompanyContext: currentCompanyContext,
        fullName: fullName,
        phone: phone,
        nationalId: nationalId,
        licenseNumber: licenseNumber,
        licenseExpiryDate: licenseExpiryDate,
        notes: notes,
      ),
    );

    result.when(
      success: _upsertDriver,
      failure: (failure) => emit(DriversFailure(failure)),
    );
  }

  Future<void> updateDriver({
    required Driver driver,
    required String fullName,
    String? phone,
    String? nationalId,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    String? notes,
  }) async {
    final currentCompanyContext = _currentCompanyContext;
    if (currentCompanyContext == null) return;

    final result = await updateDriverUseCase(
      UpdateDriverParams(
        currentCompanyContext: currentCompanyContext,
        driverId: driver.id,
        fullName: fullName,
        phone: phone,
        nationalId: nationalId,
        licenseNumber: licenseNumber,
        licenseExpiryDate: licenseExpiryDate,
        notes: notes,
      ),
    );

    result.when(
      success: _upsertDriver,
      failure: (failure) => emit(DriversFailure(failure)),
    );
  }

  Future<void> deactivateDriver(Driver driver) async {
    final currentCompanyContext = _currentCompanyContext;
    if (currentCompanyContext == null) return;

    final result = await deactivateDriverUseCase(
      DeactivateDriverParams(
        currentCompanyContext: currentCompanyContext,
        driverId: driver.id,
      ),
    );

    result.when(
      success: _upsertDriver,
      failure: (failure) => emit(DriversFailure(failure)),
    );
  }

  Future<void> reactivateDriver(Driver driver) async {
    final currentCompanyContext = _currentCompanyContext;
    if (currentCompanyContext == null) return;

    final result = await reactivateDriverUseCase(
      ReactivateDriverParams(
        currentCompanyContext: currentCompanyContext,
        driverId: driver.id,
      ),
    );

    result.when(
      success: _upsertDriver,
      failure: (failure) => emit(DriversFailure(failure)),
    );
  }

  void _upsertDriver(Driver driver) {
    final currentState = state;
    final currentCompanyContext = _currentCompanyContext;

    if (currentState is! DriversLoaded) {
      if (currentCompanyContext != null) {
        loadDrivers(currentCompanyContext);
      }
      return;
    }

    final exists = currentState.allDrivers.any((item) => item.id == driver.id);
    final updatedDrivers = exists
        ? currentState.allDrivers
            .map((item) => item.id == driver.id ? driver : item)
            .toList()
        : [driver, ...currentState.allDrivers];

    if (currentState.selectedDriver?.id == driver.id) {
      emit(currentState.copyWith(allDrivers: updatedDrivers, selectedDriver: driver));
      return;
    }

    emit(currentState.copyWith(allDrivers: updatedDrivers));
  }
}
