import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_category.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_form_lookups.dart';
import 'package:horus_system/features/company_expenses/domain/entities/company_expense_link_option.dart';
import 'package:horus_system/features/company_expenses/presentation/cubit/company_expenses_state.dart';

void main() {
  group('CompanyExpensesLoaded.filteredExpenses', () {
    test('finds localized Arabic category terms without hamza variants', () {
      final state = _loadedState(searchQuery: 'اطارات');

      final expenses = state.filteredExpenses(
        categorySearchTermsById: _localizedCategorySearchTerms,
      );

      expect(expenses, hasLength(1));
      expect(expenses.single.id, 'tires-expense');
    });

    test('finds English category terms', () {
      final state = _loadedState(searchQuery: 'tires');

      final expenses = state.filteredExpenses(
        categorySearchTermsById: _localizedCategorySearchTerms,
      );

      expect(expenses, hasLength(1));
      expect(expenses.single.id, 'tires-expense');
    });

    test('finds linked driver labels', () {
      final state = _loadedState(searchQuery: 'Mina Driver');

      final expenses = state.filteredExpenses(
        categorySearchTermsById: _localizedCategorySearchTerms,
      );

      expect(expenses, hasLength(1));
      expect(expenses.single.id, 'tires-expense');
    });

    test('finds linked tractor head labels', () {
      final state = _loadedState(searchQuery: 'TH-100');

      final expenses = state.filteredExpenses(
        categorySearchTermsById: _localizedCategorySearchTerms,
      );

      expect(expenses, hasLength(1));
      expect(expenses.single.id, 'tires-expense');
    });

    test('hides voided expenses when includeVoided is false', () {
      final state = _loadedState(searchQuery: 'fines');

      final expenses = state.filteredExpenses(
        categorySearchTermsById: _localizedCategorySearchTerms,
      );

      expect(expenses, isEmpty);
    });

    test('includes voided expenses in search when includeVoided is true', () {
      final state = _loadedState(searchQuery: 'غرامات', includeVoided: true);

      final expenses = state.filteredExpenses(
        categorySearchTermsById: _localizedCategorySearchTerms,
      );

      expect(expenses, hasLength(1));
      expect(expenses.single.id, 'fines-expense');
    });
  });
}

const _companyId = 'company-1';

final _localizedCategorySearchTerms = {
  'category-tires': ['Tires', 'tires', 'الإطارات'],
  'category-fines': ['Fines', 'fines', 'الغرامات'],
};

CompanyExpensesLoaded _loadedState({
  required String searchQuery,
  bool includeVoided = false,
}) {
  return CompanyExpensesLoaded(
    currentCompanyContext: const CurrentCompanyContext(
      company: Company(id: _companyId, name: 'Test Company'),
      role: CompanyRole.accountant,
    ),
    categories: const [
      CompanyExpenseCategory(
        id: 'category-tires',
        companyId: _companyId,
        name: 'Tires',
        code: 'tires',
        isActive: true,
      ),
      CompanyExpenseCategory(
        id: 'category-fines',
        companyId: _companyId,
        name: 'Fines',
        code: 'fines',
        isActive: true,
      ),
    ],
    allExpenses: [
      _expense(
        id: 'tires-expense',
        categoryId: 'category-tires',
        amount: 250,
        referenceNumber: 'TYR-001',
        driverId: 'driver-1',
        tractorHeadId: 'tractor-1',
      ),
      _expense(
        id: 'fines-expense',
        categoryId: 'category-fines',
        amount: 100,
        referenceNumber: 'FINE-001',
        isVoided: true,
      ),
    ],
    formLookups: const CompanyExpenseFormLookups(
      drivers: [CompanyExpenseLinkOption(id: 'driver-1', label: 'Mina Driver')],
      tractorHeads: [
        CompanyExpenseLinkOption(id: 'tractor-1', label: 'TH-100'),
      ],
    ),
    canManageCompanyExpenses: true,
    searchQuery: searchQuery,
    includeVoided: includeVoided,
  );
}

CompanyExpense _expense({
  required String id,
  required String categoryId,
  required double amount,
  required String referenceNumber,
  String? driverId,
  String? tractorHeadId,
  bool isVoided = false,
}) {
  return CompanyExpense(
    id: id,
    companyId: _companyId,
    categoryId: categoryId,
    driverId: driverId,
    tractorHeadId: tractorHeadId,
    amount: amount,
    expenseDate: DateTime(2026, 7, 3),
    referenceNumber: referenceNumber,
    isVoided: isVoided,
  );
}
