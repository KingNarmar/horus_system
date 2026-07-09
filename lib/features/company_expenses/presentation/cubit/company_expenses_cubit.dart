import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_expense.dart';
import '../../domain/policies/company_expenses_permission_policy.dart';
import '../../domain/usecases/company_expenses_usecases.dart';
import 'company_expenses_state.dart';

class CompanyExpensesCubit extends Cubit<CompanyExpensesState> {
  final GetCompanyExpenseCategoriesUseCase getCategoriesUseCase;
  final GetCompanyExpensesUseCase getExpensesUseCase;
  final GetCompanyExpenseFormLookupsUseCase getFormLookupsUseCase;
  final AddCompanyExpenseUseCase addExpenseUseCase;
  final UpdateCompanyExpenseUseCase updateExpenseUseCase;
  final VoidCompanyExpenseUseCase voidExpenseUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;

  CurrentCompanyContext? _currentCompanyContext;

  CompanyExpensesCubit({
    required this.getCategoriesUseCase,
    required this.getExpensesUseCase,
    required this.getFormLookupsUseCase,
    required this.addExpenseUseCase,
    required this.updateExpenseUseCase,
    required this.voidExpenseUseCase,
    required this.getEntityAuditLogsUseCase,
  }) : super(const CompanyExpensesInitial());

  Future<void> loadCompanyExpenses(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    _currentCompanyContext = currentCompanyContext;
    final previousState = state;
    final previousSearchQuery = previousState is CompanyExpensesLoaded
        ? previousState.searchQuery
        : '';
    final previousIncludeVoided = previousState is CompanyExpensesLoaded
        ? previousState.includeVoided
        : false;

    emit(const CompanyExpensesLoading());

    final categoriesResult = await getCategoriesUseCase(
      GetCompanyExpenseCategoriesParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );

    await categoriesResult.when(
      success: (categories) async {
        final lookupsResult = await getFormLookupsUseCase(
          GetCompanyExpenseFormLookupsParams(
            currentCompanyContext: currentCompanyContext,
          ),
        );

        await lookupsResult.when(
          success: (formLookups) async {
            final expensesResult = await getExpensesUseCase(
              GetCompanyExpensesParams(
                currentCompanyContext: currentCompanyContext,
                includeVoided: previousIncludeVoided,
              ),
            );

            expensesResult.when(
              success: (expenses) => emit(
                CompanyExpensesLoaded(
                  currentCompanyContext: currentCompanyContext,
                  categories: categories,
                  allExpenses: expenses,
                  formLookups: formLookups,
                  searchQuery: previousSearchQuery,
                  includeVoided: previousIncludeVoided,
                  canManageCompanyExpenses:
                      CompanyExpensesPermissionPolicy.canManageCompanyExpenses(
                        currentCompanyContext.role,
                      ),
                ),
              ),
              failure: (failure) => emit(CompanyExpensesFailure(failure)),
            );
          },
          failure: (failure) async => emit(CompanyExpensesFailure(failure)),
        );
      },
      failure: (failure) async => emit(CompanyExpensesFailure(failure)),
    );
  }

  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is CompanyExpensesLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  Future<void> setIncludeVoided(bool includeVoided) async {
    final currentState = state;
    if (currentState is! CompanyExpensesLoaded) return;

    emit(currentState.copyWith(includeVoided: includeVoided));
    await loadCompanyExpenses(currentState.currentCompanyContext);
  }

