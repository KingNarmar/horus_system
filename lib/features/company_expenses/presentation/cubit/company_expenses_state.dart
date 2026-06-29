import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_expense.dart';
import '../../domain/entities/company_expense_category.dart';

const Object _notSet = Object();

sealed class CompanyExpensesState {
  const CompanyExpensesState();
}

class CompanyExpensesInitial extends CompanyExpensesState {
  const CompanyExpensesInitial();
}

class CompanyExpensesLoading extends CompanyExpensesState {
  const CompanyExpensesLoading();
}

class CompanyExpensesLoaded extends CompanyExpensesState {
  final CurrentCompanyContext currentCompanyContext;
  final List<CompanyExpenseCategory> categories;
  final List<CompanyExpense> allExpenses;
  final bool canManageCompanyExpenses;
  final String searchQuery;
  final bool includeVoided;
  final String? pendingActionExpenseId;

  const CompanyExpensesLoaded({
    required this.currentCompanyContext,
    required this.categories,
    required this.allExpenses,
    required this.canManageCompanyExpenses,
    this.searchQuery = '',
    this.includeVoided = false,
    this.pendingActionExpenseId,
  });

  List<CompanyExpense> get expenses {
    final normalizedSearch = searchQuery.trim().toLowerCase();
    final categoryNameById = {
      for (final category in categories) category.id: category.name.toLowerCase(),
    };

    return allExpenses.where((expense) {
      if (!includeVoided && expense.isVoided) return false;
      if (normalizedSearch.isEmpty) return true;

      return categoryNameById[expense.categoryId]?.contains(normalizedSearch) == true ||
          expense.amount.toString().contains(normalizedSearch) ||
          (expense.referenceNumber?.toLowerCase().contains(normalizedSearch) ?? false) ||
          (expense.notes?.toLowerCase().contains(normalizedSearch) ?? false);
    }).toList();
  }

  CompanyExpensesLoaded copyWith({
    List<CompanyExpenseCategory>? categories,
    List<CompanyExpense>? allExpenses,
    bool? canManageCompanyExpenses,
    String? searchQuery,
    bool? includeVoided,
    Object? pendingActionExpenseId = _notSet,
  }) {
    return CompanyExpensesLoaded(
      currentCompanyContext: currentCompanyContext,
      categories: categories ?? this.categories,
      allExpenses: allExpenses ?? this.allExpenses,
      canManageCompanyExpenses:
          canManageCompanyExpenses ?? this.canManageCompanyExpenses,
      searchQuery: searchQuery ?? this.searchQuery,
      includeVoided: includeVoided ?? this.includeVoided,
      pendingActionExpenseId: pendingActionExpenseId == _notSet
          ? this.pendingActionExpenseId
          : pendingActionExpenseId as String?,
    );
  }
}

class CompanyExpensesFailure extends CompanyExpensesState {
  final Failure failure;

  const CompanyExpensesFailure(this.failure);
}
