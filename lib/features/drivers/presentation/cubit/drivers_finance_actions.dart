part of 'drivers_cubit.dart';

mixin DriversFinanceActions on Cubit<DriversState> {
  Future<void> loadDriverFinancialMovements(Driver driver) async {
    final owner = this as DriversCubit;
    final context = owner._currentCompanyContext;
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

    final result = await owner.getDriverMovementsUseCase(
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

  Future<void> addDriverAdvance({
    required Driver driver,
    required double amount,
    required DateTime movementDate,
    String? notes,
  }) {
    final owner = this as DriversCubit;
    return _addDriverFinancialMovement(
      driver: driver,
      action: () {
        final context = owner._currentCompanyContext!;
        return owner.addDriverAdvanceUseCase(
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
    final owner = this as DriversCubit;
    return _addDriverFinancialMovement(
      driver: driver,
      action: () {
        final context = owner._currentCompanyContext!;
        return owner.addDriverChargeUseCase(
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
    final owner = this as DriversCubit;
    return _addDriverFinancialMovement(
      driver: driver,
      action: () {
        final context = owner._currentCompanyContext!;
        return owner.addDriverCashReturnUseCase(
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

  Future<void> _addDriverFinancialMovement({
    required Driver driver,
    required Future<Result<DriverFinancialMovement>> Function() action,
  }) async {
    final owner = this as DriversCubit;
    final context = owner._currentCompanyContext;
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
    final owner = this as DriversCubit;
    final balanceResult = await owner.getCanonicalDriverBalanceUseCase(
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
}
