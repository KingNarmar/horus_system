import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import '../../../../core/usecases/get_company_business_date_usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_expense.dart';
import '../../domain/usecases/can_manage_company_expenses_usecase.dart';
import '../../domain/usecases/company_expenses_usecases.dart';
import 'company_expenses_state.dart';

part 'company_expenses_realtime_actions.dart';

class CompanyExpensesCubit extends Cubit<CompanyExpensesState>
    with CompanyExpensesRealtimeActions {
  final GetCompanyBusinessDateUseCase getBusinessDateUseCase;
  final CanManageCompanyExpensesUseCase canManageCompanyExpensesUseCase;
  final GetCompanyExpenseCategoriesUseCase getCategoriesUseCase;
  final GetCompanyExpensesUseCase getExpensesUseCase;
  final GetCompanyExpenseFormLookupsUseCase getFormLookupsUseCase;
  final AddCompanyExpenseUseCase addExpenseUseCase;
  final UpdateCompanyExpenseUseCase updateExpenseUseCase;
  final VoidCompanyExpenseUseCase voidExpenseUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;
  final ConvertInstantsToBusinessLocalDateTimesUseCase
  convertInstantsToBusinessLocalDateTimesUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestGeneration = 0;
  int _activityRequestGeneration = 0;
  int _expenseMutationRevision = 0;
  bool _expensesRefreshInProgress = false;
  bool _expensesRefreshPending = false;
  bool _referencesRefreshInProgress = false;
  bool _referencesRefreshPending = false;

  bool _isCurrentCompanyRequest(
    int generation,
    CurrentCompanyContext context,
  ) =>
      !isClosed &&
      generation == _loadRequestGeneration &&
      _currentCompanyContext?.companyId == context.companyId &&
      _currentCompanyContext?.role == context.role;

  CompanyExpensesCubit({
    required this.getBusinessDateUseCase,
    required this.canManageCompanyExpensesUseCase,
    required this.getCategoriesUseCase,
    required this.getExpensesUseCase,
    required this.getFormLookupsUseCase,
    required this.addExpenseUseCase,
    required this.updateExpenseUseCase,
    required this.voidExpenseUseCase,
    required this.getEntityAuditLogsUseCase,
    required this.convertInstantsToBusinessLocalDateTimesUseCase,
  }) : super(const CompanyExpensesInitial());

  Future<void> loadCompanyExpenses(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    final previous = state;
    final searchQuery = previous is CompanyExpensesLoaded
        ? previous.searchQuery
        : '';
    final includeVoided = previous is CompanyExpensesLoaded
        ? previous.includeVoided
        : false;
    _currentCompanyContext = currentCompanyContext;
    final generation = ++_loadRequestGeneration;
    ++_activityRequestGeneration;
    emit(const CompanyExpensesLoading());

    final businessDateResult = await getBusinessDateUseCase(
      GetCompanyBusinessDateParams(companyId: currentCompanyContext.companyId),
    );
    if (!_isCurrentCompanyRequest(generation, currentCompanyContext)) return;
    final businessDateFailure = businessDateResult.failureOrNull;
    if (businessDateFailure != null) {
      emit(CompanyExpensesFailure(businessDateFailure));
      return;
    }

    final categoriesResult = await getCategoriesUseCase(
      GetCompanyExpenseCategoriesParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (!_isCurrentCompanyRequest(generation, currentCompanyContext)) return;
    final categoriesFailure = categoriesResult.failureOrNull;
    if (categoriesFailure != null) {
      emit(CompanyExpensesFailure(categoriesFailure));
      return;
    }

    final lookupsResult = await getFormLookupsUseCase(
      GetCompanyExpenseFormLookupsParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (!_isCurrentCompanyRequest(generation, currentCompanyContext)) return;
    final lookupsFailure = lookupsResult.failureOrNull;
    if (lookupsFailure != null) {
      emit(CompanyExpensesFailure(lookupsFailure));
      return;
    }

    final expensesResult = await getExpensesUseCase(
      GetCompanyExpensesParams(
        currentCompanyContext: currentCompanyContext,
        includeVoided: includeVoided,
      ),
    );
    if (!_isCurrentCompanyRequest(generation, currentCompanyContext)) return;
    final expensesFailure = expensesResult.failureOrNull;
    if (expensesFailure != null) {
      emit(CompanyExpensesFailure(expensesFailure));
      return;
    }

    final permissionResult = await canManageCompanyExpensesUseCase(
      CanManageCompanyExpensesParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (!_isCurrentCompanyRequest(generation, currentCompanyContext)) return;
    final permissionFailure = permissionResult.failureOrNull;
    if (permissionFailure != null) {
      emit(CompanyExpensesFailure(permissionFailure));
      return;
    }

    emit(
      CompanyExpensesLoaded(
        currentCompanyContext: currentCompanyContext,
        currentBusinessDate: businessDateResult.dataOrNull!,
        categories: categoriesResult.dataOrNull!,
        allExpenses: expensesResult.dataOrNull!,
        formLookups: lookupsResult.dataOrNull!,
        searchQuery: searchQuery,
        includeVoided: includeVoided,
        canManageCompanyExpenses: permissionResult.dataOrNull!,
      ),
    );
    if (_expensesRefreshPending) {
      unawaited(refreshCompanyExpensesFromRealtime());
    }
    if (_referencesRefreshPending) {
      unawaited(refreshCompanyExpenseReferencesFromRealtime());
    }
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
    await refreshCompanyExpensesFromRealtime();
  }

  Future<void> loadExpenseActivity(CompanyExpense expense) async {
    final generation = ++_activityRequestGeneration;
    final currentState = state;
    if (currentState is! CompanyExpensesLoaded) return;

    emit(
      currentState.copyWith(
        selectedExpense: expense,
        selectedExpenseActivity: const [],
        selectedExpenseActivityBusinessTimesById: const {},
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
    if (generation != _activityRequestGeneration ||
        !_isCurrentCompanyRequest(
          _loadRequestGeneration,
          currentState.currentCompanyContext,
        ) ||
        latestState is! CompanyExpensesLoaded ||
        latestState.selectedExpense?.id != expense.id) {
      return;
    }

    if (result is FailureResult<List<AuditLog>>) {
      emit(
        latestState.copyWith(
          isActivityLoading: false,
          activityFailure: result.failure,
        ),
      );
      return;
    }

    final logs = (result as Success<List<AuditLog>>).data;
    final businessTimesResult =
        await convertInstantsToBusinessLocalDateTimesUseCase(
          ConvertInstantsToBusinessLocalDateTimesParams(
            timeZoneId:
                latestState.currentCompanyContext.company.businessTimezone ??
                '',
            instantsByKey: {for (final log in logs) log.id: log.createdAt},
          ),
        );

    final currentAfterConversion = state;
    if (generation != _activityRequestGeneration ||
        currentAfterConversion is! CompanyExpensesLoaded ||
        currentAfterConversion.currentCompanyContext.companyId !=
            currentState.currentCompanyContext.companyId ||
        currentAfterConversion.selectedExpense?.id != expense.id) {
      return;
    }

    if (businessTimesResult
        is FailureResult<Map<String, BusinessLocalDateTime>>) {
      emit(
        currentAfterConversion.copyWith(
          isActivityLoading: false,
          activityFailure: businessTimesResult.failure,
        ),
      );
      return;
    }

    emit(
      currentAfterConversion.copyWith(
        selectedExpenseActivity: logs,
        selectedExpenseActivityBusinessTimesById:
            (businessTimesResult as Success<Map<String, BusinessLocalDateTime>>)
                .data,
        isActivityLoading: false,
        activityFailure: null,
      ),
    );
  }

  void clearExpenseActivity() {
    ++_activityRequestGeneration;
    final currentState = state;
    if (currentState is! CompanyExpensesLoaded) return;

    emit(
      currentState.copyWith(
        selectedExpense: null,
        selectedExpenseActivity: const [],
        selectedExpenseActivityBusinessTimesById: const {},
        isActivityLoading: false,
        activityFailure: null,
      ),
    );
  }

  Future<void> addExpense({
    required String categoryId,
    required double amount,
    required BusinessDate expenseDate,
    String? driverId,
    String? tractorHeadId,
    String? trailerId,
    String? tripId,
    String? referenceNumber,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) return;

    final generation = _loadRequestGeneration;
    ++_expenseMutationRevision;
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

    if (!_isCurrentCompanyRequest(generation, context)) return;
    ++_expenseMutationRevision;
    if (!_isCurrentCompanyRequest(generation, context)) return;
    ++_expenseMutationRevision;
    result.when(
      success: _upsertExpense,
      failure: (failure) => emit(CompanyExpensesFailure(failure)),
    );
  }

  Future<void> updateExpense({
    required CompanyExpense expense,
    required String categoryId,
    required double amount,
    required BusinessDate expenseDate,
    String? driverId,
    String? tractorHeadId,
    String? trailerId,
    String? tripId,
    String? referenceNumber,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) return;

    final generation = _loadRequestGeneration;
    ++_expenseMutationRevision;
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

    final generation = _loadRequestGeneration;
    ++_expenseMutationRevision;
    final result = await voidExpenseUseCase(
      VoidCompanyExpenseParams(
        currentCompanyContext: context,
        expenseId: expense.id,
        reason: reason,
      ),
    );

    if (!_isCurrentCompanyRequest(generation, context)) return;
    ++_expenseMutationRevision;
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
      if (context != null) unawaited(loadCompanyExpenses(context));
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
