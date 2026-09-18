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
        current.currentCompanyContext.companyId != context.companyId ||
        current.selectedTrip?.id != tripId ||
        current.isTripExpenseMutating) {
      return;
    }

    final companyGeneration = owner._companyRequestGeneration;
    final companyId = context.companyId;
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

    if (!owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId)) {
      return;
    }

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
        current.currentCompanyContext.companyId != context.companyId ||
        current.selectedTrip?.id != tripId ||
        current.isTripExpenseMutating) {
      return;
    }

    final companyGeneration = owner._companyRequestGeneration;
    final companyId = context.companyId;
    emit(current.copyWith(isTripExpenseMutating: true, expensesFailure: null));

    final result = await owner.voidExpenseLedgerEntryUseCase(
      VoidExpenseLedgerEntryParams(
        currentCompanyContext: context,
        entry: expense,
        reason: reason,
      ),
    );

    if (!owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId)) {
      return;
    }

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
    await owner._recalculateSelectedTripFinancials();
    await owner._loadSelectedTripActivity(selectedTrip);
  }

  Future<void> _loadSelectedTripExpenses(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded || current.selectedTrip?.id != trip.id) return;

    final companyGeneration = owner._companyRequestGeneration;
    final detailsGeneration = owner._detailsRequestGeneration;
    final companyId = current.currentCompanyContext.companyId;

    emit(current.copyWith(isExpensesLoading: true, expensesFailure: null));

    final result = await owner.getTripExpenseLedgerEntriesUseCase(
      GetTripExpenseLedgerEntriesParams(
        currentCompanyContext: current.currentCompanyContext,
        tripId: trip.id,
      ),
    );

    if (!owner._isCurrentDetailsRequest(
      companyGeneration: companyGeneration,
      detailsGeneration: detailsGeneration,
      companyId: companyId,
      tripId: trip.id,
    )) {
      return;
    }

    final latestState = state as TripsLoaded;
    if (result is FailureResult<List<ExpenseLedgerEntry>>) {
      emit(
        latestState.copyWith(
          isExpensesLoading: false,
          expensesFailure: result.failure,
        ),
      );
      return;
    }

    emit(
      latestState.copyWith(
        selectedTripExpenses:
            (result as Success<List<ExpenseLedgerEntry>>).data,
        isExpensesLoading: false,
        expensesFailure: null,
      ),
    );
    await owner._recalculateSelectedTripFinancials();
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

    final companyGeneration = owner._companyRequestGeneration;
    final companyId = current.currentCompanyContext.companyId;
    final currentCompanyContext = current.currentCompanyContext;

    emit(
      current.copyWith(isExpenseTypesLoading: true, expenseTypesFailure: null),
    );

    final catalogResult = await owner.getExpenseTypeCatalogUseCase(
      GetExpenseTypeCatalogParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );

    if (!owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId)) {
      return;
    }

    final afterCatalog = state as TripsLoaded;
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
        currentCompanyContext: currentCompanyContext,
      ),
    );

    if (!owner._isCurrentLoadedCompanyRequest(companyGeneration, companyId)) {
      return;
    }

    final latestState = state as TripsLoaded;
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
