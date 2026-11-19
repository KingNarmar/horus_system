import '../../domain/entities/operational_trip_report.dart';
import '../../domain/entities/report_export_kind.dart';
import '../../domain/policies/reports_permission_policy.dart';
import '../../../company/domain/entities/company_role.dart';

enum ReportType {
  dailyTrips,
  tripsByCustomer,
  tripsByRoute,
  tripsByDriver,
  tripsByTractorHead,
  tripsByTrailer,
  tripExpenses,
  tripNetProfit,
  openInvoices,
}

extension ReportTypeX on ReportType {
  ReportExportKind get exportKind => switch (this) {
    ReportType.dailyTrips => ReportExportKind.dailyTrips,
    ReportType.tripsByCustomer => ReportExportKind.tripsByCustomer,
    ReportType.tripsByRoute => ReportExportKind.tripsByRoute,
    ReportType.tripsByDriver => ReportExportKind.tripsByDriver,
    ReportType.tripsByTractorHead => ReportExportKind.tripsByTractorHead,
    ReportType.tripsByTrailer => ReportExportKind.tripsByTrailer,
    ReportType.tripExpenses => ReportExportKind.tripExpenses,
    ReportType.tripNetProfit => ReportExportKind.tripNetProfit,
    ReportType.openInvoices => ReportExportKind.openInvoices,
  };

  bool canView(CompanyRole role) {
    return switch (this) {
      ReportType.dailyTrips ||
      ReportType.tripsByCustomer ||
      ReportType.tripsByRoute ||
      ReportType.tripsByDriver ||
      ReportType.tripsByTractorHead ||
      ReportType.tripsByTrailer =>
        ReportsPermissionPolicy.canViewOperationalReports(role),
      ReportType.tripExpenses || ReportType.tripNetProfit =>
        ReportsPermissionPolicy.canViewFinancialReports(role),
      ReportType.openInvoices =>
        ReportsPermissionPolicy.canViewOpenInvoicesReport(role),
    };
  }

  OperationalReportDimension? get operationalDimension {
    return switch (this) {
      ReportType.dailyTrips => OperationalReportDimension.day,
      ReportType.tripsByCustomer => OperationalReportDimension.customer,
      ReportType.tripsByRoute => OperationalReportDimension.route,
      ReportType.tripsByDriver => OperationalReportDimension.driver,
      ReportType.tripsByTractorHead => OperationalReportDimension.tractorHead,
      ReportType.tripsByTrailer => OperationalReportDimension.trailer,
      ReportType.tripExpenses ||
      ReportType.tripNetProfit ||
      ReportType.openInvoices => null,
    };
  }
}
