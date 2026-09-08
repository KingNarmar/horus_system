import '../../domain/value_objects/business_date.dart';

abstract final class DbDate {
  static final RegExp _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static String encode(BusinessDate value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static BusinessDate decode(Object? value) {
    final raw = value?.toString();
    if (raw == null || !_datePattern.hasMatch(raw)) {
      throw const FormatException('Invalid database date.');
    }

    final parts = raw.split('-');
    final parsed = BusinessDate.tryCreate(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      day: int.parse(parts[2]),
    );
    if (parsed == null) {
      throw const FormatException('Invalid database date.');
    }
    return parsed;
  }

  static BusinessDate? decodeNullable(Object? value) {
    if (value == null) return null;
    return decode(value);
  }
}
