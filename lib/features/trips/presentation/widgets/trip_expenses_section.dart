import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../expenses/domain/entities/expense_type_option.dart';
import '../../../expenses/domain/entities/trip_expense.dart';
import '../../../expenses/domain/entities/trip_expense_paid_by.dart';
import '../../domain/entities/trip_entity.dart';
import '../cubit/trips_cubit.dart';
import '../cubit/trips_state.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';
import 'trip_details_helpers.dart';
import 'trip_details_shared_widgets.dart';

class TripExpensesSection extends StatelessWidget {
  final TripEntity trip;
  final TripsLoaded? state;

  const TripExpensesSection({required this.trip, required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loaded = state;

    if (loaded == null || loaded.isExpensesLoading) {
      return TripDetailsCard(children: [Text(l10n.tripLoadingExpenses)]);
    }

    final failure = loaded.expensesFailure;
    if (failure != null) return TripDetailsFailureCard(failure: failure);

    final expenses = loaded.selectedTripExpenses;

    return TripDetailsCard(
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.tripTotalExpensesLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (loaded.canManageTripExpenses)
              FilledButton.icon(
                onPressed: loaded.isTripExpenseSaving
                    ? null
                    : () => _showExpenseForm(context, trip: trip, state: loaded),
                icon: const Icon(AppIcons.add),
                label: Text(l10n.tripAddExpenseButton),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          TripFormatters.money(trip.totalExpenses, l10n.tripEmptyValue),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        if (expenses.isEmpty)
          Text(l10n.tripNoExpensesFound)
        else
          ...expenses.map(
            (expense) => _TripExpenseTile(
              expense: expense,
              canEdit: loaded.canManageTripExpenses,
              onEdit: () => _showExpenseForm(
                context,
                trip: trip,
                state: loaded,
                expense: expense,
              ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.expenseName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${formatTripDateTime(expense.expenseDate, l10n.tripEmptyValue)} • ${l10n.tripExpensePaidByValueLabel(expense.paidBy)}',
                ),
                if (typeName != l10n.tripEmptyValue)
                  Text('${l10n.tripExpenseTypeLabel}: $typeName'),
                if ((expense.notes ?? '').trim().isNotEmpty)
                  Text('${l10n.tripNotesLabel}: ${expense.notes!.trim()}'),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            TripFormatters.money(expense.amount, l10n.tripEmptyValue),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (canEdit) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: l10n.tripEditButton,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ],
      ),
    );
  }
}

class TripExpenseFormDialog extends StatefulWidget {
  final String title;
  final TripExpense? expense;
  final List<ExpenseTypeOption> expenseTypes;
  final Object? expenseTypesFailure;
  final Future<void> Function(TripExpenseFormData data) onSubmit;

  const TripExpenseFormDialog({
    required this.title,
    required this.expense,
    required this.expenseTypes,
    required this.expenseTypesFailure,
    required this.onSubmit,
    super.key,
  });

  @override
  State<TripExpenseFormDialog> createState() => _TripExpenseFormDialogState();
}

class _TripExpenseFormDialogState extends State<TripExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;
  late TripExpensePaidBy _paidBy;
  String? _expenseTypeId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _expenseTypeId = expense?.expenseTypeId;
    _paidBy = expense?.paidBy ?? TripExpensePaidBy.company;
    _nameController = TextEditingController(text: expense?.expenseName ?? '');
    _amountController = TextEditingController(
      text: expense == null ? '' : TripFormatters.number(expense.amount, ''),
    );
    _dateController = TextEditingController(
      text: _dateOnly(expense?.expenseDate ?? DateTime.now()),
    );
    _notesController = TextEditingController(text: expense?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.expenseTypesFailure != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(l10n.tripExpenseTypesUnavailable),
                  ),
                DropdownButtonFormField<String>(
                  value: _expenseTypeId,
                  decoration: InputDecoration(labelText: l10n.tripExpenseTypeLabel),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(l10n.tripOptionalNone),
                    ),
                    for (final type in widget.expenseTypes)
                      DropdownMenuItem<String>(
                        value: type.id,
                        child: Text(type.name),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _expenseTypeId = value);
                    final selected = widget.expenseTypes
                        .where((type) => type.id == value)
                        .firstOrNull;
                    if (selected != null && _nameController.text.trim().isEmpty) {
                      _nameController.text = selected.name;
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.tripExpenseNameLabel),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.tripExpenseNameRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: l10n.tripExpenseAmountLabel),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    return amount == null || amount <= 0
                        ? l10n.tripExpenseAmountPositive
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<TripExpensePaidBy>(
                  value: _paidBy,
                  decoration: InputDecoration(labelText: l10n.tripExpensePaidByLabel),
                  items: TripExpensePaidBy.values.map((paidBy) {
                    return DropdownMenuItem<TripExpensePaidBy>(
                      value: paidBy,
                      child: Text(l10n.tripExpensePaidByValueLabel(paidBy)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _paidBy = value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: l10n.tripExpenseDateLabel,
                    helperText: l10n.tripExpenseDateHelperText,
                  ),
                  validator: (value) => _parseDate(value) == null
                      ? l10n.tripExpenseDateInvalid
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: l10n.tripNotesLabel),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.tripCancelButton),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(l10n.tripSaveButton),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    final expenseDate = _parseDate(_dateController.text)!;

    setState(() => _isSaving = true);
    await widget.onSubmit(
      TripExpenseFormData(
        expenseTypeId: _expenseTypeId,
        expenseName: _nameController.text.trim(),
        amount: amount,
        paidBy: _paidBy,
        expenseDate: expenseDate,
        notes: _notesController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  DateTime? _parseDate(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class TripExpenseFormData {
  final String? expenseTypeId;
  final String expenseName;
  final double amount;
  final TripExpensePaidBy paidBy;
  final DateTime expenseDate;
  final String? notes;

  const TripExpenseFormData({
    required this.expenseTypeId,
    required this.expenseName,
    required this.amount,
    required this.paidBy,
    required this.expenseDate,
    required this.notes,
  });
}
