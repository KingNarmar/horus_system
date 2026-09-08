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

  BusinessDate get startOfMonth =>
      BusinessDate._(year: year, month: month, day: 1);

  BusinessDate get endOfMonth => BusinessDate._(
    year: year,
    month: month,
    day: _daysInMonth(year: year, month: month),
  );

  BusinessDate get nextDay {
    final lastDay = _daysInMonth(year: year, month: month);
    if (day < lastDay) {
      return BusinessDate._(year: year, month: month, day: day + 1);
    }
    if (month < 12) {
      return BusinessDate._(year: year, month: month + 1, day: 1);
    }
    if (year == 9999) {
      throw StateError('Business date cannot advance beyond year 9999.');
    }
    return BusinessDate._(year: year + 1, month: 1, day: 1);
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
    return day <= _daysInMonth(year: year, month: month);
  }

  static int _daysInMonth({required int year, required int month}) {
    return switch (month) {
      2 => _isLeapYear(year) ? 29 : 28,
      4 || 6 || 9 || 11 => 30,
      _ => 31,
    };
  }

  static bool _isLeapYear(int year) {
    return year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
  }
}
