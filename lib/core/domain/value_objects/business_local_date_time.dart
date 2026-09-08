import 'business_date.dart';

final class BusinessLocalDateTime implements Comparable<BusinessLocalDateTime> {
  final BusinessDate date;
  final int hour;
  final int minute;

  const BusinessLocalDateTime._({
    required this.date,
    required this.hour,
    required this.minute,
  });

  factory BusinessLocalDateTime({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) {
    final value = tryCreate(
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
    );
    if (value == null) {
      throw ArgumentError('Invalid business-local date and time.');
    }
    return value;
  }

  static BusinessLocalDateTime? tryCreate({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) {
    final date = BusinessDate.tryCreate(year: year, month: month, day: day);
    if (date == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return BusinessLocalDateTime._(date: date, hour: hour, minute: minute);
  }

  int get year => date.year;
  int get month => date.month;
  int get day => date.day;

  bool isBefore(BusinessLocalDateTime other) => compareTo(other) < 0;

  bool isAfter(BusinessLocalDateTime other) => compareTo(other) > 0;

  @override
  int compareTo(BusinessLocalDateTime other) {
    final dateComparison = date.compareTo(other.date);
    if (dateComparison != 0) return dateComparison;

    final hourComparison = hour.compareTo(other.hour);
    if (hourComparison != 0) return hourComparison;

    return minute.compareTo(other.minute);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BusinessLocalDateTime &&
            other.date == date &&
            other.hour == hour &&
            other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(date, hour, minute);

  @override
  String toString() {
    return 'BusinessLocalDateTime($year, $month, $day, $hour, $minute)';
  }
}