  Future<void> loadExpenseActivity(CompanyExpense expense) async {
    final currentState = state;
    if (currentState is! CompanyExpensesLoaded) return;

    emit(
      currentState.copyWith(
        selectedExpense: expense,
        selectedExpenseActivity: const [],
        isActivityLoading: true,
        activityFailure: null,
      ),
    );

    final result = await getEntityAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: currentState.currentCompanyContext.companyId,
        module: AuditModule.expenses,
        entityType: AuditEntityType.expense,
        entityId: expense.id,
      ),
    );

    final latestState = state;
    if (latestState is! CompanyExpensesLoaded ||
        latestState.selectedExpense?.id != expense.id) {
      return;
    }

    result.when(
      success: (logs) => emit(
        latestState.copyWith(
          selectedExpenseActivity: logs,
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

  void clearExpenseActivity() {
    final currentState = state;
    if (currentState is! CompanyExpensesLoaded) return;

    emit(
      currentState.copyWith(
        selectedExpense: null,
        selectedExpenseActivity: const [],
        isActivityLoading: false,
        activityFailure: null,
      ),
    );
  }

  Future<void> addExpense({
    required String categoryId,
    required double amount,
    required DateTime expenseDate,
    String? driverId,
    String? tractorHeadId,
    String? trailerId,
    String? tripId,
    String? referenceNumber,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) return;

    final result = await addExpenseUseCase(
      AddCompanyExpenseParams(
        currentCompanyContext: context,
        categoryId: categoryId,
        amount: amount,
        expenseDate: expenseDate,
        driverId: driverId,
        tractorHeadId: tractorHeadId,
        trailerId: trailerId,
        tripId: tripId,
        referenceNumber: referenceNumber,
        notes: notes,
      ),
    );

    result.when(
      success: _upsertExpense,
      failure: (failure) => emit(CompanyExpensesFailure(failure)),
    );
  }

  Future<void> updateExpense({
    required CompanyExpense expense,
    required String categoryId,
    required double amount,
    required DateTime expenseDate,
    String? driverId,
    String? tractorHeadId,
    String? trailerId,
    String? tripId,
    String? referenceNumber,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) return;

    final result = await updateExpenseUseCase(
      UpdateCompanyExpenseParams(
        currentCompanyContext: context,
        expenseId: expense.id,
        categoryId: categoryId,
        amount: amount,
        expenseDate: expenseDate,
        driverId: driverId,
        tractorHeadId: tractorHeadId,
        trailerId: trailerId,
        tripId: tripId,
        referenceNumber: referenceNumber,
        notes: notes,
      ),
    );

    result.when(
      success: _upsertExpense,
      failure: (failure) => emit(CompanyExpensesFailure(failure)),
    );
  }

  Future<void> voidExpense(CompanyExpense expense, {String? reason}) async {
    final context = _currentCompanyContext;
    if (context == null || !_startPendingAction(expense.id)) return;

    final result = await voidExpenseUseCase(
      VoidCompanyExpenseParams(
        currentCompanyContext: context,
        expenseId: expense.id,
        reason: reason,
      ),
    );

    result.when(success: _upsertExpense, failure: _emitMutationFailure);
  }

  bool _startPendingAction(String expenseId) {
    final currentState = state;
    if (currentState is! CompanyExpensesLoaded) return true;
    if (currentState.pendingActionExpenseId != null) return false;

    emit(currentState.copyWith(pendingActionExpenseId: expenseId));
    return true;
  }

  void _emitMutationFailure(Failure failure) {
    final currentState = state;
    if (currentState is CompanyExpensesLoaded) {
      emit(currentState.copyWith(pendingActionExpenseId: null));
    }
    emit(CompanyExpensesFailure(failure));
  }

  void _upsertExpense(CompanyExpense expense) {
    final currentState = state;
    final context = _currentCompanyContext;

    if (currentState is! CompanyExpensesLoaded) {
      if (context != null) loadCompanyExpenses(context);
      return;
    }

    final exists = currentState.allExpenses.any(
      (item) => item.id == expense.id,
    );
    final updatedExpenses = exists
        ? currentState.allExpenses
              .map((item) => item.id == expense.id ? expense : item)
              .toList()
        : [expense, ...currentState.allExpenses];

    emit(
      currentState.copyWith(
        allExpenses: updatedExpenses,
        selectedExpense: currentState.selectedExpense?.id == expense.id
            ? expense
            : currentState.selectedExpense,
        pendingActionExpenseId: null,
      ),
    );
  }
}
