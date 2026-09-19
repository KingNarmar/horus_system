import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/get_company_business_date_usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../drivers/domain/usecases/get_drivers_usecase.dart';
import '../../domain/entities/driver_balance.dart';
import '../../domain/entities/driver_finance_trip_option.dart';
import '../../domain/entities/driver_financial_movement.dart';
import '../../domain/policies/driver_finance_permission_policy.dart';
import '../../domain/usecases/driver_finance_usecases.dart';
import '../../domain/usecases/get_canonical_driver_balance_usecase.dart';
import 'driver_finance_state.dart';

final class DriverFinanceCubit extends Cubit<DriverFinanceState> {
  final GetDriversUseCase getDriversUseCase;
  final GetCompanyBusinessDateUseCase getCompanyBusinessDateUseCase;
  final GetDriverMovementsUseCase getDriverMovementsUseCase;
  final GetDriverTripOptionsUseCase getDriverTripOptionsUseCase;
  final AddDriverAdvanceUseCase addDriverAdvanceUseCase;
  final AddDriverChargeUseCase addDriverChargeUseCase;
  final AddDriverCashReturnUseCase addDriverCashReturnUseCase;
  final GetCurrentCanonicalDriverBalanceUseCase
  getCurrentCanonicalDriverBalanceUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestId = 0;
  int _detailsRequestId = 0;

  DriverFinanceCubit({
    required this.getDriversUseCase,
    required this.getCompanyBusinessDateUseCase,
    required this.getDriverMovementsUseCase,
    required this.getDriverTripOptionsUseCase,
    required this.addDriverAdvanceUseCase,
    required this.addDriverChargeUseCase,
    required this.addDriverCashReturnUseCase,
    required this.getCurrentCanonicalDriverBalanceUseCase,
  }) : super(const DriverFinanceInitial());

  Future<void> load(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_loadRequestId;
    ++_detailsRequestId;
    emit(const DriverFinanceLoading());

    final result = await getDriversUseCase(
      GetDriversParams(currentCompanyContext: currentCompanyContext),
    );

    if (!_isCurrentLoad(requestId, currentCompanyContext)) return;

    result.when(
      success: (drivers) => emit(
        DriverFinanceLoaded(
          currentCompanyContext: currentCompanyContext,
          drivers: List.unmodifiable(drivers),
          canManage: DriverFinancePermissionPolicy.canManageDriverFinance(
            currentCompanyContext.role,
          ),
        ),
      ),
      failure: (failure) => emit(DriverFinanceFailure(failure)),
    );
  }

  Future<void> selectDriver(String? driverId) async {
    final current = state;
    if (current is! DriverFinanceLoaded || current.isSaving) return;

    final normalizedId = driverId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) {
      ++_detailsRequestId;
      emit(
        current.copyWith(
          selectedDriverId: null,
          movements: const [],
          balance: null,
          tripOptions: const [],
          isDetailsLoading: false,
          failure: null,
        ),
      );
      return;
    }

    if (!current.drivers.any((driver) => driver.id == normalizedId)) return;

    final requestId = ++_detailsRequestId;
    final companyId = current.currentCompanyContext.companyId;
    emit(
      current.copyWith(
        selectedDriverId: normalizedId,
        movements: const [],
        balance: null,
        tripOptions: const [],
        isDetailsLoading: true,
        failure: null,
      ),
    );

    final movementsResult = await getDriverMovementsUseCase(
      GetDriverMovementsParams(
        currentCompanyContext: current.currentCompanyContext,
        driverId: normalizedId,
      ),
    );
    if (!_isCurrentDetailsRequest(requestId, companyId, normalizedId)) return;
    if (movementsResult is FailureResult<List<DriverFinancialMovement>>) {
      _emitDetailsFailure(movementsResult.failure);
      return;
    }

    final tripOptionsResult = await getDriverTripOptionsUseCase(
      GetDriverTripOptionsParams(
        currentCompanyContext: current.currentCompanyContext,
        driverId: normalizedId,
      ),
    );
    if (!_isCurrentDetailsRequest(requestId, companyId, normalizedId)) return;
    if (tripOptionsResult is FailureResult<List<DriverFinanceTripOption>>) {
      _emitDetailsFailure(tripOptionsResult.failure);
      return;
    }

