abstract final class ReportsDbConstants {
  static const operationalRpc = 'get_operational_trip_reports_source';
  static const tripExpensesRpc = 'get_trip_expenses_report_source';
  static const tripNetProfitRpc = 'get_trip_net_profit_report_source';
  static const openInvoicesRpc = 'get_open_invoices_report_source';
  static const startSnapshotRpc = 'start_report_export_snapshot';
  static const readSnapshotPageRpc = 'read_report_export_snapshot_page';
  static const releaseSnapshotRpc = 'release_report_export_snapshot';

  static const companyIdParam = 'p_company_id';
  static const fromDateParam = 'p_from_date';
  static const toDateParam = 'p_to_date';
  static const sourceKindParam = 'p_source_kind';
  static const snapshotIdParam = 'p_snapshot_id';
  static const streamParam = 'p_stream';
  static const cursorParam = 'p_cursor';
  static const pageSizeParam = 'p_page_size';
}

abstract final class ReportsRpcErrorCodes {
  static const permissionDenied = 'P3010';
  static const invalidDateRange = 'P3011';
  static const companyNotFound = 'P3012';
  static const businessTimezoneNotConfigured = 'P3013';
  static const financialSettingsNotConfigured = 'P3014';
  static const exportCapacity = 'P3015';
  static const exportSnapshotInvalid = 'P3016';
  static const exportPageInvalid = 'P3017';
}
