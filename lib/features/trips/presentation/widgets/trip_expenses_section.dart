import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../expense_types/domain/entities/expense_type.dart';
import '../../../expenses/domain/entities/expense_ledger_entry.dart';
import '../../domain/entities/trip_entity.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_details_shared_widgets.dart';
import 'trip_expense_form_dialog.dart';

class TripExpensesSection extends StatelessWidget {
  final TripEntity trip;
  final TripsLoaded? state;

  const TripExpensesSection({
    required this.trip,
    required this.state,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loaded = state;

    if (loaded == null || loaded.isExpensesLoading) {
      return TripDetailsCard(children: [Text(l10n.tripLoadingExpenses)]);
    }

    final failure = loaded.expensesFailure;
    if (failure != null) {
      return TripDetailsCard(
        children: [Text(l10n.tripExpenseFailureMessage(failure))],
      );
    }

    return TripDetailsCard(
      children: [
        _TripExpensesHeader(
          trip: trip,
          state: loaded,
          onAdd: () => _showExpenseForm(context, trip: trip, state: loaded),
        ),
        const SizedBox(height: AppSpacing.md),
        if (loaded.selectedTripExpenses.isEmpty)
          Text(l10n.tripNoExpensesFound)
        else
          for (final expense in loaded.selectedTripExpenses)
            _TripExpenseTile(
              expense: expense,
              expenseType: _findExpenseType(
                loaded.expenseTypes,
                expense.expenseTypeId,
              ),
              canVoid: loaded.canManageTripExpenses,
              isMutating: loaded.isTripExpenseMutating,
              onVoid: () => _confirmVoid(context, expense),
            ),
      ],
    );
  }

  Future<void> _showExpenseForm(
    BuildContext context, {
    required TripEntity trip,
    required TripsLoaded state,
  }) {
    final cubit = context.read<TripsCubit>();

    return showDialog<void>(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: TripExpenseFormDialog(
            expenseTypes: state.selectableExpenseTypes,
            expenseTypesFailure: state.expenseTypesFailure,
            onSubmit: (data) {
              return cubit.createTripExpense(
                tripId: trip.id,
                expenseType: data.expenseType,
                amountInput: data.amountInput,
                fundingSource: data.fundingSource,
                expenseDate: data.expenseDate,
                description: data.description,
                notes: data.notes,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmVoid(
    BuildContext context,
    ExpenseLedgerEntry expense,
  ) async {
    final cubit = context.read<TripsCubit>();
    final reasonController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final l10n = dialogContext.l10n;
          return AlertDialog(
            title: Text(l10n.tripExpensesTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.voidCompanyExpenseMessage),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(labelText: l10n.voidReasonLabel),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancelButton),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.confirmButton),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !context.mounted) return;

      final reason = reasonController.text.trim();
      await cubit.voidTripExpense(
        expense: expense,
        reason: reason.isEmpty ? null : reason,
      );
    } finally {
      reasonController.dispose();
    }
  }

  ExpenseType? _findExpenseType(List<ExpenseType> types, String id) {
    for (final type in types) {
      if (type.id == id) return type;
    }
    return null;
  }
}

class _TripExpensesHeader extends StatelessWidget {
  final TripEntity trip;
  final TripsLoaded state;
  final VoidCallback onAdd;

  const _TripExpensesHeader({
    required this.trip,
    required this.state,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tripTotalExpensesLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              TripFormatters.money(trip.totalExpenses, l10n.tripEmptyValue),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (state.canManageTripExpenses)
          FilledButton.icon(
            onPressed: state.isTripExpenseMutating ? null : onAdd,
            icon: const Icon(AppIcons.add),
            label: Text(l10n.tripAddExpenseButton),
          ),
      ],
    );
  }
}

class _TripExpenseTile extends StatelessWidget {
  final ExpenseLedgerEntry expense;
  final ExpenseType? expenseType;
  final bool canVoid;
  final bool isMutating;
  final VoidCallback onVoid;

  const _TripExpenseTile({
    required this.expense,
    required this.expenseType,
    required this.canVoid,
    required this.isMutating,
    required this.onVoid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final description = expense.description?.trim();
    final typeLabel = expenseType == null
        ? l10n.tripEmptyValue
        : l10n.tripExpenseTypeLabel(expenseType!);
    final title = description == null || description.isEmpty
        ? typeLabel
        : description;
    final notes = expense.notes?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  TripFormatters.businessDate(
                    expense.expenseDate,
                    l10n.tripEmptyValue,
                  ),
                ),
                Text(
                  l10n.tripExpenseFundingSourceLabel(expense.fundingSource),
                ),
                if (typeLabel != l10n.tripEmptyValue && title != typeLabel)
                  Text('${l10n.tripExpenseTypeLabel}: $typeLabel'),
                if (notes != null && notes.isNotEmpty)
                  Text('${l10n.tripNotesLabel}: $notes'),
              ],
            ),
          ),
          Text(
            TripFormatters.moneyMinorUnits(
              expense.amount.minorUnits,
              expense.currencyFractionDigits,
              l10n.tripEmptyValue,
            ),
          ),
          if (canVoid)
            IconButton(
              tooltip: l10n.voidCompanyExpenseButton,
              onPressed: isMutating ? null : onVoid,
              icon: const Icon(AppIcons.deactivate),
            ),
        ],
      ),
    );
  }
}
