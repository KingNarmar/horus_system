import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/localization/app_localizations_extension.dart';
import '../../domain/entities/driver_settlement_driver_option.dart';
import '../constants/driver_settlement_presentation_constants.dart';
import '../cubit/driver_settlement_form_input.dart';
import '../cubit/driver_settlements_cubit.dart';
import '../cubit/driver_settlements_state.dart';
import '../helpers/driver_settlement_formatters.dart';
import '../localization/driver_settlement_localizations_x.dart';
import '../localization/driver_settlements_localizations.dart';
import 'driver_settlement_preview_section.dart';

class DriverSettlementFormDialog extends StatefulWidget {
  final List<DriverSettlementDriverOption> driverOptions;

  const DriverSettlementFormDialog({required this.driverOptions, super.key});

  @override
  State<DriverSettlementFormDialog> createState() =>
      _DriverSettlementFormDialogState();
}

class _DriverSettlementFormDialogState
    extends State<DriverSettlementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _grossSalaryController = TextEditingController();
  final _salaryDeductionsController = TextEditingController();
  final _balanceDeductionController = TextEditingController();
  final _settlementDeductionsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedDriverId;
  late DateTime _periodStart;
  late DateTime _periodEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periodStart = DateTime(now.year, now.month);
    _periodEnd = DateTime(now.year, now.month + 1, 0);
    context.read<DriverSettlementsCubit>().invalidatePreview();
  }

  @override
  void dispose() {
    _grossSalaryController.dispose();
    _salaryDeductionsController.dispose();
    _balanceDeductionController.dispose();
    _settlementDeductionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _invalidatePreview() {
    context.read<DriverSettlementsCubit>().invalidatePreview();
  }

  Future<void> _pickPeriodStart() async {
    final picked = await _pickDate(_periodStart);
    if (picked == null) return;
    setState(() => _periodStart = picked);
    _invalidatePreview();
  }

  Future<void> _pickPeriodEnd() async {
    final picked = await _pickDate(_periodEnd);
    if (picked == null) return;
    setState(() => _periodEnd = picked);
    _invalidatePreview();
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(
        DriverSettlementPresentationConstants.datePickerFirstYear,
      ),
      lastDate: DateTime(
        now.year + DriverSettlementPresentationConstants.datePickerFutureYears,
        12,
        31,
      ),
    );
  }

  double _amount(TextEditingController controller) {
    final value = controller.text.trim();
    if (value.isEmpty) return 0;
    return double.tryParse(value) ?? -1;
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String? _validateAmount(String? value) {
    final strings = context.driverSettlementsL10n;
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) return null;
    final amount = double.tryParse(normalized);
    if (amount == null || amount < 0) return strings.nonNegativeAmount;
    return null;
  }

  bool _validate() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return false;
    if (_selectedDriverId == null) return false;
    if (_periodStart.isAfter(_periodEnd)) {
      setState(() {});
      return false;
    }
    return true;
  }

  DriverSettlementFormInput _input() {
    return DriverSettlementFormInput(
      driverId: _selectedDriverId!,
      periodStart: _periodStart,
      periodEnd: _periodEnd,
      grossSalary: _amount(_grossSalaryController),
      salaryDeductionsTotal: _amount(_salaryDeductionsController),
      balanceDeductionApplied: _amount(_balanceDeductionController),
      settlementDeductionsTotal: _amount(_settlementDeductionsController),
      notes: _optional(_notesController.text),
    );
  }

  Future<void> _calculatePreview() async {
    if (!_validate()) return;
    await context.read<DriverSettlementsCubit>().calculatePreview(_input());
  }

  Future<void> _saveDraft() async {
    if (!_validate()) return;
    final created = await context.read<DriverSettlementsCubit>().createDraft(
      _input(),
    );
    if (created && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.driverSettlementsL10n;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return BlocBuilder<DriverSettlementsCubit, DriverSettlementsState>(
      builder: (context, state) {
        final loaded = state is DriverSettlementsLoaded ? state : null;
        final isBusy =
            loaded?.isCreatingDraft == true || loaded?.isPreviewLoading == true;

        return AlertDialog(
          title: Text(strings.newDraftTitle),
          content: SizedBox(
            width: AppSizes.detailsDialogMaxWidth,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDriverId,
                      decoration: InputDecoration(
                        labelText: strings.driverLabel,
                      ),
                      items: widget.driverOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option.id,
                              child: Text(option.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: isBusy
                          ? null
                          : (value) {
                              setState(() => _selectedDriverId = value);
                              _invalidatePreview();
                            },
                      validator: (value) =>
                          value == null ? strings.driverRequired : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: strings.periodStart,
                            value: formatDriverSettlementDate(
                              _periodStart,
                              localeName,
                            ),
                            onTap: isBusy ? null : _pickPeriodStart,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _DateField(
                            label: strings.periodEnd,
                            value: formatDriverSettlementDate(
                              _periodEnd,
                              localeName,
                            ),
                            onTap: isBusy ? null : _pickPeriodEnd,
                          ),
                        ),
                      ],
                    ),
                    if (_periodStart.isAfter(_periodEnd)) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        strings.periodInvalid,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _AmountField(
                      controller: _grossSalaryController,
                      label: strings.grossSalary,
                      enabled: !isBusy,
                      validator: _validateAmount,
                      onChanged: _invalidatePreview,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AmountField(
                      controller: _salaryDeductionsController,
                      label: strings.salaryDeductions,
                      enabled: !isBusy,
                      validator: _validateAmount,
                      onChanged: _invalidatePreview,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AmountField(
                      controller: _balanceDeductionController,
                      label: strings.balanceDeduction,
                      enabled: !isBusy,
                      validator: _validateAmount,
                      onChanged: _invalidatePreview,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AmountField(
                      controller: _settlementDeductionsController,
                      label: strings.settlementDeductions,
                      enabled: !isBusy,
                      validator: _validateAmount,
                      onChanged: _invalidatePreview,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _notesController,
                      enabled: !isBusy,
                      decoration: InputDecoration(labelText: strings.notes),
                      maxLines:
                          DriverSettlementPresentationConstants.notesMaxLines,
                      onChanged: (_) => _invalidatePreview(),
                    ),
                    if (loaded?.previewFailure != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.localizedDriverSettlementFailure(
                          loaded!.previewFailure!,
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (loaded?.mutationFailure != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.localizedDriverSettlementFailure(
                          loaded!.mutationFailure!,
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (loaded?.preview != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      DriverSettlementPreviewSection(preview: loaded!.preview!),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isBusy ? null : () => Navigator.of(context).pop(),
              child: Text(context.l10n.cancelButton),
            ),
            OutlinedButton(
              onPressed: isBusy ? null : _calculatePreview,
              child: Text(
                loaded?.isPreviewLoading == true
                    ? strings.calculatingPreview
                    : strings.calculatePreview,
              ),
            ),
            FilledButton(
              onPressed: loaded?.preview == null || isBusy ? null : _saveDraft,
              child: Text(
                loaded?.isCreatingDraft == true
                    ? strings.savingDraft
                    : strings.saveDraft,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final FormFieldValidator<String> validator;
  final VoidCallback onChanged;

  const _AmountField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.validator,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      onChanged: (_) => onChanged(),
    );
  }
}
