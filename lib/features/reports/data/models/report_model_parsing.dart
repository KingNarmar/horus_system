Map<String, dynamic> requiredMap(Object? value, String field) {
  if (value is! Map) throw FormatException('Invalid reports object: $field.');
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> requiredMapList(Object? value, String field) {
  if (value is! List) throw FormatException('Invalid reports list: $field.');
  return value.map((item) => requiredMap(item, field)).toList(growable: false);
}

String requiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid reports string: $field.');
  }
  return value.trim();
}

String? optionalString(Object? value, String field) {
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Invalid reports string: $field.');
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int requiredInt(Object? value, String field) {
  if (value is int) return value;
  if (value is num && value == value.truncate()) return value.toInt();
  throw FormatException('Invalid reports integer: $field.');
}

double? optionalDouble(Object? value, String field) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw FormatException('Invalid reports number: $field.');
}

DateTime requiredDate(Object? value, String field) {
  final parsed = _parseDate(value, field);
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? optionalDate(Object? value, String field) {
  if (value == null) return null;
  final parsed = _parseDate(value, field);
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? optionalDateTime(Object? value, String field) {
  if (value == null) return null;
  return _parseDate(value, field);
}

DateTime requiredDateTime(Object? value, String field) {
  return _parseDate(value, field);
}

DateTime _parseDate(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid reports date: $field.');
  }
  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) throw FormatException('Invalid reports date: $field.');
  return parsed;
}
