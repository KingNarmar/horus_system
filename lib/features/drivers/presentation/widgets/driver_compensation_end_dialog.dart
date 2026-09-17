import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/driver_compensation_revision.dart';
import '../helpers/driver_compensation_formatters.dart';
import '../localization/driver_compensation_localizations.dart';

typedef DriverCompensationEndSubmit =
    Future<Failure?> Function(BusinessDate effectiveTo);

final class DriverCompensationEndDialog extends StatefulWidget {
  final DriverCompensationRevision revision;
  final BusinessDate initialEffectiveTo;
  final DriverCompensationEndSubmit onSubmit;

  const DriverCompensationEndDialog({
    required this.revision,
    required this.initialEffectiveTo,
    required this.onSubmit,
    super.key,
  });

  @override
  State<DriverCompensationEndDialog> createState() =>
      _DriverCompensationEndDialogState();
}

final class _DriverCompensationEndDialogState
    extends State<DriverCompensationEndDialog> {
  late BusinessDate _effectiveTo;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _effectiveTo = widget.initialEffectiveTo;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.driverCompensationL10n;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.formDialogMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.endRevisionTitle,
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
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickDate,
                icon: const Icon(AppIcons.calendar),
                label: Text(
                  '${l10n.effectiveToLabel}: '
                  '${DriverCompensationFormatters.date(_effectiveTo)}',
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDateTime(_effectiveTo),
      firstDate: _toDateTime(widget.revision.effectiveFrom),
      lastDate: DateTime(9999, 12, 31),
    );
    if (picked != null && mounted) {
      setState(
        () => _effectiveTo = BusinessDate(
          year: picked.year,
          month: picked.month,
          day: picked.day,
        ),
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final failure = await widget.onSubmit(_effectiveTo);
    if (!mounted) return;
    if (failure != null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(driverCompensationFailureMessage(context, failure)),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  DateTime _toDateTime(BusinessDate value) {
    return DateTime(value.year, value.month, value.day);
  }
}
