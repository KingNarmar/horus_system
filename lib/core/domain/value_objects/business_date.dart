final class BusinessDate implements Comparable<BusinessDate> {
  final int year;
  final int month;
  final int day;

  const BusinessDate._({
    required this.year,
    required this.month,
    required this.day,
  });

  factory BusinessDate({
    required int year,
    required int month,
    required int day,
  }) {
    final value = tryCreate(year: year, month: month, day: day);
    if (value == null) {
      throw ArgumentError('Invalid business date.');
    }
    return value;
  }

  static BusinessDate? tryCreate({
    required int year,
    required int month,
    required int day,
  }) {
    if (!_isValidDate(year: year, month: month, day: day)) {
      return null;
    }
    return BusinessDate._(year: year, month: month, day: day);
  }

  bool isBefore(BusinessDate other) => compareTo(other) < 0;

  bool isAfter(BusinessDate other) => compareTo(other) > 0;

  @override
  int compareTo(BusinessDate other) {
    final yearComparison = year.compareTo(other.year);
    if (yearComparison != 0) return yearComparison;

    final monthComparison = month.compareTo(other.month);
    if (monthComparison != 0) return monthComparison;

    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BusinessDate &&
            other.year == year &&
            other.month == month &&
            other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'BusinessDate($year, $month, $day)';

  static bool _isValidDate({
    required int year,
    required int month,
    required int day,
  }) {
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
      return false;
    }

    final daysInMonth = switch (month) {
      2 => _isLeapYear(year) ? 29 : 28,
      4 || 6 || 9 || 11 => 30,
      _ => 31,
    };
    return day <= daysInMonth;
  }

  static bool _isLeapYear(int year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
  }
}
