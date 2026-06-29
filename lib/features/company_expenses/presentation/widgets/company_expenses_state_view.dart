import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_expense.dart';
import '../cubit/company_expenses_state.dart';

class CompanyExpensesStateView extends StatelessWidget {
  final CompanyExpensesState state;
  final VoidCallback onRetry;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onIncludeVoidedChanged;
  final ValueChanged<CompanyExpense> onEdit;
  final ValueChanged<CompanyExpense> onVoid;

  const CompanyExpensesStateView({
    required this.state,
    required this.onRetry,
    required this.onSearchChanged,
    required this.onIncludeVoidedChanged,
    required this.onEdit,
    required this.onVoid,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentState = state;

    if (currentState is CompanyExpensesInitial ||
        currentState is CompanyExpensesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentState is CompanyExpensesFailure) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Text(
                l10n.localizedErrorMessage(currentState.failure),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(onPressed: onRetry, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }

    if (currentState is! CompanyExpensesLoaded) return const SizedBox.shrink();

    final categoriesById = {
      for (final category in currentState.categories)
        category.id: category.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 420,
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(AppIcons.search),
                  hintText: l10n.searchCompanyExpensesHint,
                ),
              ),
            ),
            FilterChip(
              selected: currentState.includeVoided,
              label: Text(l10n.includeVoidedCompanyExpenses),
              onSelected: onIncludeVoidedChanged,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (currentState.allExpenses.isEmpty)
          _EmptyMessage(message: l10n.noCompanyExpensesFound)
        else if (currentState.expenses.isEmpty)
          _EmptyMessage(message: l10n.noCompanyExpensesMatchFilters)
        else
          ...currentState.expenses.map(
            (expense) => _ExpenseCard(
              expense: expense,
              categoryName:
                  categoriesById[expense.categoryId] ?? expense.categoryId,
              canManage: currentState.canManageCompanyExpenses,
              isPending: currentState.pendingActionExpenseId == expense.id,
              onEdit: onEdit,
              onVoid: onVoid,
            ),
          ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final CompanyExpense expense;
  final String categoryName;
  final bool canManage;
  final bool isPending;
  final ValueChanged<CompanyExpense> onEdit;
  final ValueChanged<CompanyExpense> onVoid;

  const _ExpenseCard({
    required this.expense,
    required this.categoryName,
    required this.canManage,
    required this.isPending,
    required this.onEdit,
    required this.onVoid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = expense.isVoided
        ? l10n.companyExpenseVoidedStatus
        : l10n.companyExpenseActiveStatus;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    categoryName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.companyExpenseAmountLine(expense.amount.toStringAsFixed(2)),
            ),
            Text(l10n.companyExpenseDateLine(_dateOnly(expense.expenseDate))),
            if (expense.referenceNumber != null)
              Text(l10n.companyExpenseReferenceLine(expense.referenceNumber!)),
            if (expense.notes != null) Text(expense.notes!),
            if (canManage && !expense.isVoided) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: isPending ? null : () => onEdit(expense),
                    icon: const Icon(AppIcons.edit),
                    label: Text(l10n.editCustomerButton),
                  ),
                  OutlinedButton.icon(
                    onPressed: isPending ? null : () => onVoid(expense),
                    icon: isPending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(AppIcons.deactivate),
                    label: Text(l10n.voidCompanyExpenseButton),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
