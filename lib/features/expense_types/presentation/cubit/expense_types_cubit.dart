import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/expense_type.dart';
import '../../domain/entities/expense_type_status_filter.dart';
import '../../domain/policies/expense_types_permission_policy.dart';
import '../../domain/usecases/add_expense_type_usecase.dart';
import '../../domain/usecases/deactivate_expense_type_usecase.dart';
import '../../domain/usecases/get_expense_types_usecase.dart';
import '../../domain/usecases/reactivate_expense_type_usecase.dart';
import '../../domain/usecases/update_expense_type_usecase.dart';
import 'expense_types_state.dart';

class ExpenseTypesCubit extends Cubit<ExpenseTypesState> {
  final GetExpenseTypesUseCase getExpenseTypesUseCase;
  final AddExpenseTypeUseCase addExpenseTypeUseCase;
  final UpdateExpenseTypeUseCase updateExpenseTypeUseCase;
  final DeactivateExpenseTypeUseCase deactivateExpenseTypeUseCase;
  final ReactivateExpenseTypeUseCase reactivateExpenseTypeUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestId = 0;

  ExpenseTypesCubit({
    required this.getExpenseTypesUseCase,
    required this.addExpenseTypeUseCase,
    required this.updateExpenseTypeUseCase,
    required this.deactivateExpenseTypeUseCase,
    required this.reactivateExpenseTypeUseCase,
  }) : super(const ExpenseTypesInitial());

  Future<void> loadExpenseTypes(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_loadRequestId;
    final previousState = state;
    final previousFilter = previousState is ExpenseTypesLoaded
        ? previousState.statusFilter
        : ExpenseTypeStatusFilter.active;

    emit(const ExpenseTypesLoading());
    final result = await getExpenseTypesUseCase(
      GetExpenseTypesParams(currentCompanyContext: currentCompanyContext),
    );

    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;

    result.when(
      success: (types) => emit(
        ExpenseTypesLoaded(
          currentCompanyContext: currentCompanyContext,
          allTypes: _sortTypes(types),
          statusFilter: previousFilter,
          canManageExpenseTypes:
              ExpenseTypesPermissionPolicy.canManageExpenseTypes(
                currentCompanyContext.role,
              ),
        ),
      ),
      failure: (failure) => emit(ExpenseTypesFailure(failure)),
    );
  }

  void setStatusFilter(ExpenseTypeStatusFilter filter) {
    final currentState = state;
    if (currentState is ExpenseTypesLoaded) {
      emit(currentState.copyWith(statusFilter: filter));
    }
  }

  Future<bool> addExpenseType(String name) {
    return _submitMutation(
      execute: (context) => addExpenseTypeUseCase(
        AddExpenseTypeParams(currentCompanyContext: context, name: name),
      ),
      mutation: ExpenseTypeMutation.created,
    );
  }

  Future<bool> updateExpenseType({
    required ExpenseType expenseType,
    required String name,
  }) {
    return _submitMutation(
      execute: (context) => updateExpenseTypeUseCase(
        UpdateExpenseTypeParams(
          currentCompanyContext: context,
          expenseTypeId: expenseType.id,
          name: name,
        ),
      ),
      mutation: ExpenseTypeMutation.updated,
    );
  }

  Future<bool> deactivateExpenseType(ExpenseType expenseType) {
    return _statusMutation(
      expenseType: expenseType,
      execute: (context) => deactivateExpenseTypeUseCase(
        DeactivateExpenseTypeParams(
          currentCompanyContext: context,
          expenseTypeId: expenseType.id,
        ),
      ),
      mutation: ExpenseTypeMutation.deactivated,
    );
  }

  Future<bool> reactivateExpenseType(ExpenseType expenseType) {
    return _statusMutation(
      expenseType: expenseType,
      execute: (context) => reactivateExpenseTypeUseCase(
        ReactivateExpenseTypeParams(
          currentCompanyContext: context,
          expenseTypeId: expenseType.id,
        ),
      ),
      mutation: ExpenseTypeMutation.reactivated,
    );
  }

