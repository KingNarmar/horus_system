import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../expenses/domain/entities/trip_expense.dart';
import '../../domain/entities/trip_entity.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_details_helpers.dart';
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
    if (failure != null) return TripDetailsFailureCard(failure: failure);

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
              canEdit: loaded.canManageTripExpenses,
              onEdit: () => _showExpenseForm(
                context,
                trip: trip,
                state: loaded,
                expense: expense,
              ),
            ),
      ],
    );
  }

  Future<void> _showExpenseForm(
    BuildContext context, {
    required TripEntity trip,
    required TripsLoaded state,
    TripExpense? expense,
  }) {
    final cubit = context.read<TripsCubit>();
    final l10n = context.l10n;

    return showDialog<void>(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: cubit,
          child: TripExpenseFormDialog(
            title: expense == null
                ? l10n.tripAddExpenseTitle
                : l10n.tripEditExpenseTitle,
            expense: expense,
            expenseTypes: state.expenseTypes,
            expenseTypesFailure: state.expenseTypesFailure,
            onSubmit: (data) {
              return cubit.saveTripExpense(
                expense: expense,
                tripId: trip.id,
                expenseTypeId: data.expenseTypeId,
                expenseName: data.expenseName,
                amount: data.amount,
                paidBy: data.paidBy,
                expenseDate: data.expenseDate,
                notes: data.notes,
              );
            },
          ),
        );
      },
    );
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
            onPressed: state.isTripExpenseSaving ? null : onAdd,
            icon: const Icon(AppIcons.add),
            label: Text(l10n.tripAddExpenseButton),
          ),
      ],
    );
  }
}

class _TripExpenseTile extends StatelessWidget {
  final TripExpense expense;
  final bool canEdit;
  final VoidCallback onEdit;

  const _TripExpenseTile({
    required this.expense,
    required this.canEdit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typeName = TripFormatters.optionalText(
      expense.expenseTypeName,
      l10n.tripEmptyValue,
    );
    final notes = expense.notes?.trim();
    final expenseName = l10n.tripExpenseTypeName(expense.expenseName);
    final localizedTypeName = typeName == l10n.tripEmptyValue
        ? typeName
        : l10n.tripExpenseTypeName(typeName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expenseName),
                Text(
                  formatTripDateTime(expense.expenseDate, l10n.tripEmptyValue),
                ),
                Text(l10n.tripExpensePaidByValueLabel(expense.paidBy)),
                if (localizedTypeName != l10n.tripEmptyValue)
                  Text('${l10n.tripExpenseTypeLabel}: $localizedTypeName'),
                if (notes != null && notes.isNotEmpty)
                  Text('${l10n.tripNotesLabel}: $notes'),
              ],
            ),
          ),
          Text(TripFormatters.money(expense.amount, l10n.tripEmptyValue)),
          if (canEdit)
            IconButton(
              tooltip: l10n.tripEditButton,
              onPressed: onEdit,
              icon: const Icon(AppIcons.edit),
            ),
        ],
      ),
    );
  }
}
