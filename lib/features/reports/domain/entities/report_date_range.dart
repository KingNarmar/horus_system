import '../../../../core/domain/value_objects/business_date.dart';

final class ReportDateRange {
  final BusinessDate? fromDate;
  final BusinessDate? toDate;

  const ReportDateRange({this.fromDate, this.toDate});

  ReportDateRange normalized() => this;

  bool get isInvalid =>
      fromDate != null && toDate != null && fromDate!.isAfter(toDate!);
}