    final balanceResult = await getCurrentCanonicalDriverBalanceUseCase(
      GetCurrentCanonicalDriverBalanceParams(
        currentCompanyContext: current.currentCompanyContext,
        driverId: normalizedId,
      ),
    );
    if (!_isCurrentDetailsRequest(requestId, companyId, normalizedId)) return;
    if (balanceResult is FailureResult<DriverBalance>) {
      _emitDetailsFailure(balanceResult.failure);
      return;
    }

    final latest = state;
    if (latest is! DriverFinanceLoaded) return;
    emit(
      latest.copyWith(
        movements:
            (movementsResult as Success<List<DriverFinancialMovement>>).data,
        tripOptions:
            (tripOptionsResult as Success<List<DriverFinanceTripOption>>).data,
        balance: (balanceResult as Success<DriverBalance>).data,
        isDetailsLoading: false,
        failure: null,
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

  Future<void> addDriverAdvance({
    required String amount,
    required BusinessDate movementDate,
    String? notes,
  }) {
    return _addMovement(
      action: (context, driverId) => addDriverAdvanceUseCase(
        AddDriverAdvanceParams(
          currentCompanyContext: context,
          driverId: driverId,
          amount: amount,
          movementDate: movementDate,
          notes: notes,
        ),
      ),
    );
  }

  Future<void> addDriverCharge({
    required String amount,
    required BusinessDate movementDate,
    String? tripId,
    String? notes,
  }) {
    return _addMovement(
      action: (context, driverId) => addDriverChargeUseCase(
        AddDriverChargeParams(
          currentCompanyContext: context,
          driverId: driverId,
          amount: amount,
          movementDate: movementDate,
          tripId: tripId,
          notes: notes,
        ),
      ),
    );
  }

  Future<void> addDriverCashReturn({
    required String amount,
    required BusinessDate movementDate,
    String? notes,
  }) {
    return _addMovement(
      action: (context, driverId) => addDriverCashReturnUseCase(
        AddDriverCashReturnParams(
          currentCompanyContext: context,
          driverId: driverId,
          amount: amount,
          movementDate: movementDate,
          notes: notes,
        ),
      ),
    );
  }

  Future<void> _addMovement({
    required Future<Result<DriverFinancialMovement>> Function(
      CurrentCompanyContext context,
      String driverId,
    )
    action,
  }) async {
    final current = state;
    if (current is! DriverFinanceLoaded ||
        current.isSaving ||
        current.selectedDriverId == null ||
        !current.canManage) {
      return;
    }

    final driverId = current.selectedDriverId!;
    emit(current.copyWith(isSaving: true, failure: null));

    final result = await action(current.currentCompanyContext, driverId);
    final latest = state;
    if (latest is! DriverFinanceLoaded || latest.selectedDriverId != driverId) {
      return;
    }

    if (result is FailureResult<DriverFinancialMovement>) {
      emit(latest.copyWith(isSaving: false, failure: result.failure));
      return;
    }

    emit(latest.copyWith(isSaving: false, failure: null));
    await selectDriver(driverId);
  }

  void _emitDetailsFailure(Failure failure) {
    final current = state;
    if (current is DriverFinanceLoaded) {
      emit(current.copyWith(isDetailsLoading: false, failure: failure));
    }
  }

  bool _isCurrentLoad(int requestId, CurrentCompanyContext context) {
    final current = _currentCompanyContext;
    return !isClosed &&
        requestId == _loadRequestId &&
        current?.companyId == context.companyId &&
        current?.role == context.role;
  }

  bool _isCurrentDetailsRequest(
    int requestId,
    String companyId,
    String driverId,
  ) {
    final current = state;
    return !isClosed &&
        requestId == _detailsRequestId &&
        current is DriverFinanceLoaded &&
        current.currentCompanyContext.companyId == companyId &&
        current.selectedDriverId == driverId;
  }
}
