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

  static DateTime requiredDate(Object? value, String field) {
    final parsed = optionalDate(value, field);
    if (parsed == null) throw FormatException('Invalid invoice field: $field.');
    return parsed;
  }

  static DateTime? optionalDate(Object? value, String field) {
    if (value == null) return null;
    final raw = value.toString();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      throw FormatException('Invalid invoice field: $field.');
    }
    final parts = raw.split('-').map(int.parse).toList(growable: false);
    final parsed = DateTime.utc(parts[0], parts[1], parts[2]);
    if (parsed.year != parts[0] ||
        parsed.month != parts[1] ||
        parsed.day != parts[2]) {
      throw FormatException('Invalid invoice field: $field.');
    }
    return parsed;
  }

  static DateTime requiredDateTime(Object? value, String field) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed == null) throw FormatException('Invalid invoice field: $field.');
    return parsed.toUtc();
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
