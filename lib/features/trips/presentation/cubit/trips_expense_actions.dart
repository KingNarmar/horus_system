part of 'trips_cubit.dart';

mixin TripsExpenseActions on Cubit<TripsState> {
  Future<void> saveTripExpense({
    TripExpense? expense,
    required String tripId,
    required String? expenseTypeId,
    required String expenseName,
    required double amount,
    required TripExpensePaidBy paidBy,
    required DateTime expenseDate,
    String? notes,
  }) async {
    final owner = this as TripsCubit;
    final context = owner._currentCompanyContext;
    final current = state;
    if (context == null ||
        current is! TripsLoaded ||
        current.isTripExpenseSaving) {
      return;
    }

    emit(current.copyWith(isTripExpenseSaving: true));

    final result = expense == null
        ? await owner.addTripExpenseUseCase(
            AddTripExpenseParams(
              currentCompanyContext: context,
              tripId: tripId,
              expenseTypeId: expenseTypeId,
              expenseName: expenseName,
              amount: amount,
              paidBy: paidBy,
              expenseDate: expenseDate,
              notes: notes,
            ),
          )
        : await owner.updateTripExpenseUseCase(
            UpdateTripExpenseParams(
              currentCompanyContext: context,
              id: expense.id,
              tripId: tripId,
              expenseTypeId: expenseTypeId,
              expenseName: expenseName,
              amount: amount,
              paidBy: paidBy,
              expenseDate: expenseDate,
              notes: notes,
            ),
          );

    owner._mapLoaded((state) => state.copyWith(isTripExpenseSaving: false));

    result.when(
      success: (_) async {
        final latest = state;
        if (latest is! TripsLoaded || latest.selectedTrip?.id != tripId) return;
        final selectedTrip = latest.selectedTrip!;
        await _loadSelectedTripExpenses(selectedTrip);
        await owner._loadSelectedTripDetails(selectedTrip);
        await owner._loadSelectedTripActivity(selectedTrip);
      },
      failure: (failure) => emit(TripsFailure(failure)),
    );
  }

  Future<void> _loadSelectedTripExpenses(TripEntity trip) async {
    final owner = this as TripsCubit;
    final current = state;
    if (current is! TripsLoaded) return;

    emit(current.copyWith(isExpensesLoading: true, expensesFailure: null));

    final result = await owner.getTripExpensesUseCase(
      GetTripExpensesParams(
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
        current.expenseTypesFailure == null) {
      return;
    }

    emit(
      current.copyWith(isExpenseTypesLoading: true, expenseTypesFailure: null),
    );

    final result = await owner.getActiveExpenseTypesUseCase(
      GetActiveExpenseTypesParams(
        currentCompanyContext: current.currentCompanyContext,
      ),
    );

    final latestState = state;
    if (latestState is! TripsLoaded) return;

    result.when(
      success: (types) => emit(
        latestState.copyWith(
          expenseTypes: types,
          isExpenseTypesLoading: false,
          expenseTypesFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          isExpenseTypesLoading: false,
          expenseTypesFailure: failure,
        ),
      ),
    );
  }
}
