import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_expense.dart';
import '../cubit/company_expenses_state.dart';
import '../helpers/company_expense_date_formatter.dart';
import '../localization/company_expense_category_localizations_x.dart';

class CompanyExpensesStateView extends StatelessWidget {
  final CompanyExpensesState state;
  final VoidCallback onRetry;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onIncludeVoidedChanged;
  final ValueChanged<CompanyExpense> onViewDetails;
  final ValueChanged<CompanyExpense> onEdit;
  final ValueChanged<CompanyExpense> onVoid;

  const CompanyExpensesStateView({
    required this.state,
    required this.onRetry,
    required this.onSearchChanged,
    required this.onIncludeVoidedChanged,
    required this.onViewDetails,
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
        category.id: l10n.companyExpenseCategoryName(
          code: category.code,
          fallbackName: category.name,
        ),
    };
    final categorySearchTermsById = {
      for (final category in currentState.categories)
        category.id: [
          category.name,
          if (category.code != null) category.code!,
          categoriesById[category.id] ?? category.name,
        ],
    };
    final visibleExpenses = currentState.filteredExpenses(
      categorySearchTermsById: categorySearchTermsById,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: AppSizes.searchFieldMaxWidth,
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
        else if (visibleExpenses.isEmpty)
          _EmptyMessage(message: l10n.noCompanyExpensesMatchFilters)
        else
          ...visibleExpenses.map(
            (expense) => _ExpenseCard(
              expense: expense,
              categoryName:
                  categoriesById[expense.categoryId] ?? expense.categoryId,
              driverLabel: _displayLinkedLabel(
                id: expense.driverId,
                label: currentState.driverLabel(expense.driverId),
                unavailableLabel: l10n.fleetNotAvailable,
              ),
              tractorHeadLabel: _displayLinkedLabel(
                id: expense.tractorHeadId,
                label: currentState.tractorHeadLabel(expense.tractorHeadId),
                unavailableLabel: l10n.fleetNotAvailable,
              ),
              trailerLabel: _displayLinkedLabel(
                id: expense.trailerId,
                label: currentState.trailerLabel(expense.trailerId),
                unavailableLabel: l10n.fleetNotAvailable,
              ),
              tripLabel: _displayLinkedLabel(
                id: expense.tripId,
                label: currentState.tripLabel(expense.tripId),
                unavailableLabel: l10n.fleetNotAvailable,
              ),
              canManage: currentState.canManageCompanyExpenses,
              isPending: currentState.pendingActionExpenseId == expense.id,
              onViewDetails: onViewDetails,
              onEdit: onEdit,
              onVoid: onVoid,
            ),
          ),
      ],
    );
  }

  String? _displayLinkedLabel({
    required String? id,
    required String? label,
    required String unavailableLabel,
  }) {
    if (id == null) return null;
    return label ?? unavailableLabel;
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
  final String? driverLabel;
  final String? tractorHeadLabel;
  final String? trailerLabel;
  final String? tripLabel;
  final bool canManage;
  final bool isPending;
  final ValueChanged<CompanyExpense> onViewDetails;
  final ValueChanged<CompanyExpense> onEdit;
  final ValueChanged<CompanyExpense> onVoid;

  const _ExpenseCard({
    required this.expense,
    required this.categoryName,
    required this.driverLabel,
    required this.tractorHeadLabel,
    required this.trailerLabel,
    required this.tripLabel,
    required this.canManage,
    required this.isPending,
    required this.onViewDetails,
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
            Text(
              l10n.companyExpenseDateLine(
                formatCompanyExpenseDate(expense.expenseDate),
              ),
            ),
            if (driverLabel != null)
              Text(_linkedLine(l10n.driverNameLabel, driverLabel!)),
            if (tractorHeadLabel != null)
              Text(_linkedLine(l10n.tractorHeadsTab, tractorHeadLabel!)),
            if (trailerLabel != null)
              Text(_linkedLine(l10n.trailersTab, trailerLabel!)),
            if (tripLabel != null)
              Text(_linkedLine(l10n.driverMovementTripLine, tripLabel!)),
            if (expense.referenceNumber != null)
              Text(l10n.companyExpenseReferenceLine(expense.referenceNumber!)),
            if (expense.notes != null) Text(expense.notes!),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onViewDetails(expense),
                  icon: const Icon(AppIcons.info),
                  label: Text(l10n.fleetDetailsButton),
                ),
                if (canManage && !expense.isVoided) ...[
                  OutlinedButton.icon(
                    onPressed: isPending ? null : () => onEdit(expense),
                    icon: const Icon(AppIcons.edit),
                    label: Text(l10n.editCompanyExpenseTitle),
                  ),
                  OutlinedButton.icon(
                    onPressed: isPending ? null : () => onVoid(expense),
                    icon: isPending
                        ? const SizedBox.square(
                            dimension: AppSizes.loadingIndicatorSm,
                            child: CircularProgressIndicator(
                              strokeWidth: AppSizes.loadingIndicatorStrokeWidth,
                            ),
                          )
                        : const Icon(AppIcons.deactivate),
                    label: Text(l10n.voidCompanyExpenseButton),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _linkedLine(String label, String value) => '$label: $value';
}
