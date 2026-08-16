import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../driver_finance/domain/entities/driver_financial_movement.dart';
import '../../../driver_finance/domain/policies/driver_finance_permission_policy.dart';
import '../../../driver_finance/domain/usecases/driver_finance_usecases.dart';
import '../../../driver_finance/domain/usecases/get_canonical_driver_balance_usecase.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_image_file.dart';
import '../../domain/entities/driver_image_urls.dart';
import '../../domain/entities/driver_status_filter.dart';
import '../../domain/policies/drivers_permission_policy.dart';
import '../../domain/usecases/add_driver_usecase.dart';
import '../../domain/usecases/deactivate_driver_usecase.dart';
import '../../domain/usecases/get_driver_image_urls_usecase.dart';
import '../../domain/usecases/get_drivers_usecase.dart';
import '../../domain/usecases/reactivate_driver_usecase.dart';
import '../../domain/usecases/update_driver_usecase.dart';
import 'drivers_state.dart';

class DriversCubit extends Cubit<DriversState> {
  final GetDriversUseCase getDriversUseCase;
  final GetDriverImageUrlsUseCase getDriverImageUrlsUseCase;
  final AddDriverUseCase addDriverUseCase;
  final UpdateDriverUseCase updateDriverUseCase;
  final DeactivateDriverUseCase deactivateDriverUseCase;
  final ReactivateDriverUseCase reactivateDriverUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;
  final GetDriverMovementsUseCase getDriverMovementsUseCase;
  final GetDriverTripOptionsUseCase getDriverTripOptionsUseCase;
  final AddDriverAdvanceUseCase addDriverAdvanceUseCase;
  final AddDriverChargeUseCase addDriverChargeUseCase;
  final AddDriverCashReturnUseCase addDriverCashReturnUseCase;
  final GetCanonicalDriverBalanceUseCase getCanonicalDriverBalanceUseCase;

  CurrentCompanyContext? _currentCompanyContext;

