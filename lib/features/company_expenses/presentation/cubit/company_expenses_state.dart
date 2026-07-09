import '../../../../core/errors/failure.dart';
import '../../../../core/utils/search_text_normalizer.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_expense.dart';
import '../../domain/entities/company_expense_category.dart';
import '../../domain/entities/company_expense_form_lookups.dart';
import '../../domain/entities/company_expense_link_option.dart';

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
  final CompanyExpenseFormLookups formLookups;
  final bool canManageCompanyExpenses;
  final String searchQuery;
  final bool includeVoided;
  final String? pendingActionExpenseId;

  const CompanyExpensesLoaded({
    required this.currentCompanyContext,
    required this.categories,
    required this.allExpenses,
    required this.canManageCompanyExpenses,
    this.formLookups = const CompanyExpenseFormLookups(),
    this.searchQuery = '',
    this.includeVoided = false,
    this.pendingActionExpenseId,
  });

  List<CompanyExpense> get expenses {
    return filteredExpenses(
      categorySearchTermsById: {
        for (final category in categories)
          category.id: [category.name, if (category.code != null) category.code!],
      },
    );
  }

  String? driverLabel(String? id) => _labelFor(formLookups.drivers, id);

  String? tractorHeadLabel(String? id) =>
      _labelFor(formLookups.tractorHeads, id);

  String? trailerLabel(String? id) => _labelFor(formLookups.trailers, id);

  String? tripLabel(String? id) => _labelFor(formLookups.trips, id);

  List<CompanyExpense> filteredExpenses({
    required Map<String, Iterable<String>> categorySearchTermsById,
  }) {
    final normalizedSearch = normalizeSearchText(searchQuery);

    return allExpenses.where((expense) {
      if (!includeVoided && expense.isVoided) return false;
      if (normalizedSearch.isEmpty) return true;

      return _categoryMatchesSearch(
            categorySearchTermsById[expense.categoryId],
            normalizedSearch,
          ) ||
          expense.amount.toString().contains(normalizedSearch) ||
          _nullableTextMatchesSearch(expense.referenceNumber, normalizedSearch) ||
          _nullableTextMatchesSearch(expense.notes, normalizedSearch) ||
          _linkedLabelsMatchSearch(expense, normalizedSearch);
    }).toList();
  }

  bool _categoryMatchesSearch(
    Iterable<String>? terms,
    String normalizedSearch,
  ) {
    if (terms == null) return false;

    return terms.any(
      (term) => normalizeSearchText(term).contains(normalizedSearch),
    );
  }

  bool _nullableTextMatchesSearch(String? value, String normalizedSearch) {
    if (value == null) return false;
    return normalizeSearchText(value).contains(normalizedSearch);
  }

  bool _linkedLabelsMatchSearch(
    CompanyExpense expense,
    String normalizedSearch,
  ) {
    final labels = [
      driverLabel(expense.driverId),
      tractorHeadLabel(expense.tractorHeadId),
      trailerLabel(expense.trailerId),
      tripLabel(expense.tripId),
    ];

    return labels.any((label) {
      if (label == null) return false;
      return normalizeSearchText(label).contains(normalizedSearch);
    });
  }

  String? _labelFor(List<CompanyExpenseLinkOption> options, String? id) {
    if (id == null) return null;
    for (final option in options) {
      if (option.id == id) return option.label;
    }
    return null;
  }

  CompanyExpensesLoaded copyWith({
    List<CompanyExpenseCategory>? categories,
    List<CompanyExpense>? allExpenses,
    CompanyExpenseFormLookups? formLookups,
    bool? canManageCompanyExpenses,
    String? searchQuery,
    bool? includeVoided,
    Object? pendingActionExpenseId = _notSet,
  }) {
    return CompanyExpensesLoaded(
      currentCompanyContext: currentCompanyContext,
      categories: categories ?? this.categories,
      allExpenses: allExpenses ?? this.allExpenses,
      formLookups: formLookups ?? this.formLookups,
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
