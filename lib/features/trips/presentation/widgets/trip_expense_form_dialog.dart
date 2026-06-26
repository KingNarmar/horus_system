import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../expenses/domain/entities/expense_type_option.dart';
import '../../../expenses/domain/entities/trip_expense.dart';
import '../../../expenses/domain/entities/trip_expense_paid_by.dart';
import '../helpers/trip_formatters.dart';
import '../localization/trips_localizations_x.dart';

const _manualExpenseTypePrefix = 'manual:';
const _fallbackExpenseTypeNames = <String>[
  'Fuel',
  'Road fees',
  'Weighbridge',
  'Loading',
  'Unloading',
  'Fines',
  'Emergency maintenance',
  'Driver advance',
  'Other',
];

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
  String? _selectedExpenseTypeValue;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _selectedExpenseTypeValue = expense?.expenseTypeId;
    if (_selectedExpenseTypeValue == null && expense?.expenseTypeName != null) {
      _selectedExpenseTypeValue = _manualValue(expense!.expenseTypeName!);
    }
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
    final expenseTypeItems = _expenseTypeItems();

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
                DropdownButtonFormField<String?>(
                  value: _dropdownValue(expenseTypeItems),
                  decoration: InputDecoration(
                    labelText: l10n.tripExpenseTypeLabel,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.tripOptionalNone),
                    ),
                    for (final item in expenseTypeItems)
                      DropdownMenuItem<String?>(
                        value: item.value,
                        child: Text(item.name),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedExpenseTypeValue = value);
                    final selected = _findTypeChoice(value);
                    if (selected != null && _nameController.text.trim().isEmpty) {
                      _nameController.text = selected.name;
                    }
                  },
                ),
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
                  value: _paidBy,
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    final expenseDate = _parseDate(_dateController.text)!;

    setState(() => _isSaving = true);
    await widget.onSubmit(
      TripExpenseFormData(
        expenseTypeId: _selectedExpenseTypeId(),
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

  List<_ExpenseTypeChoice> _expenseTypeItems() {
    if (widget.expenseTypes.isNotEmpty) {
      final items = widget.expenseTypes.map((type) {
        return _ExpenseTypeChoice(value: type.id, name: type.name);
      }).toList();

      final manualValue = _selectedExpenseTypeValue;
      final manualName = widget.expense?.expenseTypeName;
      if (manualValue != null &&
          manualName != null &&
          !items.any((item) => item.value == manualValue)) {
        items.add(_ExpenseTypeChoice(value: manualValue, name: manualName));
      }

      return items;
    }

    return _fallbackExpenseTypeNames.map((name) {
      return _ExpenseTypeChoice(value: _manualValue(name), name: name);
    }).toList();
  }

  _ExpenseTypeChoice? _findTypeChoice(String? value) {
    if (value == null) return null;
    for (final item in _expenseTypeItems()) {
      if (item.value == value) return item;
    }
    return null;
  }

  String? _dropdownValue(List<_ExpenseTypeChoice> items) {
    final value = _selectedExpenseTypeValue;
    if (value == null) return null;
    if (items.any((item) => item.value == value)) return value;
    return null;
  }

  String? _selectedExpenseTypeId() {
    final value = _selectedExpenseTypeValue;
    if (value == null || value.startsWith(_manualExpenseTypePrefix)) {
      return null;
    }
    return value;
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

String _manualValue(String name) => '$_manualExpenseTypePrefix$name';

class _ExpenseTypeChoice {
  final String value;
  final String name;

  const _ExpenseTypeChoice({required this.value, required this.name});
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
