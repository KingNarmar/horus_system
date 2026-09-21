import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../../expense_types/domain/entities/expense_type.dart';
import '../../../expense_types/domain/policies/expense_type_semantics.dart';
import '../../../expenses/domain/entities/expense_funding_source.dart';
import '../localization/trips_localizations_x.dart';

class TripExpenseFormDialog extends StatefulWidget {
  final BusinessDate initialExpenseDate;
  final List<ExpenseType> expenseTypes;
  final Object? expenseTypesFailure;
  final Future<void> Function(TripExpenseFormData data) onSubmit;

  const TripExpenseFormDialog({
    required this.initialExpenseDate,
    required this.expenseTypes,
    required this.expenseTypesFailure,
    required this.onSubmit,
    super.key,
  });

  @override
  State<TripExpenseFormDialog> createState() => _TripExpenseFormDialogState();
}

class _TripExpenseFormDialogState extends State<TripExpenseFormDialog> {
  static final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;
  ExpenseFundingSource _fundingSource = ExpenseFundingSource.company;
  String? _expenseTypeId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController();
    _dateController = TextEditingController(
      text: _dateOnly(widget.initialExpenseDate),
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedType = _selectedType();
    final requiresDescription =
        selectedType != null &&
        ExpenseTypeSemantics.requiresDescription(selectedType);

    return AlertDialog(
      title: Text(l10n.tripAddExpenseTitle),
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
                  initialValue: _expenseTypeId,
                  decoration: InputDecoration(
                    labelText: l10n.tripExpenseTypeLabel,
                  ),
                  items: widget.expenseTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type.id,
                      child: Text(l10n.tripExpenseTypeDisplayLabel(type)),
                    );
                  }).toList(),
                  validator: (value) =>
                      value == null ? l10n.tripExpenseTypeRequired : null,
                  onChanged: widget.expenseTypes.isEmpty
                      ? null
                      : (value) => setState(() => _expenseTypeId = value),
                ),
                if (widget.expenseTypes.isEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(l10n.tripExpenseTypesUnavailable),
                  ),
                ],
                if (requiresDescription) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descriptionController,
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
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? l10n.tripExpenseAmountPositive
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<ExpenseFundingSource>(
                  initialValue: _fundingSource,
                  decoration: InputDecoration(
                    labelText: l10n.tripExpensePaidByLabel,
                  ),
                  items: ExpenseFundingSource.values.map((fundingSource) {
                    return DropdownMenuItem<ExpenseFundingSource>(
                      value: fundingSource,
                      child: Text(
                        l10n.tripExpenseFundingSourceLabel(fundingSource),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _fundingSource = value);
                    }
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

    final selectedType = _selectedType();
    if (selectedType == null) return;

    final expenseDate = _parseDate(_dateController.text);
    if (expenseDate == null) return;

    setState(() => _isSaving = true);
    await widget.onSubmit(
      TripExpenseFormData(
        expenseType: selectedType,
        amountInput: _amountController.text.trim(),
        fundingSource: _fundingSource,
        expenseDate: expenseDate,
        description: ExpenseTypeSemantics.requiresDescription(selectedType)
            ? _descriptionController.text.trim()
            : null,
        notes: _notesController.text.trim(),
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  ExpenseType? _selectedType() {
    final id = _expenseTypeId;
    if (id == null) return null;
    for (final type in widget.expenseTypes) {
      if (type.id == id) return type;
    }
    return null;
  }

  BusinessDate? _parseDate(String? value) {
    final text = value?.trim();
    if (text == null || !_datePattern.hasMatch(text)) return null;
    final parts = text.split('-');
    return BusinessDate.tryCreate(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      day: int.parse(parts[2]),
    );
  }

  String _dateOnly(BusinessDate value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

final class TripExpenseFormData {
  final ExpenseType expenseType;
  final String amountInput;
  final ExpenseFundingSource fundingSource;
  final BusinessDate expenseDate;
  final String? description;
  final String? notes;

  const TripExpenseFormData({
    required this.expenseType,
    required this.amountInput,
    required this.fundingSource,
    required this.expenseDate,
    this.description,
    this.notes,
  });
}
