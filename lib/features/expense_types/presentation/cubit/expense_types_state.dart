import '../../../../core/errors/failure.dart';
import '../../domain/entities/expense_type.dart';
import '../../domain/entities/expense_type_status_filter.dart';

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
  final List<ExpenseType> allTypes;
  final ExpenseTypeStatusFilter statusFilter;

  const ExpenseTypesLoaded({
    required this.allTypes,
    this.statusFilter = ExpenseTypeStatusFilter.active,
  });

  List<ExpenseType> get visibleTypes =>
      allTypes.where(statusFilter.matches).toList(growable: false);

  ExpenseTypesLoaded copyWith({
    List<ExpenseType>? allTypes,
    ExpenseTypeStatusFilter? statusFilter,
  }) {
    return ExpenseTypesLoaded(
      allTypes: allTypes ?? this.allTypes,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}