  Future<bool> _submitMutation({
    required Future<Result<ExpenseType>> Function(
      CurrentCompanyContext context,
    ) execute,
    required ExpenseTypeMutation mutation,
  }) async {
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null ||
        currentState is! ExpenseTypesLoaded ||
        currentState.isMutationPending) {
      return false;
    }

    final companyId = context.companyId;
    emit(
      currentState.copyWith(
        isSubmitting: true,
        mutationFailure: null,
        completedMutation: null,
      ),
    );

    final result = await execute(context);
    if (!_isCurrentCompany(companyId)) return false;

    final latestState = state;
    if (latestState is! ExpenseTypesLoaded) return false;

    var succeeded = false;
    result.when(
      success: (type) {
        succeeded = true;
        _emitMutationSuccess(
          state: latestState,
          type: type,
          mutation: mutation,
        );
      },
      failure: (failure) {
        _emitMutationFailure(
          state: latestState,
          failure: failure,
          clearSubmitting: true,
        );
      },
    );
    return succeeded;
  }

  Future<bool> _statusMutation({
    required ExpenseType expenseType,
    required Future<Result<ExpenseType>> Function(
      CurrentCompanyContext context,
    ) execute,
    required ExpenseTypeMutation mutation,
  }) async {
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null ||
        currentState is! ExpenseTypesLoaded ||
        currentState.isMutationPending) {
      return false;
    }

    final companyId = context.companyId;
    emit(
      currentState.copyWith(
        pendingActionExpenseTypeId: expenseType.id,
        mutationFailure: null,
        completedMutation: null,
      ),
    );

    final result = await execute(context);
    if (!_isCurrentCompany(companyId)) return false;

    final latestState = state;
    if (latestState is! ExpenseTypesLoaded) return false;

    var succeeded = false;
    result.when(
      success: (type) {
        succeeded = true;
        _emitMutationSuccess(
          state: latestState,
          type: type,
          mutation: mutation,
        );
      },
      failure: (failure) {
        _emitMutationFailure(
          state: latestState,
          failure: failure,
          clearPendingAction: true,
        );
      },
    );
    return succeeded;
  }

  void _emitMutationSuccess({
    required ExpenseTypesLoaded state,
    required ExpenseType type,
    required ExpenseTypeMutation mutation,
  }) {
    final updated = [...state.allTypes];
    final index = updated.indexWhere((item) => item.id == type.id);
    if (index == -1) {
      updated.add(type);
    } else {
      updated[index] = type;
    }

    emit(
      state.copyWith(
        allTypes: _sortTypes(updated),
        pendingActionExpenseTypeId: null,
        isSubmitting: false,
        mutationFailure: null,
        completedMutation: mutation,
        feedbackSequence: state.feedbackSequence + 1,
      ),
    );
  }

  void _emitMutationFailure({
    required ExpenseTypesLoaded state,
    required Failure failure,
    bool clearSubmitting = false,
    bool clearPendingAction = false,
  }) {
    emit(
      state.copyWith(
        pendingActionExpenseTypeId: clearPendingAction
            ? null
            : state.pendingActionExpenseTypeId,
        isSubmitting: clearSubmitting ? false : state.isSubmitting,
        mutationFailure: failure,
        completedMutation: null,
        feedbackSequence: state.feedbackSequence + 1,
      ),
    );
  }

  bool _isCurrentLoad(int requestId, String companyId) {
    return requestId == _loadRequestId && _isCurrentCompany(companyId);
  }

  bool _isCurrentCompany(String companyId) {
    return _currentCompanyContext?.companyId == companyId;
  }

  List<ExpenseType> _sortTypes(Iterable<ExpenseType> types) {
    final sorted = types.toList();
    sorted.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return sorted;
  }
}
