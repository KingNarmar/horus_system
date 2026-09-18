import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/localization/app_localizations_extension.dart';

class TripBusinessDateTimeField extends StatelessWidget {
  final String label;
  final BusinessLocalDateTime? value;
  final ValueChanged<BusinessLocalDateTime?> onChanged;
  final bool enabled;

  const TripBusinessDateTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;

    final currentValue = value;
    final now = DateTime.now();
    final initialDate = currentValue == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime(currentValue.year, currentValue.month, currentValue.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(BusinessDate.minYear),
      lastDate: DateTime(BusinessDate.maxYear, 12, 31),
    );
    if (!context.mounted || selectedDate == null) return;

    final initialTime = currentValue == null
        ? TimeOfDay.fromDateTime(now)
        : TimeOfDay(hour: currentValue.hour, minute: currentValue.minute);

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (!context.mounted || selectedTime == null) return;

    final nextValue = BusinessLocalDateTime.tryCreate(
      year: selectedDate.year,
      month: selectedDate.month,
      day: selectedDate.day,
      hour: selectedTime.hour,
      minute: selectedTime.minute,
    );
    if (nextValue != null) {
      onChanged(nextValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final materialL10n = MaterialLocalizations.of(context);
    final currentValue = value;

    final displayText = currentValue == null
        ? l10n.tripOptionalNone
        : _formatValue(
            context: context,
            value: currentValue,
            materialL10n: materialL10n,
          );

    return Semantics(
      button: enabled,
      label: label,
      value: displayText,
      child: InkWell(
        onTap: enabled ? () => _pick(context) : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            enabled: enabled,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(AppIcons.calendar),
            suffixIcon: currentValue == null
                ? null
                : IconButton(
                    onPressed: enabled ? () => onChanged(null) : null,
                    icon: const Icon(AppIcons.clear),
                  ),
          ),
          child: Text(displayText),
        ),
      ),
    );
  }

  String _formatValue({
    required BuildContext context,
    required BusinessLocalDateTime value,
    required MaterialLocalizations materialL10n,
  }) {
    final date = DateTime(value.year, value.month, value.day);
    final time = TimeOfDay(hour: value.hour, minute: value.minute);
    final use24HourFormat = MediaQuery.alwaysUse24HourFormatOf(context);

    return '${materialL10n.formatCompactDate(date)} '
        '${materialL10n.formatTimeOfDay(time, alwaysUse24HourFormat: use24HourFormat)}';
  }
}
