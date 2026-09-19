import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';

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

int? optionalInt(Object? value, String field) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num && value == value.truncate()) return value.toInt();
  throw FormatException('Invalid reports integer: $field.');
}

double? optionalDouble(Object? value, String field) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw FormatException('Invalid reports number: $field.');
}

BusinessDate requiredDate(Object? value, String field) {
  return DbDate.decode(value, field: field);
}

BusinessDate? optionalDate(Object? value, String field) {
  return DbDate.decodeNullable(value, field: field);
}

DateTime? optionalDateTime(Object? value, String field) {
  return DbTimestamp.decodeNullable(value, field: field);
}

DateTime requiredDateTime(Object? value, String field) {
  return DbTimestamp.decode(value, field: field);
}
