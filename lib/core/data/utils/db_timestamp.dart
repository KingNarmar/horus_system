abstract final class DbTimestamp {
  static final RegExp _offsetPattern = RegExp(
    r'(?:[zZ]|[+-]\d{2}(?::?\d{2})?)$',
  );

  static DateTime decode(Object? value, {String? field}) {
    if (value is DateTime) {
      if (!value.isUtc) throw _invalidTimestamp(field);
      return value;
    }

    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty || !_offsetPattern.hasMatch(raw)) {
      throw _invalidTimestamp(field);
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null || !parsed.isUtc) {
      throw _invalidTimestamp(field);
    }
    return parsed.toUtc();
  }

  static DateTime? decodeNullable(Object? value, {String? field}) {
    if (value == null) return null;
    return decode(value, field: field);
  }

  static String encode(DateTime value) {
    return value.toUtc().toIso8601String();
  }

  static String? encodeNullable(DateTime? value) {
    return value == null ? null : encode(value);
  }

  static String nowUtcIsoString() => encode(DateTime.now());

  static FormatException _invalidTimestamp(String? field) {
    if (field == null || field.trim().isEmpty) {
      return const FormatException('Invalid database timestamp.');
    }
    return FormatException('Invalid database timestamp: $field.');
  }
}
