part of 'trips_cubit.dart';

mixin TripsExpenseActions on Cubit<TripsState> {
  Future<void> createTripExpense({
    required String tripId,
    required ExpenseType expenseType,
    required String amountInput,
    required ExpenseFundingSource fundingSource,
    required BusinessDate expenseDate,
    String? description,
    String? notes,
  }) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    final current = state;
    if (context == null ||
        current is! TripsLoaded ||
        current.isTripExpenseMutating) {
      return;
    }

    emit(current.copyWith(isTripExpenseMutating: true, expensesFailure: null));

    final result = await owner.createTripExpenseUseCase(
      CreateTripExpenseParams(
        currentCompanyContext: context,
        tripId: tripId,
        expenseType: expenseType,
        amountInput: amountInput,
        fundingSource: fundingSource,
        expenseDate: expenseDate,
        description: description,
        notes: notes,
      ),
    );

    owner._mapLoaded((state) => state.copyWith(isTripExpenseMutating: false));

    result.when(
      success: (_) => _refreshSelectedTripExpenseContext(tripId),
      failure: (failure) =>
          owner._mapLoaded((state) => state.copyWith(expensesFailure: failure)),
    );
  }

  Future<void> voidTripExpense({
    required ExpenseLedgerEntry expense,
    String? reason,
  }) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    final current = state;
    final tripId = expense.attribution.tripId;
    if (context == null ||
        tripId == null ||
        current is! TripsLoaded ||
        current.isTripExpenseMutating) {
      return;
    }

    emit(current.copyWith(isTripExpenseMutating: true, expensesFailure: null));

    final result = await owner.voidExpenseLedgerEntryUseCase(
      VoidExpenseLedgerEntryParams(
        currentCompanyContext: context,
        entry: expense,
        reason: reason,
      ),
    );

    owner._mapLoaded((state) => state.copyWith(isTripExpenseMutating: false));

    result.when(
      success: (_) => _refreshSelectedTripExpenseContext(tripId),
      failure: (failure) =>
          owner._mapLoaded((state) => state.copyWith(expensesFailure: failure)),
    );
  }

  Future<void> _refreshSelectedTripExpenseContext(String tripId) async {
    final owner = this as TripsCubit;
    final latest = state;
    if (latest is! TripsLoaded || latest.selectedTrip?.id != tripId) return;

    final selectedTrip = latest.selectedTrip!;
    await _loadSelectedTripExpenses(selectedTrip);
    await owner._loadSelectedTripDetails(selectedTrip);
    await owner._loadSelectedTripActivity(selectedTrip);
  }

  Future<void> _loadSelectedTripExpenses(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded) return;

    emit(current.copyWith(isExpensesLoading: true, expensesFailure: null));

    final result = await owner.getTripExpenseLedgerEntriesUseCase(
      GetTripExpenseLedgerEntriesParams(
        currentCompanyContext: current.currentCompanyContext,
        tripId: trip.id,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (expenses) => emit(
        latestState.copyWith(
          selectedTripExpenses: expenses,
          isExpensesLoading: false,
          expensesFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          isExpensesLoading: false,
          expensesFailure: failure,
        ),
      ),
    );
  }

  Future<void> _loadExpenseTypesIfNeeded() async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded || current.isExpenseTypesLoading) return;
    if (current.expenseTypes.isNotEmpty &&
        current.selectableExpenseTypes.isNotEmpty &&
        current.expenseTypesFailure == null) {
      return;
    }

    emit(
      current.copyWith(isExpenseTypesLoading: true, expenseTypesFailure: null),
    );

    final catalogResult = await owner.getExpenseTypeCatalogUseCase(
      GetExpenseTypeCatalogParams(
        currentCompanyContext: current.currentCompanyContext,
      ),
    );
    final afterCatalog = state;
    if (afterCatalog is! TripsLoaded) return;
    if (catalogResult is FailureResult<List<ExpenseType>>) {
      emit(
        afterCatalog.copyWith(
          isExpenseTypesLoading: false,
          expenseTypesFailure: catalogResult.failure,
        ),
      );
      return;
    }

    final selectableResult = await owner.getLedgerEligibleExpenseTypesUseCase(
      GetLedgerEligibleExpenseTypesParams(
        currentCompanyContext: afterCatalog.currentCompanyContext,
      ),
    );
    final latestState = state;
    if (latestState is! TripsLoaded) return;

    if (selectableResult is FailureResult<List<ExpenseType>>) {
      emit(
        latestState.copyWith(
          isExpenseTypesLoading: false,
          expenseTypesFailure: selectableResult.failure,
        ),
      );
      return;
    }

    emit(
      latestState.copyWith(
        expenseTypes: (catalogResult as Success<List<ExpenseType>>).data,
        selectableExpenseTypes:
            (selectableResult as Success<List<ExpenseType>>).data,
        isExpenseTypesLoading: false,
        expenseTypesFailure: null,
      ),
    );
  }
}
