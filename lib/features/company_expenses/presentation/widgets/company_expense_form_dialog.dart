import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/company_expense.dart';
import '../../domain/entities/company_expense_category.dart';
import '../../domain/entities/company_expense_form_lookups.dart';
import '../../domain/entities/company_expense_link_option.dart';
import '../constants/company_expense_presentation_constants.dart';
import '../helpers/company_expense_date_formatter.dart';
import '../localization/company_expense_category_localizations_x.dart';

class CompanyExpenseFormData {
  final String categoryId;
  final double amount;
  final DateTime expenseDate;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? tripId;
  final String? referenceNumber;
  final String? notes;

  const CompanyExpenseFormData({
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.tripId,
    this.referenceNumber,
    this.notes,
  });
}

class CompanyExpenseFormDialog extends StatefulWidget {
  final List<CompanyExpenseCategory> categories;
  final CompanyExpenseFormLookups formLookups;
  final CompanyExpense? expense;
  final Future<void> Function(CompanyExpenseFormData data) onSubmit;

  const CompanyExpenseFormDialog({
    required this.categories,
    required this.formLookups,
    required this.onSubmit,
    this.expense,
    super.key,
  });

  @override
  State<CompanyExpenseFormDialog> createState() =>
      _CompanyExpenseFormDialogState();
}

class _CompanyExpenseFormDialogState extends State<CompanyExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedDriverId;
  String? _selectedTractorHeadId;
  String? _selectedTrailerId;
  String? _selectedTripId;
  late DateTime _expenseDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _selectedCategoryId =
        expense?.categoryId ??
        (widget.categories.isEmpty ? null : widget.categories.first.id);
    _selectedDriverId = expense?.driverId;
    _selectedTractorHeadId = expense?.tractorHeadId;
    _selectedTrailerId = expense?.trailerId;
    _selectedTripId = expense?.tripId;
    _expenseDate = expense?.expenseDate ?? DateTime.now();
    _amountController.text = expense?.amount.toStringAsFixed(2) ?? '';
    _referenceController.text = expense?.referenceNumber ?? '';
    _notesController.text = expense?.notes ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(
        CompanyExpensePresentationConstants.expenseDatePickerFirstYear,
      ),
      lastDate: DateTime(
        CompanyExpensePresentationConstants.expenseDatePickerLastYear,
      ),
    );
    if (picked == null) return;
    setState(() => _expenseDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final categoryId = _selectedCategoryId;
    if (categoryId == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) return;

    setState(() => _isSaving = true);
    await widget.onSubmit(
      CompanyExpenseFormData(
        categoryId: categoryId,
        amount: amount,
        expenseDate: _expenseDate,
        driverId: _selectedDriverId,
        tractorHeadId: _selectedTractorHeadId,
        trailerId: _selectedTrailerId,
        tripId: _selectedTripId,
        referenceNumber: _optional(_referenceController.text),
        notes: _optional(_notesController.text),
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditing = widget.expense != null;

    return AlertDialog(
      title: Text(
        isEditing ? l10n.editCompanyExpenseTitle : l10n.addCompanyExpenseTitle,
      ),
      content: SizedBox(
        width: AppSizes.formDialogMaxWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: l10n.companyExpenseCategoryLabel,
                  ),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            l10n.companyExpenseCategoryName(
                              code: category.code,
                              fallbackName: category.name,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _selectedCategoryId = value),
                  validator: (value) => value == null
                      ? l10n.companyExpenseCategoryRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _OptionalLinkDropdown(
                  label: l10n.driverNameLabel,
                  noneLabel: l10n.fleetNotAvailable,
                  options: widget.formLookups.drivers,
                  selectedId: _selectedDriverId,
                  isSaving: _isSaving,
                  onChanged: (value) =>
                      setState(() => _selectedDriverId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _OptionalLinkDropdown(
                  label: l10n.tractorHeadsTab,
                  noneLabel: l10n.fleetNotAvailable,
                  options: widget.formLookups.tractorHeads,
                  selectedId: _selectedTractorHeadId,
                  isSaving: _isSaving,
                  onChanged: (value) =>
                      setState(() => _selectedTractorHeadId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _OptionalLinkDropdown(
                  label: l10n.trailersTab,
                  noneLabel: l10n.fleetNotAvailable,
                  options: widget.formLookups.trailers,
                  selectedId: _selectedTrailerId,
                  isSaving: _isSaving,
                  onChanged: (value) =>
                      setState(() => _selectedTrailerId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _OptionalLinkDropdown(
                  label: l10n.driverMovementTripLine,
                  noneLabel: l10n.fleetNotAvailable,
                  options: widget.formLookups.trips,
                  selectedId: _selectedTripId,
                  isSaving: _isSaving,
                  onChanged: (value) => setState(() => _selectedTripId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: l10n.companyExpenseAmountLabel,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    final amount = double.tryParse((value ?? '').trim());
                    if (amount == null || amount <= 0) {
                      return l10n.companyExpenseAmountInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: _isSaving ? null : _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.companyExpenseDateLabel,
                    ),
                    child: Text(formatCompanyExpenseDate(_expenseDate)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    labelText: l10n.companyExpenseReferenceLabel,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n.companyExpenseNotesLabel,
                  ),
                  maxLines: CompanyExpensePresentationConstants.notesMaxLines,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}

class _OptionalLinkDropdown extends StatelessWidget {
  final String label;
  final String noneLabel;
  final List<CompanyExpenseLinkOption> options;
  final String? selectedId;
  final bool isSaving;
  final ValueChanged<String?> onChanged;

  const _OptionalLinkDropdown({
    required this.label,
    required this.noneLabel,
    required this.options,
    required this.selectedId,
    required this.isSaving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: _hasSelectedOption ? selectedId : null,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(noneLabel)),
        ...options.map(
          (option) => DropdownMenuItem<String?>(
            value: option.id,
            child: Text(option.label),
          ),
        ),
      ],
      onChanged: isSaving ? null : onChanged,
    );
  }

  bool get _hasSelectedOption {
    if (selectedId == null) return false;
    return options.any((option) => option.id == selectedId);
  }
}
