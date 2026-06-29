import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver_financial_movement_type.dart';
import '../localization/driver_finance_localizations_x.dart';

typedef DriverFinancialMovementSubmit = Future<void> Function({
  required double amount,
  required DateTime movementDate,
  String? tripId,
  String? notes,
});

class DriverFinancialMovementFormDialog extends StatefulWidget {
  final DriverFinancialMovementType movementType;
  final DriverFinancialMovementSubmit onSubmit;

  const DriverFinancialMovementFormDialog({
    required this.movementType,
    required this.onSubmit,
    super.key,
  });

  @override
  State<DriverFinancialMovementFormDialog> createState() =>
      _DriverFinancialMovementFormDialogState();
}

class _DriverFinancialMovementFormDialogState
    extends State<DriverFinancialMovementFormDialog> {
  final _amountController = TextEditingController();
  final _tripIdController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _movementDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _tripIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.movementType.isAdvance
        ? l10n.addDriverAdvanceTitle
        : l10n.addDriverDeductionTitle;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formDialogMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.clear),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.driverMovementAmountLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.movementType.isDeduction) ...[
                TextField(
                  controller: _tripIdController,
                  decoration: InputDecoration(
                    labelText: l10n.driverMovementTripIdLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickDate,
                icon: const Icon(AppIcons.calendar),
                label: Text(
                  '${l10n.driverMovementDateLabel}: ${_dateOnly(_movementDate)}',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.driverMovementNotesLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancelButton),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(
                      _isSubmitting ? l10n.savingDriverFinancialMovement : l10n.saveButton,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _movementDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _movementDate = picked);
    }
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidDriverMovementAmount)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await widget.onSubmit(
      amount: amount,
      movementDate: _movementDate,
      tripId: _optional(_tripIdController.text),
      notes: _optional(_notesController.text),
    );
    if (mounted) Navigator.of(context).pop();
  }
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _dateOnly(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
