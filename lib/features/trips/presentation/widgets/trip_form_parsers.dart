part of 'trip_form_dialog.dart';

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

  return _parseDateTime(text) != null;
}

DateTime? _parseDateTime(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;

  return DateTime.tryParse(text);
}

String _formatDouble(double? value) {
  if (value == null) return '';

  final text = value.toString();
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

String _formatDateTimeForInput(DateTime? value) {
  if (value == null) return '';

  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$year-$month-$day $hour:$minute';
}
