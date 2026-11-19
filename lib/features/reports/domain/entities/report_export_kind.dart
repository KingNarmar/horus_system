import '../../../company/domain/entities/company_role.dart';
import '../policies/reports_permission_policy.dart';
import 'operational_trip_report.dart';

/// Report identifiers independent of Presentation's selected-tab state.
enum ReportExportKind {
  dailyTrips,
  tripsByCustomer,
  tripsByRoute,
  tripsByDriver,
  tripsByTractorHead,
  tripsByTrailer,
  tripExpenses,
  tripNetProfit,
  openInvoices;

  OperationalReportDimension? get operationalDimension => switch (this) {
    dailyTrips => OperationalReportDimension.day,
    tripsByCustomer => OperationalReportDimension.customer,
    tripsByRoute => OperationalReportDimension.route,
    tripsByDriver => OperationalReportDimension.driver,
    tripsByTractorHead => OperationalReportDimension.tractorHead,
    tripsByTrailer => OperationalReportDimension.trailer,
    tripExpenses || tripNetProfit || openInvoices => null,
  };

  bool canView(CompanyRole role) => switch (this) {
    dailyTrips ||
    tripsByCustomer ||
    tripsByRoute ||
    tripsByDriver ||
    tripsByTractorHead ||
    tripsByTrailer => ReportsPermissionPolicy.canViewOperationalReports(role),
    tripExpenses || tripNetProfit =>
      ReportsPermissionPolicy.canViewFinancialReports(role),
    openInvoices => ReportsPermissionPolicy.canViewOpenInvoicesReport(role),
  };
}
