abstract final class ReportsFailureCodes {
  static const permissionOperationalView =
      'reports.permission.operational_view';
  static const permissionFinancialView = 'reports.permission.financial_view';
  static const permissionOpenInvoicesView =
      'reports.permission.open_invoices_view';

  static const validationDateRange = 'reports.validation.date_range';

  static const conflictSourceInvalid = 'reports.conflict.source_invalid';
  static const conflictCurrencyMismatch = 'reports.conflict.currency_mismatch';
  static const conflictFinancialDataInvalid =
      'reports.conflict.financial_data_invalid';
  static const conflictInvoiceBalanceInvalid =
      'reports.conflict.invoice_balance_invalid';
}
