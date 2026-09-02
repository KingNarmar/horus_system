import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/expense_type.dart';
import '../../domain/entities/expense_type_status_filter.dart';

enum ExpenseTypeMutation { created, updated, deactivated, reactivated }

sealed class ExpenseTypesState {
  const ExpenseTypesState();
}

final class ExpenseTypesInitial extends ExpenseTypesState {
  const ExpenseTypesInitial();
}

final class ExpenseTypesLoading extends ExpenseTypesState {
  const ExpenseTypesLoading();
}

final class ExpenseTypesFailure extends ExpenseTypesState {
  final Failure failure;

  const ExpenseTypesFailure(this.failure);
}

final class ExpenseTypesLoaded extends ExpenseTypesState {
  static const Object _unset = Object();

  final CurrentCompanyContext currentCompanyContext;
  final List<ExpenseType> allTypes;
  final ExpenseTypeStatusFilter statusFilter;
  final bool canManageExpenseTypes;
  final String? pendingActionExpenseTypeId;
  final bool isSubmitting;
  final Failure? mutationFailure;
  final ExpenseTypeMutation? completedMutation;
  final int feedbackSequence;

  const ExpenseTypesLoaded({
    required this.currentCompanyContext,
    required this.allTypes,
    required this.canManageExpenseTypes,
    this.statusFilter = ExpenseTypeStatusFilter.active,
    this.pendingActionExpenseTypeId,
    this.isSubmitting = false,
    this.mutationFailure,
    this.completedMutation,
    this.feedbackSequence = 0,
  });

  List<ExpenseType> get visibleTypes =>
      allTypes.where(statusFilter.matches).toList(growable: false);

  bool get isMutationPending =>
      isSubmitting || pendingActionExpenseTypeId != null;

  ExpenseTypesLoaded copyWith({
    List<ExpenseType>? allTypes,
    ExpenseTypeStatusFilter? statusFilter,
    bool? canManageExpenseTypes,
    Object? pendingActionExpenseTypeId = _unset,
    bool? isSubmitting,
    Object? mutationFailure = _unset,
    Object? completedMutation = _unset,
    int? feedbackSequence,
  }) {
    return ExpenseTypesLoaded(
      currentCompanyContext: currentCompanyContext,
      allTypes: allTypes ?? this.allTypes,
      statusFilter: statusFilter ?? this.statusFilter,
      canManageExpenseTypes:
          canManageExpenseTypes ?? this.canManageExpenseTypes,
      pendingActionExpenseTypeId: identical(pendingActionExpenseTypeId, _unset)
          ? this.pendingActionExpenseTypeId
          : pendingActionExpenseTypeId as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      mutationFailure: identical(mutationFailure, _unset)
          ? this.mutationFailure
          : mutationFailure as Failure?,
      completedMutation: identical(completedMutation, _unset)
          ? this.completedMutation
          : completedMutation as ExpenseTypeMutation?,
      feedbackSequence: feedbackSequence ?? this.feedbackSequence,
    );
  }
}
