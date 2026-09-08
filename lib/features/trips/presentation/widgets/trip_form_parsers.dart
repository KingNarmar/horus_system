part of 'trip_form_dialog.dart';

final RegExp _businessLocalDateTimePattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})$',
);

String? _validSelectedValue(String? value, List<TripLookupOption> options) {
  if (value == null || value.trim().isEmpty) return null;

  final exists = options.any((option) => option.id == value);
  return exists ? value : null;
}

String? _optionalSelected(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

String? _optional(String value) {
  final text = value.trim();
  return text.isEmpty ? null : text;
}

bool _nonNegativeNumberValid(String value) {
  final text = value.trim();
  if (text.isEmpty) return true;

  final number = _parseDouble(text);
  return number != null && number >= 0;
}

double? _parseDouble(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;

  return double.tryParse(text.replaceAll(',', '.'));
}

bool _dateTimeValid(String value) {
  final text = value.trim();
  if (text.isEmpty) return true;

  return _parseBusinessLocalDateTime(text) != null;
}

BusinessLocalDateTime? _parseBusinessLocalDateTime(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  final match = _businessLocalDateTimePattern.firstMatch(text);
  if (match == null) return null;

  return BusinessLocalDateTime.tryCreate(
    year: int.parse(match.group(1)!),
    month: int.parse(match.group(2)!),
    day: int.parse(match.group(3)!),
    hour: int.parse(match.group(4)!),
    minute: int.parse(match.group(5)!),
  );
}

String _formatDouble(double? value) {
  if (value == null) return '';

  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

String _formatBusinessLocalDateTimeForInput(BusinessLocalDateTime? value) {
  if (value == null) return '';

  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$year-$month-$day $hour:$minute';
}
