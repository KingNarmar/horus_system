import '../../../../core/data/utils/db_date.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../../../core/domain/value_objects/business_date.dart';

abstract final class InvoiceDataParser {
  static String requiredString(Object? value, String field) {
    final parsed = optionalString(value);
    if (parsed == null) throw FormatException('Invalid invoice field: $field.');
    return parsed;
  }

  static String? optionalString(Object? value) {
    if (value == null) return null;
    final parsed = value.toString().trim();
    return parsed.isEmpty ? null : parsed;
  }

  static int requiredInt(Object? value, String field) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) throw FormatException('Invalid invoice field: $field.');
    return parsed;
  }

  static double? optionalDouble(Object? value, String field) {
    if (value == null) return null;
    if (value is num && value.isFinite) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    if (parsed == null || !parsed.isFinite) {
      throw FormatException('Invalid invoice field: $field.');
    }
    return parsed;
  }

  static BusinessDate requiredDate(Object? value, String field) {
    final parsed = optionalDate(value, field);
    if (parsed == null) throw FormatException('Invalid invoice field: $field.');
    return parsed;
  }

  static BusinessDate? optionalDate(Object? value, String field) {
    return DbDate.decodeNullable(value, field: field);
  }

  static DateTime requiredDateTime(Object? value, String field) {
    return DbTimestamp.decode(value, field: field);
  }

  static List<Map<String, dynamic>> mapList(Object? value, String field) {
    if (value is! List) throw FormatException('Invalid invoice field: $field.');
    return value
        .map((item) {
          if (item is! Map) {
            throw FormatException('Invalid invoice field: $field.');
          }
          return Map<String, dynamic>.from(item);
        })
        .toList(growable: false);
  }
}
