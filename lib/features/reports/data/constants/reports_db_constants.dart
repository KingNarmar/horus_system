abstract final class ReportsDbConstants {
  static const operationalRpc = 'get_operational_trip_reports_source';
  static const tripExpensesRpc = 'get_trip_expenses_report_source';
  static const tripNetProfitRpc = 'get_trip_net_profit_report_source';
  static const openInvoicesRpc = 'get_open_invoices_report_source';

  static const companyIdParam = 'p_company_id';
  static const fromDateParam = 'p_from_date';
  static const toDateParam = 'p_to_date';
}

abstract final class ReportsRpcErrorCodes {
  static const permissionDenied = 'P3010';
  static const invalidDateRange = 'P3011';
  static const companyNotFound = 'P3012';
  static const regionalSettingsNotConfigured = 'P3013';
}
