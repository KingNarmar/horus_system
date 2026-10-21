part of 'company_expenses_cubit.dart';

/// Reconciles the mounted Company Expenses projection without resetting forms,
/// filters, selection or pending mutations. The server remains authoritative.
mixin CompanyExpensesRealtimeActions on Cubit<CompanyExpensesState> {
  Future<void> refreshCompanyExpensesFromRealtime() async {
    final owner = this as CompanyExpensesCubit;
    if (owner.isClosed) return;
    if (state is! CompanyExpensesLoaded) {
      if (state is CompanyExpensesLoading) owner._expensesRefreshPending = true;
      return;
    }
    if (owner._expensesRefreshInProgress) {
      owner._expensesRefreshPending = true;
      return;
    }

    owner._expensesRefreshInProgress = true;
    try {
      do {
        owner._expensesRefreshPending = false;
        await _refreshExpensesOnce();
      } while (owner._expensesRefreshPending &&
          !owner.isClosed &&
          state is CompanyExpensesLoaded);
    } finally {
      owner._expensesRefreshInProgress = false;
    }
  }

  Future<void> _refreshExpensesOnce() async {
    final owner = this as CompanyExpensesCubit;
    final before = state;
    if (before is! CompanyExpensesLoaded) return;
    final context = before.currentCompanyContext;
    final generation = owner._loadRequestGeneration;
    final mutationRevision = owner._expenseMutationRevision;
    final includeVoided = before.includeVoided;
    final selectedId = before.selectedExpense?.id;
    // A selected expense may be voided remotely while its details stay open.
    final result = await owner.getExpensesUseCase(
      GetCompanyExpensesParams(
        currentCompanyContext: context,
        includeVoided: includeVoided || selectedId != null,
      ),
    );

    if (!owner._isCurrentCompanyRequest(generation, context)) return;
    final current = state;
    if (current is! CompanyExpensesLoaded) return;
    if (mutationRevision != owner._expenseMutationRevision ||
        current.includeVoided != includeVoided ||
        current.selectedExpense?.id != selectedId) {
      owner._expensesRefreshPending = true;
      return;
    }

    final failure = result.failureOrNull;
    if (failure != null) {
      if (failure is AuthFailure || failure is PermissionFailure) {
        emit(CompanyExpensesFailure(failure));
      } else {
        emit(current.copyWith(realtimeRefreshFailure: failure));
      }
      return;
    }

    final serverExpenses = result.dataOrNull ?? const <CompanyExpense>[];
    CompanyExpense? selected = current.selectedExpense;
    if (selectedId != null) {
      for (final expense in serverExpenses) {
        if (expense.id == selectedId) {
          selected = expense;
          break;
        }
      }
    }
    final shouldReloadActivity =
        selectedId != null &&
        selected != null &&
        (selected.updatedAt != current.selectedExpense?.updatedAt ||
            selected.isVoided != current.selectedExpense?.isVoided);
    emit(
      current.copyWith(
        allExpenses: includeVoided
            ? serverExpenses
            : serverExpenses.where((expense) => !expense.isVoided).toList(),
        selectedExpense: selected,
        realtimeRefreshFailure: null,
      ),
    );
    if (shouldReloadActivity && selected != null) {
      unawaited(owner.loadExpenseActivity(selected));
    }
  }

  /// Network reconnect also repairs form lookups missed during the outage.
  Future<void> reconcileCompanyExpensesAfterReconnect(
    CurrentCompanyContext context,
  ) async {
    final owner = this as CompanyExpensesCubit;
    if (owner.isClosed) return;
    final current = state;
    if (current is CompanyExpensesInitial ||
        current is CompanyExpensesFailure) {
      await owner.loadCompanyExpenses(context);
      return;
    }
    if (current is CompanyExpensesLoaded &&
        (current.currentCompanyContext.companyId != context.companyId ||
            current.currentCompanyContext.role != context.role)) {
      return;
    }
    if (current is CompanyExpensesLoading) {
      owner._expensesRefreshPending = true;
      owner._referencesRefreshPending = true;
      return;
    }
    await refreshCompanyExpensesFromRealtime();
    await refreshCompanyExpenseReferencesFromRealtime();
  }

  Future<void> refreshCompanyExpenseReferencesFromRealtime() async {
    final owner = this as CompanyExpensesCubit;
    if (owner.isClosed) return;
    if (state is! CompanyExpensesLoaded) {
      if (state is CompanyExpensesLoading) {
        owner._referencesRefreshPending = true;
      }
      return;
    }
    if (owner._referencesRefreshInProgress) {
      owner._referencesRefreshPending = true;
      return;
    }

    owner._referencesRefreshInProgress = true;
    try {
      do {
        owner._referencesRefreshPending = false;
        await _refreshReferencesOnce();
      } while (owner._referencesRefreshPending &&
          !owner.isClosed &&
          state is CompanyExpensesLoaded);
    } finally {
      owner._referencesRefreshInProgress = false;
    }
  }

  Future<void> _refreshReferencesOnce() async {
    final owner = this as CompanyExpensesCubit;
    final before = state;
    if (before is! CompanyExpensesLoaded) return;
    final context = before.currentCompanyContext;
    final generation = owner._loadRequestGeneration;
    final categories = await owner.getCategoriesUseCase(
      GetCompanyExpenseCategoriesParams(currentCompanyContext: context),
    );
    if (!owner._isCurrentCompanyRequest(generation, context)) return;
    if (_referenceFailure(categories.failureOrNull)) return;

    final lookups = await owner.getFormLookupsUseCase(
      GetCompanyExpenseFormLookupsParams(currentCompanyContext: context),
    );
    if (!owner._isCurrentCompanyRequest(generation, context)) return;
    if (_referenceFailure(lookups.failureOrNull)) return;

    final businessDate = await owner.getBusinessDateUseCase(
      GetCompanyBusinessDateParams(companyId: context.companyId),
    );
    if (!owner._isCurrentCompanyRequest(generation, context)) return;
    if (_referenceFailure(businessDate.failureOrNull)) return;

    final permission = await owner.canManageCompanyExpensesUseCase(
      CanManageCompanyExpensesParams(currentCompanyContext: context),
    );
    if (!owner._isCurrentCompanyRequest(generation, context)) return;
    if (_referenceFailure(permission.failureOrNull)) return;

    final current = state;
    if (current is! CompanyExpensesLoaded) return;
    emit(
      current.copyWith(
        categories: categories.dataOrNull!,
        formLookups: lookups.dataOrNull!,
        currentBusinessDate: businessDate.dataOrNull!,
        canManageCompanyExpenses: permission.dataOrNull!,
        realtimeRefreshFailure: null,
      ),
    );
  }

  bool _referenceFailure(Failure? failure) {
    if (failure == null) return false;
    final current = state;
    if (failure is AuthFailure || failure is PermissionFailure) {
      emit(CompanyExpensesFailure(failure));
    } else if (current is CompanyExpensesLoaded) {
      emit(current.copyWith(realtimeRefreshFailure: failure));
    }
    return true;
  }
}
