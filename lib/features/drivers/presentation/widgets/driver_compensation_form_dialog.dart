import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/services/money_input_parser.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/failure.dart';
import '../helpers/driver_compensation_formatters.dart';
import '../helpers/driver_contract_file_picker.dart';
import '../localization/driver_compensation_localizations.dart';

typedef DriverCompensationFormSubmit =
    Future<Failure?> Function({
      required Money amount,
      required BusinessDate effectiveFrom,
      BusinessDate? effectiveTo,
      String? contractReference,
      BusinessDocumentFile? contractDocument,
    });

final class DriverCompensationFormDialog extends StatefulWidget {
  final CurrencyConfiguration financialConfiguration;
  final BusinessDate initialEffectiveFrom;
  final DriverCompensationFormSubmit onSubmit;

  const DriverCompensationFormDialog({
    required this.financialConfiguration,
    required this.initialEffectiveFrom,
    required this.onSubmit,
    super.key,
  });

  @override
  State<DriverCompensationFormDialog> createState() =>
      _DriverCompensationFormDialogState();
}

final class _DriverCompensationFormDialogState
    extends State<DriverCompensationFormDialog> {
  static const MoneyInputParser _moneyInputParser = MoneyInputParser();
  static const DriverContractFilePicker _filePicker =
      DriverContractFilePicker();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _contractReferenceController =
      TextEditingController();

  late BusinessDate _effectiveFrom;
  BusinessDate? _effectiveTo;
  BusinessDocumentFile? _contractDocument;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _effectiveFrom = widget.initialEffectiveFrom;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _contractReferenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.driverCompensationL10n;

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
                      l10n.addRevisionTitle,
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
                enabled: !_isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      '${l10n.amountLabel} (${widget.financialConfiguration.currency.value})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickEffectiveFrom,
                icon: const Icon(AppIcons.calendar),
                label: Text(
                  '${l10n.effectiveFromLabel}: '
                  '${DriverCompensationFormatters.date(_effectiveFrom)}',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickEffectiveTo,
                      icon: const Icon(AppIcons.calendar),
                      label: Text(
                        '${l10n.effectiveToLabel}: '
                        '${_effectiveTo == null ? l10n.ongoingLabel : DriverCompensationFormatters.date(_effectiveTo!)}',
                      ),
                    ),
                  ),
                  if (_effectiveTo != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _effectiveTo = null),
                      icon: const Icon(AppIcons.clear),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _contractReferenceController,
                enabled: !_isSubmitting,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: l10n.contractReferenceLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickContractDocument,
                icon: const Icon(AppIcons.uploadFile),
                label: Text(l10n.chooseContractDocument),
              ),
              if (_contractDocument != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${l10n.selectedFileLabel}: ${_contractDocument!.fileName}',
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting ? l10n.saving : l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickEffectiveFrom() async {
    final picked = await _pickDate(_effectiveFrom);
    if (picked != null && mounted) {
      setState(() => _effectiveFrom = picked);
    }
  }

  Future<void> _pickEffectiveTo() async {
    final picked = await _pickDate(_effectiveTo ?? _effectiveFrom);
    if (picked != null && mounted) {
      setState(() => _effectiveTo = picked);
    }
  }

  Future<BusinessDate?> _pickDate(BusinessDate initialValue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDateTime(initialValue),
      firstDate: DateTime(1, 1, 1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (picked == null) return null;
    return BusinessDate(year: picked.year, month: picked.month, day: picked.day);
  }

  Future<void> _pickContractDocument() async {
    final l10n = context.driverCompensationL10n;
    try {
      final document = await _filePicker.pick();
      if (document != null && mounted) {
        setState(() => _contractDocument = document);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.filePickerFailed)),
      );
    }
  }

  Future<void> _submit() async {
    final l10n = context.driverCompensationL10n;
    final minorUnits = _moneyInputParser.tryParseMinorUnits(
      _amountController.text,
      fractionDigits: widget.financialConfiguration.fractionDigits,
    );
    if (minorUnits == null || minorUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.amountPositive)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final failure = await widget.onSubmit(
      amount: Money(
        minorUnits: minorUnits,
        currency: widget.financialConfiguration.currency,
      ),
      effectiveFrom: _effectiveFrom,
      effectiveTo: _effectiveTo,
      contractReference: _optional(_contractReferenceController.text),
      contractDocument: _contractDocument,
    );

    if (!mounted) return;
    if (failure != null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(driverCompensationFailureMessage(context, failure))),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  DateTime _toDateTime(BusinessDate value) {
    return DateTime(value.year, value.month, value.day);
  }

  String? _optional(String rawValue) {
    final value = rawValue.trim();
    return value.isEmpty ? null : value;
  }
}
