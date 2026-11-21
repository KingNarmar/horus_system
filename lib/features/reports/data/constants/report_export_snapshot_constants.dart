/// The server rejects larger pages and never silently truncates them.
abstract final class ReportExportSnapshotConstants {
  static const int pageSize = 200;
  static const String operational = 'operational';
  static const String tripExpenses = 'trip_expenses';
  static const String tripNetProfit = 'trip_net_profit';
  static const String openInvoices = 'open_invoices';
  static const String rows = 'rows';
  static const String trips = 'trips';
  static const String expenses = 'expenses';
  static const String invoices = 'invoices';
  static const String payments = 'payments';
}
