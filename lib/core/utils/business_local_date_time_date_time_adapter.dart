import '../domain/value_objects/business_local_date_time.dart';

abstract final class BusinessLocalDateTimeDateTimeAdapter {
  /// Formatting-only component carrier.
  ///
  /// The returned value is not an instant and must never be persisted or used
  /// for timezone conversion. UTC construction prevents device timezone rules
  /// from changing the business-local wall-clock components.
  static DateTime toDateTime(BusinessLocalDateTime value) {
    return DateTime.utc(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }
}
