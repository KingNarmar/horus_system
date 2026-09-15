import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/expense_type.dart';
import '../../domain/entities/expense_type_status_filter.dart';
import '../../domain/usecases/get_expense_type_catalog_usecase.dart';
import 'expense_types_state.dart';

class ExpenseTypesCubit extends Cubit<ExpenseTypesState> {
  final GetExpenseTypeCatalogUseCase getExpenseTypeCatalogUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestId = 0;

  ExpenseTypesCubit({required this.getExpenseTypeCatalogUseCase})
    : super(const ExpenseTypesInitial());

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
    final result = await getExpenseTypeCatalogUseCase(
      GetExpenseTypeCatalogParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );

    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;

    result.when(
      success: (types) => emit(
        ExpenseTypesLoaded(
          allTypes: _sortTypes(types),
          statusFilter: previousFilter,
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
