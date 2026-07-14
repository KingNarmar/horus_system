import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver_finance_trip_option.dart';
import '../../domain/entities/driver_financial_movement_type.dart';


typedef DriverFinancialMovementSubmit =
    Future<void> Function({
      required double amount,
      required DateTime movementDate,
      String? tripId,
      String? notes,
    });

class DriverFinancialMovementFormDialog extends StatefulWidget {
  final DriverFinancialMovementType movementType;
  final List<DriverFinanceTripOption> tripOptions;
  final bool isTripOptionsLoading;
  final Object? tripOptionsFailure;
  final DriverFinancialMovementSubmit onSubmit;

  const DriverFinancialMovementFormDialog({
    required this.movementType,
    required this.tripOptions,
    required this.isTripOptionsLoading,
    required this.tripOptionsFailure,
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
  final _notesController = TextEditingController();
  String _selectedTripId = '';
  DateTime _movementDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (widget.movementType) {
      DriverFinancialMovementType.advance => l10n.addDriverAdvanceTitle,
      DriverFinancialMovementType.driverCharge => l10n.addDriverDeductionTitle,
      DriverFinancialMovementType.cashReturn => l10n.driverMovementTypeCashReturn,
    };

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.formDialogMaxWidth,
        ),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
              if (widget.movementType.canLinkTrip) ...[
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTripId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.driverMovementRelatedTripLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(l10n.driverMovementGeneralDeductionOption),
                    ),
                    ...widget.tripOptions.map(
                      (option) => DropdownMenuItem(
                        value: option.id,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) =>
                            setState(() => _selectedTripId = value ?? ''),
                ),
                if (widget.isTripOptionsLoading) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.loadingDriverTripOptions),
                ] else if (widget.tripOptions.isEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.noDriverTripsForDeduction),
                ],
              ],
              const SizedBox(height: AppSpacing.md),
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
                      _isSubmitting
                          ? l10n.savingDriverFinancialMovement
                          : l10n.saveButton,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidDriverMovementAmount)));
      return;
    }

    setState(() => _isSubmitting = true);
    await widget.onSubmit(
      amount: amount,
      movementDate: _movementDate,
      tripId: widget.movementType.canLinkTrip
          ? _optional(_selectedTripId)
          : null,
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
