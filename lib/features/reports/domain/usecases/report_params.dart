import '../../../company/domain/entities/current_company_context.dart';
import '../entities/operational_trip_report.dart';
import '../entities/report_date_range.dart';

final class OperationalReportParams {
  final CurrentCompanyContext currentCompanyContext;
  final OperationalReportDimension dimension;
  final ReportDateRange dateRange;

  const OperationalReportParams({
    required this.currentCompanyContext,
    required this.dimension,
    required this.dateRange,
  });
}

final class ReportParams {
  final CurrentCompanyContext currentCompanyContext;
  final ReportDateRange dateRange;

  const ReportParams({
    required this.currentCompanyContext,
    required this.dateRange,
  });
}
