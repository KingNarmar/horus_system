final class ReportDateRange {
  final DateTime? fromDate;
  final DateTime? toDate;

  const ReportDateRange({this.fromDate, this.toDate});

  static DateTime? dateOnly(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }

  ReportDateRange normalized() {
    return ReportDateRange(
      fromDate: dateOnly(fromDate),
      toDate: dateOnly(toDate),
    );
  }

  bool get isInvalid =>
      fromDate != null && toDate != null && fromDate!.isAfter(toDate!);
}
