import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../expense_types/domain/entities/expense_type.dart';
import '../../../expenses/domain/entities/trip_expense.dart';
import '../../../expenses/domain/entities/trip_expense_paid_by.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';

class TripExpenseFormDialog extends StatefulWidget {
  final String title;
  final TripExpense? expense;
  final List<ExpenseType> expenseTypes;
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
    final selectedType = _selectedType();
    final isOther = _isOtherExpenseType(selectedType?.name);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
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
                  initialValue: _dropdownValue(),
                  decoration: InputDecoration(
                    labelText: l10n.tripExpenseTypeLabel,
                  ),
                  items: widget.expenseTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type.id,
                      child: Text(l10n.tripExpenseTypeName(type.name)),
                    );
                  }).toList(),
                  validator: (value) =>
                      value == null ? l10n.tripExpenseTypeRequired : null,
                  onChanged: widget.expenseTypes.isEmpty
                      ? null
                      : (value) => _onExpenseTypeChanged(value),
                ),
                if (widget.expenseTypes.isEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(l10n.tripExpenseTypesUnavailable),
                  ),
                ],
                if (isOther) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.tripExpenseNameLabel,
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.tripExpenseNameRequired
                        : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: l10n.tripExpenseAmountLabel,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    return amount == null || amount <= 0
                        ? l10n.tripExpenseAmountPositive
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<TripExpensePaidBy>(
                  initialValue: _paidBy,
                  decoration: InputDecoration(
                    labelText: l10n.tripExpensePaidByLabel,
                  ),
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

  void _onExpenseTypeChanged(String? value) {
    final selected = _findType(value);
    setState(() {
      _expenseTypeId = value;
      if (!_isOtherExpenseType(selected?.name)) {
        _nameController.text = selected?.name ?? '';
      } else {
        _nameController.clear();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedType = _selectedType();
    if (selectedType == null) return;

    final amount = double.parse(_amountController.text.trim());
    final expenseDate = _parseDate(_dateController.text)!;
    final expenseName = _isOtherExpenseType(selectedType.name)
        ? _nameController.text.trim()
        : selectedType.name;

    setState(() => _isSaving = true);
    await widget.onSubmit(
      TripExpenseFormData(
        expenseTypeId: selectedType.id,
        expenseName: expenseName,
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

  String? _dropdownValue() {
    final value = _expenseTypeId;
    if (value == null) return null;
    if (widget.expenseTypes.any((type) => type.id == value)) return value;
    return null;
  }

  ExpenseType? _selectedType() => _findType(_expenseTypeId);

  ExpenseType? _findType(String? id) {
    if (id == null) return null;
    for (final type in widget.expenseTypes) {
      if (type.id == id) return type;
    }
    return null;
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

bool _isOtherExpenseType(String? name) {
  final normalized = name?.trim().toLowerCase().replaceAll(' ', '_');
  return normalized == 'other' || normalized == 'أخرى' || normalized == 'اخرى';
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
