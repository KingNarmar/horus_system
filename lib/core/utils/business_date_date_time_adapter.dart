import '../domain/value_objects/business_date.dart';

abstract final class BusinessDateDateTimeAdapter {
  static BusinessDate fromDateTime(DateTime value) {
    return BusinessDate(year: value.year, month: value.month, day: value.day);
  }

  static DateTime toDateTime(BusinessDate value) {
    return DateTime(value.year, value.month, value.day);
  }
}