  DriversCubit({
    required this.getDriversUseCase,
    required this.getDriverImageUrlsUseCase,
    required this.addDriverUseCase,
    required this.updateDriverUseCase,
    required this.deactivateDriverUseCase,
    required this.reactivateDriverUseCase,
    required this.getEntityAuditLogsUseCase,
    required this.getDriverMovementsUseCase,
    required this.getDriverTripOptionsUseCase,
    required this.addDriverAdvanceUseCase,
    required this.addDriverChargeUseCase,
    required this.addDriverCashReturnUseCase,
    required this.getCanonicalDriverBalanceUseCase,
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
          canManageDriverFinance:
              DriverFinancePermissionPolicy.canManageDriverFinance(
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
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null || currentState is! DriversLoaded) {
      return;
    }

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
        companyId: context.companyId,
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
        latestState.copyWith(
          isActivityLoading: false,
          activityFailure: failure,
        ),
      ),
    );
  }

  Future<void> loadDriverImageUrls(Driver driver) async {
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null || currentState is! DriversLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        selectedDriver: driver,
        selectedDriverImageUrls: DriverImageUrls.empty,
        isImageUrlsLoading: true,
        imageUrlsFailure: null,
      ),
    );

    final result = await getDriverImageUrlsUseCase(
      GetDriverImageUrlsParams(currentCompanyContext: context, driver: driver),
    );

    final latestState = state;
    if (latestState is! DriversLoaded ||
        latestState.selectedDriver?.id != driver.id) {
      return;
    }

    result.when(
      success: (imageUrls) => emit(
        latestState.copyWith(
          selectedDriverImageUrls: imageUrls,
          isImageUrlsLoading: false,
          imageUrlsFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          selectedDriverImageUrls: DriverImageUrls.empty,
          isImageUrlsLoading: false,
          imageUrlsFailure: failure,
        ),
      ),
    );
  }

  Future<void> loadDriverFinancialMovements(Driver driver) async {
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null || currentState is! DriversLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        selectedDriver: driver,
        selectedDriverFinancialMovements: const [],
        selectedDriverBalance: null,
        isFinancialMovementsLoading: true,
        financialMovementsFailure: null,
      ),
    );

    final result = await getDriverMovementsUseCase(
      GetDriverMovementsParams(
        currentCompanyContext: context,
        driverId: driver.id,
      ),
    );

    final latestState = state;
    if (latestState is! DriversLoaded ||
        latestState.selectedDriver?.id != driver.id) {
      return;
    }

    if (result is Success<List<DriverFinancialMovement>>) {
      await _emitDriverFinanceState(
        state: latestState,
        driver: driver,
        movements: result.data,
        isLoading: false,
      );
      return;
    }

    if (result is FailureResult<List<DriverFinancialMovement>>) {
      emit(
        latestState.copyWith(
          isFinancialMovementsLoading: false,
          financialMovementsFailure: result.failure,
        ),
      );
    }
  }

  Future<void> loadDriverTripOptions(Driver driver) async {
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null || currentState is! DriversLoaded) {
      return;
    }

    emit(
      currentState.copyWith(
        selectedDriver: driver,
        selectedDriverTripOptions: const [],
        isTripOptionsLoading: true,
        tripOptionsFailure: null,
      ),
    );

    final result = await getDriverTripOptionsUseCase(
      GetDriverTripOptionsParams(
        currentCompanyContext: context,
        driverId: driver.id,
      ),
    );

    final latestState = state;
    if (latestState is! DriversLoaded ||
        latestState.selectedDriver?.id != driver.id) {
      return;
    }

    result.when(
      success: (tripOptions) => emit(
        latestState.copyWith(
          selectedDriverTripOptions: tripOptions,
          isTripOptionsLoading: false,
          tripOptionsFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          selectedDriverTripOptions: const [],
          isTripOptionsLoading: false,
          tripOptionsFailure: failure,
        ),
      ),
    );
  }

  void clearDriverActivity() {
    final currentState = state;
    if (currentState is DriversLoaded) {
      emit(
        currentState.copyWith(
          selectedDriver: null,
          selectedDriverImageUrls: DriverImageUrls.empty,
          isImageUrlsLoading: false,
          imageUrlsFailure: null,
          selectedDriverActivity: const [],
          isActivityLoading: false,
          activityFailure: null,
          selectedDriverFinancialMovements: const [],
          selectedDriverBalance: null,
          selectedDriverTripOptions: const [],
          isTripOptionsLoading: false,
          tripOptionsFailure: null,
          isFinancialMovementsLoading: false,
          isSavingFinancialMovement: false,
          financialMovementsFailure: null,
        ),
      );
    }
  }

  Future<Failure?> addDriver({
    required String fullName,
    String? phone,
    String? nationalId,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    DriverImageUploadSet? imageUploads,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) {
      return const UnexpectedFailure();
    }

    final result = await addDriverUseCase(
      AddDriverParams(
        currentCompanyContext: context,
        fullName: fullName,
        phone: phone,
        nationalId: nationalId,
        licenseNumber: licenseNumber,
        licenseExpiryDate: licenseExpiryDate,
        imageUploads: imageUploads,
        notes: notes,
      ),
    );

    if (result is Success<Driver>) {
      _upsertDriver(result.data);
      return null;
    }

    if (result is FailureResult<Driver>) {
      return result.failure;
    }

    return const UnexpectedFailure();
  }

  Future<Failure?> updateDriver({
    required Driver driver,
    required String fullName,
    String? phone,
    String? nationalId,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    DriverImageUploadSet? imageUploads,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) {
      return const UnexpectedFailure();
    }

    final result = await updateDriverUseCase(
      UpdateDriverParams(
        currentCompanyContext: context,
        driverId: driver.id,
        fullName: fullName,
        phone: phone,
        nationalId: nationalId,
        licenseNumber: licenseNumber,
        licenseExpiryDate: licenseExpiryDate,
        imageUploads: imageUploads,
        notes: notes,
      ),
    );

    if (result is Success<Driver>) {
      _upsertDriver(result.data);
      return null;
    }

    if (result is FailureResult<Driver>) {
      return result.failure;
    }

    return const UnexpectedFailure();
  }

  Future<void> addDriverAdvance({
    required Driver driver,
    required double amount,
    required DateTime movementDate,
    String? notes,
  }) {
    return _addDriverFinancialMovement(
      driver: driver,
      action: () {
        final context = _currentCompanyContext!;
        return addDriverAdvanceUseCase(
          AddDriverAdvanceParams(
            currentCompanyContext: context,
            driverId: driver.id,
            amount: amount,
            movementDate: movementDate,
            notes: notes,
          ),
        );
      },
    );
  }

  Future<void> addDriverCharge({
    required Driver driver,
    required double amount,
    required DateTime movementDate,
    String? tripId,
    String? notes,
  }) {
    return _addDriverFinancialMovement(
      driver: driver,
      action: () {
        final context = _currentCompanyContext!;
        return addDriverChargeUseCase(
          AddDriverChargeParams(
            currentCompanyContext: context,
            driverId: driver.id,
            tripId: tripId,
            amount: amount,
            movementDate: movementDate,
            notes: notes,
          ),
        );
      },
    );
  }

  Future<void> addDriverCashReturn({
    required Driver driver,
    required double amount,
    required DateTime movementDate,
    String? notes,
  }) {
    return _addDriverFinancialMovement(
      driver: driver,
      action: () {
        final context = _currentCompanyContext!;
        return addDriverCashReturnUseCase(
          AddDriverCashReturnParams(
            currentCompanyContext: context,
            driverId: driver.id,
            amount: amount,
            movementDate: movementDate,
            notes: notes,
          ),
        );
      },
    );
  }

  Future<void> deactivateDriver(Driver driver) async {
    final context = _currentCompanyContext;
    if (context == null || !_startPendingAction(driver.id)) {
      return;
    }

    final result = await deactivateDriverUseCase(
      DeactivateDriverParams(
        currentCompanyContext: context,
        driverId: driver.id,
      ),
    );

    result.when(success: _upsertDriver, failure: _emitMutationFailure);
  }

  Future<void> reactivateDriver(Driver driver) async {
    final context = _currentCompanyContext;
    if (context == null || !_startPendingAction(driver.id)) {
      return;
    }

    final result = await reactivateDriverUseCase(
      ReactivateDriverParams(
        currentCompanyContext: context,
        driverId: driver.id,
      ),
    );

    result.when(success: _upsertDriver, failure: _emitMutationFailure);
  }

  Future<void> _addDriverFinancialMovement({
    required Driver driver,
    required Future<Result<DriverFinancialMovement>> Function() action,
  }) async {
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null || currentState is! DriversLoaded) {
      return;
    }
    if (currentState.isSavingFinancialMovement) {
      return;
    }

    emit(
      currentState.copyWith(
        selectedDriver: driver,
        isSavingFinancialMovement: true,
        financialMovementsFailure: null,
      ),
    );

    final result = await action();
    final latestState = state;
    if (latestState is! DriversLoaded ||
        latestState.selectedDriver?.id != driver.id) {
      return;
    }

    if (result is Success<DriverFinancialMovement>) {
      await _emitDriverFinanceState(
        state: latestState,
        driver: driver,
        movements: [
          result.data,
          ...latestState.selectedDriverFinancialMovements,
        ],
        isLoading: false,
        isSaving: false,
      );
      return;
    }

    if (result is FailureResult<DriverFinancialMovement>) {
      emit(
        latestState.copyWith(
          isSavingFinancialMovement: false,
          financialMovementsFailure: result.failure,
        ),
      );
    }
  }

  Future<void> _emitDriverFinanceState({
    required DriversLoaded state,
    required Driver driver,
    required List<DriverFinancialMovement> movements,
    required bool isLoading,
    bool isSaving = false,
  }) async {
    final balanceResult = await getCanonicalDriverBalanceUseCase(
      GetCanonicalDriverBalanceParams(
        currentCompanyContext: state.currentCompanyContext,
        driverId: driver.id,
        beforeExclusive: _tomorrowDate(),
      ),
    );

    final latestState = this.state;
    if (latestState is! DriversLoaded ||
        latestState.selectedDriver?.id != driver.id) {
      return;
    }

    balanceResult.when(
      success: (balance) => emit(
        latestState.copyWith(
          selectedDriverFinancialMovements: movements,
          selectedDriverBalance: balance,
          isFinancialMovementsLoading: isLoading,
          isSavingFinancialMovement: isSaving,
          financialMovementsFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          selectedDriverFinancialMovements: movements,
          selectedDriverBalance: null,
          isFinancialMovementsLoading: isLoading,
          isSavingFinancialMovement: isSaving,
          financialMovementsFailure: failure,
        ),
      ),
    );
  }

  DateTime _tomorrowDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  bool _startPendingAction(String driverId) {
    final currentState = state;
    if (currentState is! DriversLoaded) {
      return true;
    }
    if (currentState.pendingActionDriverId != null) {
      return false;
    }
    emit(currentState.copyWith(pendingActionDriverId: driverId));
    return true;
  }

  void _emitMutationFailure(Failure failure) {
    final currentState = state;
    if (currentState is DriversLoaded) {
      emit(currentState.copyWith(pendingActionDriverId: null));
    }
    emit(DriversFailure(failure));
  }

  void _upsertDriver(Driver driver) {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! DriversLoaded) {
      if (context != null) {
        loadDrivers(context);
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
      emit(
        currentState.copyWith(
          allDrivers: updatedDrivers,
          pendingActionDriverId: null,
          selectedDriver: driver,
        ),
      );
      return;
    }

    emit(
      currentState.copyWith(
        allDrivers: updatedDrivers,
        pendingActionDriverId: null,
      ),
    );
  }
}
